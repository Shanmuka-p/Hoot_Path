// ─── App Configuration ────────────────────────────────────────────────────────
//
// Centralizes all app-level constants and runtime helpers.
//
// kUserId is no longer a hard-coded const — it reads from AuthSession so that
// the student_id returned by the login API is automatically used everywhere.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:hoot_path/services/auth_service.dart';

/// The active user's MongoDB student_id.
/// Populated automatically after a successful login via AuthService.
String get kUserId => AuthSession.instance.userId;

/// Base URL for the LSRW Analytics API (aihoot backend).
const String kLsrwApiBaseHost = 'https://aihoot.in:5001';

/// Base URL for the Learning Path API (hoot-path backend on Render).
const String kLearningPathApiBase = 'https://hoot-path.onrender.com/api';
