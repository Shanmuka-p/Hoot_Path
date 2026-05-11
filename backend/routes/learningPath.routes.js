// ─── routes/learningPath.routes.js ────────────────────────────────────────────
//  Route layer — maps HTTP endpoints to controller methods.
//  No business logic here; delegates everything to the controller.
// ─────────────────────────────────────────────────────────────────────────────

const express    = require('express');
const controller = require('../controllers/learningPath.controller');

const router = express.Router();

// ── GET existing active path for a user ───────────────────────────────────────
router.post('/get-learning-path', controller.getLearningPath);

// ── Generate a new 30-day AI-powered path ────────────────────────────────────
router.post('/generate-learning-path', controller.generateLearningPath);

// ── Mark a day as completed ───────────────────────────────────────────────────
router.post('/complete-day', controller.completeDay);

module.exports = router;
