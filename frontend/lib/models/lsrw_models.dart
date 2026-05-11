// ─── lib/models/lsrw_models.dart ─────────────────────────────────────────────
//  Model layer — Pure data classes for LSRW analytics.
//  No business logic, no UI, no API calls.
//  Extracted from lsrw_api_service.dart to follow MVC separation.
// ─────────────────────────────────────────────────────────────────────────────

// ─── Overall LSRW Models ──────────────────────────────────────────────────────

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
      module:     json['module'] ?? '',
      count:      json['count'] ?? 0,
      duration:   json['duration'] ?? 0,
      accuracy:   double.tryParse(json['accuracy'].toString()) ?? 0.0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
      id:         json['_id'] ?? '',
    );
  }
}

class OverallLsrwData {
  final List<OverallSkill> skills;
  OverallLsrwData({required this.skills});

  OverallSkill? get listening => _find('Listening');
  OverallSkill? get speaking  => _find('Speaking');
  OverallSkill? get reading   => _find('Reading');
  OverallSkill? get writing   => _find('Writing');

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
    final rel = [listening, speaking, reading, writing].whereType<OverallSkill>().toList();
    if (rel.isEmpty) return 0;
    return rel.fold(0.0, (s, e) => s + e.percentage) / rel.length;
  }
}

// ─── Individual Skill Models ───────────────────────────────────────────────────

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

  factory ModuleRecord.fromJson(Map<String, dynamic> json, String baseHost) {
    return ModuleRecord(
      moduleName: json['module_name'] ?? '',
      moduleIcon: _resolveIconUrl(json['module_icon'], baseHost),
      complexity: json['complexity'] ?? 'easy',
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
      count:      json['count'] ?? 0,
      courseName: json['course_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'module_name': moduleName,
    'module_icon': moduleIcon,
    'complexity': complexity,
    'percentage': percentage,
    'count': count,
    'course_name': courseName,
  };

  /// Converts a module_icon value from the API into a full URL.
  static String _resolveIconUrl(String? raw, String baseHost) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return '$baseHost${raw.startsWith('/') ? raw : '/$raw'}';
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

  factory SkillDetail.fromJson(Map<String, dynamic> json, String baseHost) {
    final raw = json['records'] as List<dynamic>? ?? [];
    return SkillDetail(
      records:    raw.map((r) => ModuleRecord.fromJson(r, baseHost)).toList(),
      noAttempts: json['no_attempts'] ?? 0,
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'records': records.map((r) => r.toJson()).toList(),
    'no_attempts': noAttempts,
    'percentage': percentage,
  };
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

  factory IndividualLsrwData.fromJson(Map<String, dynamic> json, String baseHost) {
    return IndividualLsrwData(
      listening:      SkillDetail.fromJson(json['listening'] ?? {}, baseHost),
      speaking:       SkillDetail.fromJson(json['speaking']  ?? {}, baseHost),
      reading:        SkillDetail.fromJson(json['reading']   ?? {}, baseHost),
      writing:        SkillDetail.fromJson(json['writing']   ?? {}, baseHost),
      totalAttempts:  json['total_attempts'] ?? 0,
      userPercentage: double.tryParse(json['user_percentage'].toString()) ?? 0.0,
    );
  }

  SkillDetail detailFor(String skill) {
    switch (skill.toLowerCase()) {
      case 'listening': return listening;
      case 'speaking':  return speaking;
      case 'reading':   return reading;
      default:          return writing;
    }
  }
}
