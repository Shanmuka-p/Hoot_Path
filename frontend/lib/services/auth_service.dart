// ─── lib/services/auth_service.dart ──────────────────────────────────────────
//  Service layer — handles authentication against the LSRW backend.
//  Calls POST /api/login and extracts student_id + student_name from the
//  response, storing them in the AuthSession singleton for the app lifetime.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoot_path/config/app_config.dart';

// ─── Auth Session (singleton — runtime state) ─────────────────────────────────
//  Holds the logged-in user's data after a successful login.
//  Access anywhere via AuthSession.instance.
class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  String _userId   = '';
  String _userName = '';
  Map<String, dynamic> _userData = {};

  /// The MongoDB student_id returned from the login API.
  String get userId   => _userId;

  /// The student's display name returned from the login API.
  String get userName => _userName;

  /// The raw user data from the login API.
  Map<String, dynamic> get userData => _userData;

  /// First letter of the student name, used for the avatar badge.
  String get avatarLetter =>
      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S';

  void _set({required String userId, required String userName, required Map<String, dynamic> userData}) {
    _userId   = userId;
    _userName = userName;
    _userData = userData;
  }

  Future<void> saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(_userData));
  }

  Future<bool> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString('user_data');
      if (dataStr != null && dataStr.isNotEmpty) {
        final decoded = jsonDecode(dataStr) as Map<String, dynamic>;
        _userData = decoded;
        _userId = (decoded['student_id'] ?? decoded['_id'] ?? decoded['id'] ?? '') as String;
        _userName = (decoded['first_name'] ?? decoded['student_name'] ?? decoded['name'] ?? decoded['username'] ?? decoded['email'] ?? '') as String;
        return true;
      }
    } catch (e) {
      // Ignore errors on load
    }
    return false;
  }

  Future<void> clear() async {
    _userId   = '';
    _userName = '';
    _userData = {};
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }
}

// ─── Login Result ──────────────────────────────────────────────────────────────
class LoginResult {
  final bool   success;
  final String? errorMessage;

  const LoginResult.ok()           : success = true,  errorMessage = null;
  const LoginResult.fail(this.errorMessage) : success = false;
}

// ─── Auth Service ──────────────────────────────────────────────────────────────
class AuthService {
  static const String _loginUrl = '$kLsrwApiBaseHost/api/login';

  // Bypass self-signed / expired SSL cert on port 5001 (same as LsrwApiService)
  static http.Client _buildClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => host == 'aihoot.in';
    return IOClient(httpClient);
  }

  /// Calls POST /api/login with [email] and [password].
  /// On success, populates [AuthSession.instance] with student_id + name.
  /// Returns a [LoginResult] indicating success or failure with a message.
  static Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final client = _buildClient();
    try {
      final response = await client
          .post(
            Uri.parse(_loginUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept'      : 'application/json',
            },
            body: jsonEncode({
              'email'     : email,
              'password'  : password,
              'forcelogin': false,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        // ── Extract student_id ────────────────────────────────────────────────
        final studentId = (decoded['student_id']   ??
                           decoded['_id']           ??
                           decoded['id']            ??
                           '') as String;

        // ── Extract student name (try common field names) ─────────────────────
        final studentName = (decoded['student_name'] ??
                             decoded['name']          ??
                             decoded['username']      ??
                             decoded['email']         ??
                             email) as String;

        if (studentId.isEmpty) {
          return const LoginResult.fail(
            'Login succeeded but no student_id was returned.',
          );
        }

        AuthSession.instance._set(
          userId  : studentId,
          userName: studentName,
          userData: decoded,
        );
        await AuthSession.instance.saveSession();

        return const LoginResult.ok();
      } else {
        // Server returned an error — surface the message if present
        final msg = (decoded['message'] ??
                     decoded['error']   ??
                     'Login failed (${response.statusCode})') as String;
        return LoginResult.fail(msg);
      }
    } on SocketException {
      return const LoginResult.fail('No internet connection.');
    } on HttpException {
      return const LoginResult.fail('Server unreachable. Please try again.');
    } catch (e) {
      return LoginResult.fail('Unexpected error: $e');
    } finally {
      client.close();
    }
  }

  /// Logs out the user by clearing the stored session.
  static Future<void> logout() async {
    await AuthSession.instance.clear();
  }
}
