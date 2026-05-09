import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class LearningPathService {
  // 🌐 Uses the existing production server (same as LSRW API)
  static const String _baseUrl = 'https://aihoot.in:5001/api';

  String get baseUrl => _baseUrl;

  // Same SSL-bypass client as lsrw_api_service (self-signed cert on port 5001)
  http.Client _buildClient() {
    final httpClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(httpClient);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> decoded;
    try {
      decoded = json.decode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception(
          'Invalid response from server (not JSON). Body: ${response.body}');
    }
    if (response.statusCode >= 400) {
      throw Exception(
          'Server error ${response.statusCode}: ${decoded['error'] ?? response.body}');
    }
    return decoded;
  }

  /// Quick ping to check if server is reachable.
  Future<bool> isServerReachable() async {
    final client = _buildClient();
    try {
      final response = await client
          .get(Uri.parse('https://aihoot.in:5001/'))
          .timeout(const Duration(seconds: 8));
      return response.statusCode < 500;
    } catch (_) {
      return false;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> checkExistingPath(String userId) async {
    final client = _buildClient();
    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/get-learning-path'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"user_id": userId}),
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Cannot reach server. Check your internet connection.');
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> generatePath(
    String userId,
    Map<String, dynamic> accuracyData,
  ) async {
    final client = _buildClient();
    try {
      // Gemini generation + MongoDB save can take 30-60s
      final response = await client
          .post(
            Uri.parse('$baseUrl/generate-learning-path'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"user_id": userId, "accuracy": accuracyData}),
          )
          .timeout(const Duration(seconds: 120));
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception(
          'Path generation timed out. The AI is taking too long — please try again.');
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> completeDay(String userId, int day) async {
    final client = _buildClient();
    try {
      final response = await client
          .post(
            Uri.parse('$baseUrl/complete-day'),
            headers: {"Content-Type": "application/json"},
            body: json.encode({"user_id": userId, "day": day}),
          )
          .timeout(const Duration(seconds: 20));
      return _handleResponse(response);
    } on TimeoutException {
      throw Exception('Request timed out. Check your internet connection.');
    } finally {
      client.close();
    }
  }
}
