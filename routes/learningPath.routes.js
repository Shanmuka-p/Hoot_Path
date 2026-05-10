const express      = require('express');
const LearningPath = require('../models/LearningPath');
const { generateSmartPath } = require('../services/pathGenerator.service');

const router = express.Router();

// ── GET existing active path for a user ───────────────────────────────────────
router.post('/get-learning-path', async (req, res) => {
    try {
        const { user_id } = req.body;
        if (!user_id) return res.status(400).json({ error: 'user_id is required.' });

        const activePath = await LearningPath.findOne({ user_id, status: 'active' });
        if (activePath) return res.json({ exists: true, path: activePath });
        return res.json({ exists: false });
    } catch (error) {
        console.error('[Route] get-learning-path:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── Generate a new 30-day path (condition-based, no external LLM) ─────────────
router.post('/generate-learning-path', async (req, res) => {
    try {
        const { user_id, accuracy } = req.body;
        if (!user_id) return res.status(400).json({ error: 'user_id is required.' });

        const existing = await LearningPath.findOne({ user_id, status: 'active' });
        if (existing) return res.status(400).json({ error: 'Active path exists.' });

        console.log(`[PathGen] Building personalized path for user: ${user_id}`);
        const generatedPath = generateSmartPath(accuracy || {});

        const doc = new LearningPath({
            user_id,
            start_date: new Date().toISOString().split('T')[0],
            status: 'active',
            accuracy_snapshot: {
                listening: accuracy?.listening || 0,
                speaking:  accuracy?.speaking  || 0,
                reading:   accuracy?.reading   || 0,
                writing:   accuracy?.writing   || 0,
            },
            path: generatedPath.map(dayPlan => ({
                ...dayPlan,
                completed:    false,
                completed_at: null,
            })),
        });

        const saved = await doc.save();
        console.log(`[PathGen] Path saved for user: ${user_id}`);
        res.json(saved);
    } catch (error) {
        console.error('[Route] generate-learning-path:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── Mark a day as completed ───────────────────────────────────────────────────
router.post('/complete-day', async (req, res) => {
    try {
        const { user_id, day } = req.body;
        if (!user_id || day == null) {
            return res.status(400).json({ error: 'user_id and day are required.' });
        }

        const activePath = await LearningPath.findOne({ user_id, status: 'active' });
        if (!activePath) return res.status(404).json({ error: 'No active path found.' });

        const dayIndex = activePath.path.findIndex(d => d.day === day);
        if (dayIndex === -1) return res.status(400).json({ error: 'Invalid day.' });

        activePath.path[dayIndex].completed    = true;
        activePath.path[dayIndex].completed_at = new Date();

        const allDone = activePath.path.every(d => d.completed);
        if (allDone) activePath.status = 'completed';

        await activePath.save();
        res.json({ success: true, path_completed: allDone });
    } catch (error) {
        console.error('[Route] complete-day:', error.message);
        res.status(500).json({ error: error.message });
    }
});

module.exports = router;
