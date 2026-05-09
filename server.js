require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const LearningPath = require('./models/LearningPath');

const app = express();
app.use(express.json());
app.use(cors());

mongoose.connect(process.env.MONGO_URI, {
    serverSelectionTimeoutMS: 30000,
    socketTimeoutMS: 45000,
    connectTimeoutMS: 30000,
})
    .then(() => console.log('MongoDB Connected'))
    .catch(err => console.log('MongoDB Error:', err));

// ─── Smart Path Generator (no external AI needed) ────────────────────────────

const SKILL_MODULES = {
    Listening: [
        'Audio Comprehension', 'Podcast Listening', 'Lecture Notes',
        'Dialogue Practice', 'Story Listening', 'News Listening',
        'Accent Training', 'Speed Listening', 'Inference Practice'
    ],
    Speaking: [
        'Pronunciation Drill', 'Mock Interview', 'Topic Discussion',
        'Tongue Twisters', 'Storytelling', 'Debate Practice',
        'Vocabulary Speaking', 'Role Play', 'Presentation Skills'
    ],
    Reading: [
        'Passage Comprehension', 'Vocabulary Builder', 'Speed Reading',
        'Critical Analysis', 'Inference Questions', 'Summary Writing',
        'Main Idea Finding', 'Context Clues', 'Article Reading'
    ],
    Writing: [
        'Essay Draft', 'Grammar Exercises', 'Sentence Structuring',
        'Paragraph Writing', 'Email Writing', 'Descriptive Writing',
        'Punctuation Practice', 'Vocabulary in Context', 'Story Completion'
    ],
};

function getDifficulty(day) {
    if (day <= 10) return 'easy';
    if (day <= 20) return 'medium';
    return 'hard';
}

function getCount(day) {
    if (day <= 10) return 2;
    if (day <= 20) return 3;
    return 4;
}

function pickModule(skill, dayIndex) {
    const modules = SKILL_MODULES[skill];
    return modules[dayIndex % modules.length];
}

/**
 * Generates a personalized 30-day learning path based on accuracy data.
 * - Weak skills (<60%) → prioritized, more daily tasks
 * - Medium skills (60-80%) → moderate focus
 * - Strong skills (>80%) → maintenance only
 */
function generateSmartPath(accuracy) {
    const skills = ['Listening', 'Speaking', 'Reading', 'Writing'];
    const skillKeys = ['listening', 'speaking', 'reading', 'writing'];

    // Build weight for each skill based on accuracy (inverse — lower = more focus)
    const weights = {};
    skills.forEach((skill, i) => {
        const acc = parseFloat(accuracy[skillKeys[i]]) || 50;
        if (acc < 60) weights[skill] = 4;       // weak — high priority
        else if (acc < 80) weights[skill] = 2;  // medium
        else weights[skill] = 1;                // strong — maintenance
    });

    // Build a weighted skill pool to draw from
    const skillPool = [];
    Object.entries(weights).forEach(([skill, w]) => {
        for (let i = 0; i < w; i++) skillPool.push(skill);
    });

    const path = [];

    for (let day = 1; day <= 30; day++) {
        const difficulty = getDifficulty(day);
        const count = getCount(day);
        const taskCount = 3 + Math.floor((day - 1) / 10); // 3, 4, or 5 tasks

        // Pick skills for today — primary + supporting
        const todaySkills = [];
        const primarySkill = skillPool[(day - 1) % skillPool.length];
        todaySkills.push(primarySkill);

        // Add more skills without repeating
        const remaining = skills.filter(s => s !== primarySkill);
        for (let i = 0; todaySkills.length < Math.min(taskCount, 4); i++) {
            todaySkills.push(remaining[i % remaining.length]);
        }

        // Build tasks
        const tasks = todaySkills.slice(0, taskCount).map((skill, idx) => ({
            skill,
            module: pickModule(skill, day + idx),
            count,
            difficulty,
        }));

        // Focus label
        const focusSkill = tasks[0].skill;
        const focusLabels = {
            easy: 'Foundation',
            medium: 'Practice',
            hard: 'Mastery',
        };
        const focus = `${focusSkill} ${focusLabels[difficulty]} — Day ${day}`;

        path.push({ day, focus, tasks });
    }

    return path;
}

// ─── Routes ──────────────────────────────────────────────────────────────────

app.post('/api/get-learning-path', async (req, res) => {
    try {
        const { user_id } = req.body;
        const activePath = await LearningPath.findOne({ user_id, status: 'active' });
        if (activePath) {
            return res.json({ exists: true, path: activePath });
        }
        return res.json({ exists: false });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/complete-day', async (req, res) => {
    try {
        const { user_id, day } = req.body;
        const activePath = await LearningPath.findOne({ user_id, status: 'active' });
        if (!activePath) return res.status(404).json({ error: 'No active path found' });

        const dayIndex = activePath.path.findIndex(d => d.day === day);
        if (dayIndex === -1) return res.status(400).json({ error: 'Invalid day' });

        activePath.path[dayIndex].completed = true;
        activePath.path[dayIndex].completed_at = new Date();

        const allCompleted = activePath.path.every(d => d.completed);
        if (allCompleted) activePath.status = 'completed';

        await activePath.save();
        res.json({ success: true, path_completed: allCompleted });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/generate-learning-path', async (req, res) => {
    try {
        const { user_id, accuracy } = req.body;

        const existingPath = await LearningPath.findOne({ user_id, status: 'active' });
        if (existingPath) {
            return res.status(400).json({ error: 'Active path exists.' });
        }

        // Generate path using smart algorithm (no external API needed)
        const generatedPath = generateSmartPath(accuracy || {});

        const newPath = new LearningPath({
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
                completed: false,
                completed_at: null,
            })),
        });

        const savedDoc = await newPath.save();
        console.log(`Generated 30-day path for user: ${user_id}`);
        res.json(savedDoc);
    } catch (error) {
        console.error('Generate path error:', error.message);
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));