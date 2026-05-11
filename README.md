# Hoot Path

A comprehensive language and skill learning platform focusing on core **LSRW (Listening, Speaking, Reading, Writing)** skills. Hoot Path provides users with an engaging, gamified learning experience, complete with an AI Mentor, Leaderboards, and Daily Tips.

![Hoot Path App](https://img.shields.io/badge/Platform-Flutter-blue) ![Hoot Path Backend](https://img.shields.io/badge/Backend-Node.js-green)

## Architecture

This project is structured as a monorepo containing:
- **Frontend**: A cross-platform mobile and web application built with [Flutter](https://flutter.dev/).
- **Backend**: A RESTful API built with [Node.js](https://nodejs.org/) and [Express](https://expressjs.com/), utilizing [MongoDB](https://www.mongodb.com/) for data persistence.

---

## Frontend (`/frontend`)

The frontend application provides a sleek, interactive user interface designed to facilitate daily learning habits.

### Key Features
- **Skill Modules**: Dedicated interactive sections for Listening, Speaking, Reading, and Writing.
- **HOOT AI Mentor**: An intelligent companion that guides users through onboarding and tracks daily learning streaks.
- **Leaderboard**: Competitive rankings based on user accuracy and attempt counts.
- **Hoot Tips**: Actionable, bite-sized tips for specific skill improvement.
- **Analytics & Progress**: Visual tracking of learning milestones.
- **Cross-Platform**: Fully responsive design supporting Android, iOS, and Web.

### Tech Stack
- **Framework**: Flutter (Dart)
- **Key Packages**:
  - `http`: For robust API communication with the backend.
  - `shared_preferences`: For local session and state management.
  - `device_preview`: For seamless UI testing across various device sizes.

### Getting Started (Frontend)
1. Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
2. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
3. Fetch dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```

---

## Backend (`/backend`)

The backend is a robust Node.js server handling data management, user progress tracking, and AI-driven learning path generation.

### Tech Stack
- **Runtime**: Node.js
- **Framework**: Express.js
- **Database**: MongoDB (via Mongoose ODM)
- **Utilities**: `cors` (Cross-Origin Resource Sharing), `dotenv` (Environment management).

### Getting Started (Backend)
1. Ensure you have [Node.js](https://nodejs.org/) installed.
2. Navigate to the backend directory:
   ```bash
   cd backend
   ```
3. Install dependencies:
   ```bash
   npm install
   ```
4. Configure Environment Variables:
   - Create a `.env` file based on `.env.example`.
   - Provide your `MONGO_URI` and any necessary API keys (e.g., OpenRouter AI keys).
5. Start the server:
   ```bash
   npm start
   ```
   *The server will typically run on `http://localhost:5001`.*

---

## Project Structure

```text
Hoot_Path/
├── backend/                  # Node.js & Express API Server
│   ├── config/               # Database connections and configs (db.js)
│   ├── controllers/          # API route request handlers
│   ├── models/               # MongoDB schemas (Mongoose)
│   ├── routes/               # API endpoint definitions
│   ├── services/             # Core business logic (OpenRouter, PathGenerator)
│   ├── server.js             # Application entry point
│   └── package.json          # Node dependencies
└── frontend/                 # Flutter Application
    ├── assets/               # Static assets (images, onboarding screens)
    ├── lib/                  # Dart source code
    │   ├── config/           # App-wide configuration files
    │   ├── controllers/      # UI state and business logic bindings
    │   ├── models/           # Data models representing API responses
    │   ├── services/         # API wrappers and local storage services
    │   ├── views/            # UI screens (Home, Analytics, Learning Path)
    │   └── main.dart         # Flutter application entry point
    ├── pubspec.yaml          # Flutter dependencies
    └── test/                 # Widget and unit tests
```

---

## Contributions & Conventions
- **Code Style**: The frontend utilizes `flutter_lints` to enforce Dart coding standards.
- **Environment**: Never commit `.env` files or sensitive credentials.

---
