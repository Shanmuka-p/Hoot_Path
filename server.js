/**
 * server.js — Application Entry Point
 *
 * Responsibilities (ONLY):
 *   1. Load environment variables
 *   2. Connect to MongoDB
 *   3. Mount Express middleware
 *   4. Register route modules
 *   5. Start the HTTP server
 *
 * Business logic lives in:  services/pathGenerator.service.js
 * Database config lives in:  config/db.js
 * Route handlers live in:   routes/learningPath.routes.js
 */
require('dotenv').config();
const express            = require('express');
const cors               = require('cors');
const connectDB          = require('./config/db');
const learningPathRoutes = require('./routes/learningPath.routes');

// ── Connect Database ──────────────────────────────────────────────────────────
connectDB();

// ── App Setup ─────────────────────────────────────────────────────────────────
const app = express();
app.use(express.json());
app.use(cors());

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/api', learningPathRoutes);

// ── Server ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));