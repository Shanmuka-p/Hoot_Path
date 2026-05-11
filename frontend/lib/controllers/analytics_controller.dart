// ─── lib/controllers/analytics_controller.dart ───────────────────────────────
//  Controller layer — owns the business logic for the Analytics screen.
//  Calls Service → formats data → exposes state for the View (AnalyticsScreen).
//  The View only reads properties and calls methods; no HTTP/model logic there.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:hoot_path/models/lsrw_models.dart';
import 'package:hoot_path/services/lsrw_api_service.dart';
import 'package:hoot_path/config/app_config.dart';

class AnalyticsController extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  bool isLoading = true;
  String? error;
  OverallLsrwData? overall;
  IndividualLsrwData? individual;

  final LsrwApiService _api;

  AnalyticsController() : _api = LsrwApiService(userId: kUserId) {
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
    return 'Needs Improvement';
  }

  Color statusColor(double pct) {
    if (pct >= 80) return const Color(0xFF008738);
    if (pct >= 65) return const Color(0xFF4CAF50);
    if (pct >= 50) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  String insightText(OverallLsrwData data) {
    final skills = <String, double>{
      'Listening': data.listening?.percentage ?? 0,
      'Speaking':  data.speaking?.percentage  ?? 0,
      'Reading':   data.reading?.percentage   ?? 0,
      'Writing':   data.writing?.percentage   ?? 0,
    };
    final weakest = skills.entries.reduce((a, b) => a.value < b.value ? a : b);
    final secondWeakest = _secondWeakest(skills, weakest.key);
    return 'Focus more on ${weakest.key} and $secondWeakest '
        'to improve your overall communication skills.';
  }

  String _secondWeakest(Map<String, double> skills, String weakestKey) {
    final others = skills.entries.where((e) => e.key != weakestKey).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return others.first.key;
  }
}
