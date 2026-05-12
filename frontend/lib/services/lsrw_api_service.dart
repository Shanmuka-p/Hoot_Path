// ─── lib/services/lsrw_api_service.dart ──────────────────────────────────────
//  Service layer — handles all HTTP communication with the LSRW API.
//  Returns typed Model objects; has no UI dependencies.
//  Extracted from the monolithic lsrw_api_service.dart (root lib/).
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:hoot_path/config/app_config.dart';
import 'package:hoot_path/models/lsrw_models.dart';

// ─── API Endpoints ─────────────────────────────────────────────────────────────
const String _base = '$kLsrwApiBaseHost/api';

const String kOverallLsrwApi    = '$_base/get-attempts-duration-by-user-id';
const String kIndividualLsrwApi = '$_base/get-individual-module-attempts-by-user-id';

// ─── HTTP Client ──────────────────────────────────────────────────────────────
// Uses IOClient to bypass SSL cert errors (self-signed / expired on port 5001)
http.Client _buildClient() {
  final httpClient = HttpClient()
    ..badCertificateCallback =
        (X509Certificate cert, String host, int port) => host == 'aihoot.in';
  return IOClient(httpClient);
}

// ─── Service ──────────────────────────────────────────────────────────────────

class LsrwApiService {
  final String userId;
  LsrwApiService({required this.userId});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, dynamic> get _body => {'user_id': userId};

  Future<OverallLsrwData> fetchOverallData() async {
    final client = _buildClient();
    try {
      final response = await client
          .post(
            Uri.parse(kOverallLsrwApi),
            headers: _headers,
            body: jsonEncode(_body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        List<dynamic> list;
        if (decoded is List) {
          list = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          list = decoded['data'] as List<dynamic>;
        } else {
          throw Exception('Unexpected response format from overall API');
        }
        return OverallLsrwData(
          skills: list.map((j) => OverallSkill.fromJson(j)).toList(),
        );
      } else {
        throw Exception(
          'Overall API error ${response.statusCode}: ${response.body}',
        );
      }
    } finally {
      client.close();
    }
  }

  Future<IndividualLsrwData> fetchIndividualData() async {
    final client = _buildClient();
    try {
      final response = await client
          .post(
            Uri.parse(kIndividualLsrwApi),
            headers: _headers,
            body: jsonEncode(_body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        Map<String, dynamic> map;
        if (decoded is Map<String, dynamic>) {
          map = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          map = decoded['data'] as Map<String, dynamic>;
        } else {
          throw Exception('Unexpected response format from individual API');
        }
        return IndividualLsrwData.fromJson(map, kLsrwApiBaseHost);
      } else {
        throw Exception(
          'Individual API error ${response.statusCode}: ${response.body}',
        );
      }
    } finally {
      client.close();
    }
  }
}
