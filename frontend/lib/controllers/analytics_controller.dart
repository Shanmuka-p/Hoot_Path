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
      ]);
      overall    = results[0] as OverallLsrwData;
      individual = results[1] as IndividualLsrwData;
      
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
