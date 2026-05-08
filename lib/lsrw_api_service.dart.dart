import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

// ─── API Endpoints ─────────────────────────────────────────────────────────
// On Web  → calls local proxy (localhost:8080) to bypass CORS
// On Device → calls real API directly
const String _realBase = 'https://aihoot.in:5001/api';
const String _proxyBase = 'http://localhost:8080/api';

String get _base => kIsWeb ? _proxyBase : _realBase;

String get kOverallLsrwApi => '$_base/get-attempts-duration-by-user-id';
String get kIndividualLsrwApi =>
    '$_base/get-individual-module-attempts-by-user-id';

// ─── Overall LSRW Models ───────────────────────────────────────────────────

class OverallSkill {
  final String module;
  final int count;
  final int duration;
  final double accuracy;
  final double percentage;
  final String id;

  OverallSkill({
    required this.module,
    required this.count,
    required this.duration,
    required this.accuracy,
    required this.percentage,
    required this.id,
  });

  factory OverallSkill.fromJson(Map<String, dynamic> json) {
    return OverallSkill(
      module: json['module'] ?? '',
      count: json['count'] ?? 0,
      duration: json['duration'] ?? 0,
      accuracy: double.tryParse(json['accuracy'].toString()) ?? 0.0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
      id: json['_id'] ?? '',
    );
  }
}

class OverallLsrwData {
  final List<OverallSkill> skills;
  OverallLsrwData({required this.skills});

  OverallSkill? get listening => _find('Listening');
  OverallSkill? get speaking => _find('Speaking');
  OverallSkill? get reading => _find('Reading');
  OverallSkill? get writing => _find('Writing');

  OverallSkill? _find(String name) {
    try {
      return skills.firstWhere(
        (s) => s.module.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  double get overallPercentage {
    final rel = [
      listening,
      speaking,
      reading,
      writing,
    ].whereType<OverallSkill>().toList();
    if (rel.isEmpty) return 0;
    return rel.fold(0.0, (s, e) => s + e.percentage) / rel.length;
  }
}

// ─── Individual Skill Models ───────────────────────────────────────────────

class ModuleRecord {
  final String moduleName;
  final String moduleIcon;
  final String complexity;
  final double percentage;
  final int count;
  final String courseName;

  ModuleRecord({
    required this.moduleName,
    required this.moduleIcon,
    required this.complexity,
    required this.percentage,
    required this.count,
    required this.courseName,
  });

  factory ModuleRecord.fromJson(Map<String, dynamic> json) {
    return ModuleRecord(
      moduleName: json['module_name'] ?? '',
      moduleIcon: json['module_icon'] ?? '',
      complexity: json['complexity'] ?? 'easy',
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
      count: json['count'] ?? 0,
      courseName: json['course_name'] ?? '',
    );
  }
}

class SkillDetail {
  final List<ModuleRecord> records;
  final int noAttempts;
  final double percentage;

  SkillDetail({
    required this.records,
    required this.noAttempts,
    required this.percentage,
  });

  factory SkillDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['records'] as List<dynamic>? ?? [];
    return SkillDetail(
      records: raw.map((r) => ModuleRecord.fromJson(r)).toList(),
      noAttempts: json['no_attempts'] ?? 0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
    );
  }
}

class IndividualLsrwData {
  final SkillDetail listening;
  final SkillDetail speaking;
  final SkillDetail reading;
  final SkillDetail writing;
  final int totalAttempts;
  final double userPercentage;

  IndividualLsrwData({
    required this.listening,
    required this.speaking,
    required this.reading,
    required this.writing,
    required this.totalAttempts,
    required this.userPercentage,
  });

  factory IndividualLsrwData.fromJson(Map<String, dynamic> json) {
    return IndividualLsrwData(
      listening: SkillDetail.fromJson(json['listening'] ?? {}),
      speaking: SkillDetail.fromJson(json['speaking'] ?? {}),
      reading: SkillDetail.fromJson(json['reading'] ?? {}),
      writing: SkillDetail.fromJson(json['writing'] ?? {}),
      totalAttempts: json['total_attempts'] ?? 0,
      userPercentage:
          double.tryParse(json['user_percentage'].toString()) ?? 0.0,
    );
  }

  SkillDetail detailFor(String skill) {
    switch (skill.toLowerCase()) {
      case 'listening':
        return listening;
      case 'speaking':
        return speaking;
      case 'reading':
        return reading;
      default:
        return writing;
    }
  }
}

// ─── API Service ───────────────────────────────────────────────────────────

class LsrwApiService {
  final String userId;
  LsrwApiService({required this.userId});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, dynamic> get _body => {'user_id': userId};

  Future<OverallLsrwData> fetchOverallData() async {
    final response = await http
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
        throw Exception('Unexpected format from overall API');
      }
      return OverallLsrwData(
        skills: list.map((j) => OverallSkill.fromJson(j)).toList(),
      );
    } else {
      throw Exception(
        'Overall API error: ${response.statusCode}\n${response.body}',
      );
    }
  }

  Future<IndividualLsrwData> fetchIndividualData() async {
    final response = await http
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
        throw Exception('Unexpected format from individual API');
      }
      return IndividualLsrwData.fromJson(map);
    } else {
      throw Exception(
        'Individual API error: ${response.statusCode}\n${response.body}',
      );
    }
  }
}
