// ─── App Configuration ────────────────────────────────────────────────────────
//
// Centralizes all app-level constants to avoid hard-coding values across files.
//
// ⚠️  TODO (Auth):  kUserId is currently a hard-coded MongoDB ObjectId for
//     development/demo purposes.  When user authentication is implemented,
//     replace this with the user ID obtained from the login response / JWT token
//     and pass it down via a UserProvider or similar state management solution.
// ─────────────────────────────────────────────────────────────────────────────

/// The active user's ID.
/// TODO: Replace with dynamic ID from authentication token after auth is added.
const String kUserId = '66628e2f213ad0a228fedd06';

/// Base URL for the LSRW Analytics API (aihoot backend).
const String kLsrwApiBaseHost = 'https://aihoot.in:5001';

/// Base URL for the Learning Path API (hoot-path backend on Render).
const String kLearningPathApiBase = 'https://hoot-path.onrender.com/api';
