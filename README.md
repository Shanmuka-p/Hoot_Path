# Hoot Path — Personalized English Learning Path

An AI-guided 30-day English learning path app for the HOOT platform.
Flutter frontend + Node.js/Express backend + MongoDB Atlas.

---

## Project Structure

```
Hoot_Path/
│
├── 📁 config/
│   └── db.js                        # MongoDB connection
│
├── 📁 models/
│   └── LearningPath.js              # Mongoose schema for the 30-day path
│
├── 📁 routes/
│   └── learningPath.routes.js       # Express route handlers (HTTP layer only)
│
├── 📁 services/
│   └── pathGenerator.service.js     # 4-layer personalization condition engine
│
├── server.js                        # Entry point — mounts routes, starts server
├── package.json
├── render.yaml                      # Render deployment config (no secrets)
├── .env.example                     # Documents required environment variables
│
└── 📁 lib/  (Flutter)
    ├── 📁 config/
    │   └── app_config.dart          # Centralized constants (API URLs, user ID)
    │
    ├── lsrw_api_service.dart        # LSRW analytics API client + data models
    ├── learning_path_service.dart   # Hoot-Path backend API client
    │
    ├── analytics_screen.dart        # Dashboard: LSRW donut + skill cards
    ├── skill_detail_sheet.dart      # Bottom sheet: sub-module detail view
    ├── learning_path_screen.dart    # 30-day timeline + generating state
    └── day_task_screen.dart         # Individual day task viewer
```

---

## Technologies Used

| Layer | Technology |
|---|---|
| Mobile Frontend | Flutter (Dart) |
| Backend | Node.js + Express |
| Database | MongoDB Atlas (via Mongoose) |
| Deployment | Render (Node web service) |
| Analytics API | aihoot.in:5001 (external) |
| Path generation | Rule-based condition engine (no external LLM) |

---

## Architecture

```
Flutter App
  └─► LsrwApiService         → aihoot.in:5001   (LSRW accuracy data)
  └─► LearningPathService     → hoot-path.onrender.com (30-day path)

Node.js Server (Render)
  ├─ routes/learningPath.routes.js   (HTTP request handling)
  ├─ services/pathGenerator.service.js  (Personalization logic)
  └─ models/LearningPath.js          (MongoDB persistence)
```

---

## Personalization Engine (4-Layer Condition System)

The `generateSmartPath()` function in `services/pathGenerator.service.js` builds
a 30-day plan using real LSRW API data, applying four condition layers:

| Layer | Input | Condition | Output |
|---|---|---|---|
| 1 | Skill % | < 40 Critical / 40-60 Weak / 60-75 Moderate / 75-90 Good / ≥ 90 Strong | Scheduling priority (×1 to ×5) |
| 2 | Module % + count | Never attempted → +30 score. Low % → high score | Module urgency score |
| 3 | Module complexity | easy→Phase1 / medium→Phase2 / hard→Phase3 | Phase-based scheduling |
| 4 | Skill tier | Critical→"Emergency Focus" / Strong→"Mastery Review" | Day focus label |

---

## Environment Variables

Set these in the **Render Dashboard → Environment** (not in `render.yaml`):

| Variable | Description |
|---|---|
| `MONGO_URI` | MongoDB Atlas connection string |
| `PORT` | Server port (Render sets this automatically) |

Copy `.env.example` → `.env` for local development.

---

## Known Issues / Technical Debt

- **Hardcoded `kUserId`**: `lib/config/app_config.dart` — replace with dynamic
  ID from an auth token once user authentication is implemented.
- **No unit tests**: `test/widget_test.dart` is a placeholder. Service and
  route logic should be covered by tests before production.
- **Old file**: `lib/lsrw_api_service.dart.dart` (double extension) can be
  deleted — all imports now point to `lib/lsrw_api_service.dart`.

---

## Future Enhancements

- **User Authentication**: Replace hardcoded `kUserId` with JWT-based login.
- **LLM Integration**: `services/pathGenerator.service.js` is designed to be
  swappable — the `generateSmartPath()` function can be replaced with an LLM
  call (Gemini, Grok, OpenAI) when a reliable hosted endpoint is available.
- **Spaced Repetition**: Introduce SM-2 algorithm for module revisit scheduling.
- **Push Notifications**: Daily reminders tied to the active path's next day.
- **Progress Analytics**: Dashboard showing completion rate trends over time.
- **Offline Support**: Cache the active path locally for offline day viewing.