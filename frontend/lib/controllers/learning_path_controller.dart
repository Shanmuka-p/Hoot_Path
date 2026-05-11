// ─── lib/controllers/learning_path_controller.dart ────────────────────────────
//  Controller layer — owns all business logic for the Learning Path screen.
//  Orchestrates LearningPathService calls and exposes formatted state.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:hoot_path/services/learning_path_service.dart';

class LearningPathController extends ChangeNotifier {
  // ── State ──────────────────────────────────────────────────────────────────
  bool isLoading    = true;
  bool isGenerating = false;
  String errorMessage = '';
  Map<String, dynamic>? pathData;

  final LearningPathService _service = LearningPathService();
  final String userId;
  final Map<String, dynamic> currentAccuracy;

  LearningPathController({
    required this.userId,
    required this.currentAccuracy,
  });

  // ── Accuracy tier helpers ──────────────────────────────────────────────────
  static const double _kCritical = 40.0;
  static const double _kWeak     = 60.0;
  static const double _kMod      = 75.0;
  static const double _kGood     = 90.0;

  String tierLabel(double pct) {
    if (pct < _kCritical) return 'Critical';
    if (pct < _kWeak)     return 'Weak';
    if (pct < _kMod)      return 'Moderate';
    if (pct < _kGood)     return 'Good';
    return 'Strong';
  }

  Color tierColor(double pct) {
    if (pct < _kCritical) return const Color(0xFFD32F2F);
    if (pct < _kWeak)     return const Color(0xFFE65100);
    if (pct < _kMod)      return const Color(0xFFF9A825);
    if (pct < _kGood)     return const Color(0xFF388E3C);
    return const Color(0xFF1565C0);
  }

  int priority(double pct) {
    if (pct < _kCritical) return 5;
    if (pct < _kWeak)     return 4;
    if (pct < _kMod)      return 3;
    if (pct < _kGood)     return 2;
    return 1;
  }

  /// Builds dynamic, accuracy-aware loading messages.
  List<String> buildLoadingSteps() {
    final l = (currentAccuracy['listening'] ?? 0).toDouble();
    final s = (currentAccuracy['speaking']  ?? 0).toDouble();
    final r = (currentAccuracy['reading']   ?? 0).toDouble();
    final w = (currentAccuracy['writing']   ?? 0).toDouble();

    final skills = [
      {'name': 'Listening', 'pct': l},
      {'name': 'Speaking',  'pct': s},
      {'name': 'Reading',   'pct': r},
      {'name': 'Writing',   'pct': w},
    ]..sort((a, b) => (a['pct'] as double).compareTo(b['pct'] as double));

    final weakest  = skills.first;
    final strongest = skills.last;

    return [
      'Analyzing your LSRW accuracy data...',
      '${weakest['name']} is your weakest (${(weakest['pct'] as double).toStringAsFixed(0)}%) — maximum focus assigned.',
      '${strongest['name']} is strongest (${(strongest['pct'] as double).toStringAsFixed(0)}%) — light maintenance mode.',
      'Sorting ${skills.where((s) => (s['pct'] as double) < _kWeak).length} weak skill(s) to the front of the queue...',
      'Building Foundation → Practice → Mastery progression...',
      'Assigning modules from weakest percentage upward...',
      'Finalizing your 30-day personalized path...',
    ];
  }

  // ── Path Data Queries ──────────────────────────────────────────────────────

  int getCompletedCount() {
    if (pathData == null) return 0;
    final List days = pathData!['path'] ?? [];
    return days.where((d) => d['completed'] == true).length;
  }

  int getTodayIndex(List days) {
    for (int i = 0; i < days.length; i++) {
      if (days[i]['completed'] != true) return i;
    }
    return days.length; // all done
  }

  Color skillColor(String skill) {
    switch (skill.toLowerCase()) {
      case 'listening': return const Color(0xFF4CAF50);
      case 'reading':   return const Color(0xFF2196F3);
      case 'speaking':  return const Color(0xFFFFBB00);
      case 'writing':   return Colors.grey.shade400;
      default:          return const Color(0xFF008738);
    }
  }

  IconData skillIcon(String skill) {
    switch (skill.toLowerCase()) {
      case 'listening': return Icons.headphones;
      case 'speaking':  return Icons.mic;
      case 'reading':   return Icons.menu_book;
      case 'writing':   return Icons.edit;
      default:          return Icons.star;
    }
  }

  // ── Network Actions ────────────────────────────────────────────────────────

  Future<void> loadPath() async {
    isLoading    = true;
    isGenerating = false;
    errorMessage = '';
    notifyListeners();

    // Ping server — even a 404 means server is running
    final reachable = await _service.isServerReachable();
    if (!reachable) {
      errorMessage =
          'Cannot reach the Hoot server.\n\nPlease check your internet connection and try again.';
      isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final checkRes = await _service.checkExistingPath(userId);
      if (checkRes['exists'] == true) {
        pathData  = checkRes['path'] as Map<String, dynamic>?;
        isLoading = false;
        notifyListeners();
      } else {
        isGenerating = true;
        isLoading    = false;
        notifyListeners();

        final genRes = await _service.generatePath(userId, currentAccuracy);
        pathData     = genRes;
        isGenerating = false;
        notifyListeners();
      }
    } catch (e) {
      errorMessage = 'Error: $e';
      isLoading    = false;
      isGenerating = false;
      notifyListeners();
    }
  }
}
