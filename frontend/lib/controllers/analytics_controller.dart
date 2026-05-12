// ─── lib/controllers/analytics_controller.dart ───────────────────────────────
//  Controller layer — owns the business logic for the Analytics screen.
//  Calls Service → formats data → exposes state for the View (AnalyticsScreen).
//  The View only reads properties and calls methods; no HTTP/model logic there.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:hoot_path/models/lsrw_models.dart';
import 'package:hoot_path/services/lsrw_api_service.dart';
import 'package:hoot_path/services/learning_path_service.dart';
import 'package:hoot_path/config/app_config.dart';

class AnalyticsController extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  bool isLoading = true;
  String? error;
  OverallLsrwData? overall;
  IndividualLsrwData? individual;
  String? llmInsight;
  List<PreviewStep> upcomingSteps = [];

  final LsrwApiService _api;
  final LearningPathService _pathService;

  AnalyticsController() 
      : _api = LsrwApiService(userId: kUserId),
        _pathService = LearningPathService() {
    loadData();
  }

  // ── Data Fetching ──────────────────────────────────────────────────────────
  Future<void> loadData() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.fetchOverallData(),
        _api.fetchIndividualData(),
        _pathService.checkExistingPath(kUserId),
      ]);
      overall    = results[0] as OverallLsrwData;
      individual = results[1] as IndividualLsrwData;
      
      final pathRes = results[2] as Map<String, dynamic>;
      if (pathRes['exists'] == true) {
        final List<dynamic> days = pathRes['path']['path'] ?? [];
        final nextDay = days.firstWhere((d) => d['completed'] == false, orElse: () => null);
        if (nextDay != null) {
          final tasks = nextDay['tasks'] as List<dynamic>? ?? [];
          upcomingSteps = tasks.take(3).map((t) => PreviewStep(
            skill: t['skill']?.toString() ?? '',
            module: t['module']?.toString() ?? '',
            count: t['count']?.toString() ?? '1',
          )).toList();
        }
      }
      
      final accuracyPayload = {
        "listening": overall?.listening?.percentage ?? 0,
        "speaking": overall?.speaking?.percentage ?? 0,
        "reading": overall?.reading?.percentage ?? 0,
        "writing": overall?.writing?.percentage ?? 0,
      };
      llmInsight = await _pathService.generateInsight(accuracyPayload);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ── Business Logic ─────────────────────────────────────────────────────────

  String statusLabel(double pct) {
    if (pct >= 80) return 'Excellent';
    if (pct >= 65) return 'Good';
    if (pct >= 50) return 'Average';
    return 'Poor';
  }

  Color statusColor(double pct) {
    if (pct >= 80) return const Color(0xFF008738);
    if (pct >= 65) return const Color(0xFF4CAF50);
    if (pct >= 50) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  String insightText(OverallLsrwData data) {
    return llmInsight ?? 'Analyzing your performance to generate personalized insights...';
  }
}

class PreviewStep {
  final String skill;
  final String module;
  final String count;

  PreviewStep({required this.skill, required this.module, required this.count});
}
