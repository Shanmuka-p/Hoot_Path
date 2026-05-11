// ─── controllers/learningPath.controller.js ───────────────────────────────────
//  Controller layer — handles HTTP request/response only.
//  All business logic lives in services/; all DB access goes via the Model.
// ─────────────────────────────────────────────────────────────────────────────

const LearningPath        = require('../models/LearningPath');
const { generateWithFallback } = require('../services/openRouter.service');

// ── GET existing active path for a user ───────────────────────────────────────
const getLearningPath = async (req, res) => {
    try {
        const { user_id } = req.body;
        if (!user_id) return res.status(400).json({ error: 'user_id is required.' });

        const active = await LearningPath.findOne({ user_id, status: 'active' });
        if (active) return res.json({ exists: true, path: active });
        return res.json({ exists: false });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// ── Generate a new 30-day AI-driven path ─────────────────────────────────────
const generateLearningPath = async (req, res) => {
    try {
        const { user_id, accuracy } = req.body;
        if (!user_id) return res.status(400).json({ error: 'user_id is required.' });

        const existing = await LearningPath.findOne({ user_id, status: 'active' });
        if (existing) return res.status(400).json({ error: 'Active path already exists.' });

        // LLM generates the path using real API module data only.
        // Falls back across keys and models automatically.
        const { path: generatedPath, model } = await generateWithFallback(accuracy || {});

        const doc = new LearningPath({
            user_id,
            start_date:   new Date().toISOString().split('T')[0],
            status:       'active',
            path_source:  `llm:${model}`,
            accuracy_snapshot: {
                listening: accuracy?.listening || 0,
                speaking:  accuracy?.speaking  || 0,
                reading:   accuracy?.reading   || 0,
                writing:   accuracy?.writing   || 0,
            },
            path: generatedPath.map(d => ({
                ...d,
                completed:    false,
                completed_at: null,
            })),
        });

        const saved = await doc.save();
        console.log(`[PathGen] Saved path via "${model}" for user: ${user_id}`);
        res.json(saved);

    } catch (err) {
        console.error('[PathGen] Error:', err.message);
        // 503 = service temporarily unavailable (all LLM keys exhausted)
        res.status(503).json({
            error: 'Could not generate path. All AI models are currently busy. Please try again in a moment.',
            detail: err.message,
        });
    }
};

// ── Mark a specific day as completed ─────────────────────────────────────────
const completeDay = async (req, res) => {
    try {
        const { user_id, day } = req.body;
        if (!user_id || day == null) {
            return res.status(400).json({ error: 'user_id and day are required.' });
        }

        const active = await LearningPath.findOne({ user_id, status: 'active' });
        if (!active) return res.status(404).json({ error: 'No active path found.' });

        const idx = active.path.findIndex(d => d.day === day);
        if (idx === -1) return res.status(400).json({ error: 'Invalid day.' });

        active.path[idx].completed    = true;
        active.path[idx].completed_at = new Date();

        const allDone = active.path.every(d => d.completed);
        if (allDone) active.status = 'completed';

        await active.save();
        res.json({ success: true, path_completed: allDone });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

module.exports = { getLearningPath, generateLearningPath, completeDay };
