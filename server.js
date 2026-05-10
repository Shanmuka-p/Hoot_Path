// ─── server.js ────────────────────────────────────────────────────────────────
//  Application entry-point (bootstrap only).
//  Responsibilities:
//    1. Load environment variables
//    2. Create & configure the Express app (middleware)
//    3. Connect to MongoDB via config/db.js
//    4. Mount route modules
//    5. Start the HTTP server
//
//  NO business logic, NO route handlers, NO model imports here.
// ─────────────────────────────────────────────────────────────────────────────

require('dotenv').config();

const express   = require('express');
const cors      = require('cors');
const connectDB = require('./config/db');

// ── Route modules ─────────────────────────────────────────────────────────────
const learningPathRoutes = require('./routes/learningPath.routes');

// ── App setup ─────────────────────────────────────────────────────────────────
const app = express();
app.use(express.json());
app.use(cors());

// ── Database connection ───────────────────────────────────────────────────────
connectDB();

// ── API Routes ────────────────────────────────────────────────────────────────
app.use('/api', learningPathRoutes);

// ── Start server ──────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
