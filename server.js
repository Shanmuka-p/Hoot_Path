require('dotenv').config();
const express  = require('express');
const mongoose = require('mongoose');
const cors     = require('cors');
const LearningPath = require('./models/LearningPath');

const app = express();
app.use(express.json());
app.use(cors());

// ─── MongoDB ──────────────────────────────────────────────────────────────────
mongoose.connect(process.env.MONGO_URI, {
    serverSelectionTimeoutMS: 30000,
    socketTimeoutMS: 45000,
    connectTimeoutMS: 30000,
})
    .then(() => console.log('MongoDB Connected'))
    .catch(err => console.log('MongoDB Error:', err));

// ─── Fallback module names (used when API data has no records) ─────────────────
const FALLBACK_MODULES = {
    Listening: [
        'Audio Comprehension', 'Podcast Listening', 'Lecture Notes',
        'Dialogue Practice', 'Story Listening', 'News Listening',
        'Accent Training', 'Speed Listening', 'Inference Practice',
    ],
    Speaking: [
        'Pronunciation Drill', 'Mock Interview', 'Topic Discussion',
        'Tongue Twisters', 'Storytelling', 'Debate Practice',
        'Vocabulary Speaking', 'Role Play', 'Presentation Skills',
    ],
    Reading: [
        'Passage Comprehension', 'Vocabulary Builder', 'Speed Reading',
        'Critical Analysis', 'Inference Questions', 'Summary Writing',
        'Main Idea Finding', 'Context Clues', 'Article Reading',
    ],
    Writing: [
        'Essay Draft', 'Grammar Exercises', 'Sentence Structuring',
        'Paragraph Writing', 'Email Writing', 'Descriptive Writing',
        'Punctuation Practice', 'Vocabulary in Context', 'Story Completion',
    ],
};

// ─── Smart 30-Day Path Generator ─────────────────────────────────────────────
/**
 * Generates a highly personalized 30-day learning path from real API accuracy data.
 *
 * Algorithm:
 *  1. Skill priority is determined by accuracy (5 tiers — lower accuracy = higher priority).
 *  2. Modules within each skill are sorted weakest-first (by individual module percentage)
 *     so the student always practices what they struggle with most.
 *  3. Days 1-10 → Foundation (easy, 3 tasks). Days 11-20 → Practice (medium, 4 tasks).
 *     Days 21-30 → Mastery (hard, 5 tasks).
 *  4. Each day: primary skill is drawn from the weighted pool; remaining slots are filled
 *     by the next highest-priority skills.
 *  5. Module selection rotates independently per skill so no module repeats consecutively.
 */
function generateSmartPath(accuracy) {
    const SKILL_LABELS = {
        listening: 'Listening',
        speaking:  'Speaking',
        reading:   'Reading',
        writing:   'Writing',
    };
    const ALL_SKILLS = ['Listening', 'Speaking', 'Reading', 'Writing'];

    // ── Step 1: Build sorted module pools per skill ───────────────────────────
    // Modules sorted ascending by percentage → weakest practiced first.
    const modulePool = {};
    for (const [key, label] of Object.entries(SKILL_LABELS)) {
        const skillData = accuracy?.modules?.[key];
        let records = [];

        if (skillData?.records?.length > 0) {
            records = [...skillData.records]
                .sort((a, b) =>
                    (parseFloat(a.percentage) || 0) - (parseFloat(b.percentage) || 0)
                )
                .map(r => ({
                    module_name: r.module_name  || r.moduleName  || '',
                    module_icon: r.module_icon  || r.moduleIcon  || '',
                    complexity:  r.complexity   || 'easy',
                    percentage:  parseFloat(r.percentage) || 0,
                    count:       r.count        || 0,
                    course_name: r.course_name  || r.courseName  || '',
                }));
        } else {
            // Use fallback names when this skill has no API records
            records = FALLBACK_MODULES[label].map(name => ({
                module_name: name, module_icon: '', complexity: 'easy',
                percentage: 0, count: 0, course_name: '',
            }));
        }
        modulePool[label] = records;
    }

    // ── Step 2: Calculate 5-tier skill priority ───────────────────────────────
    // Lower accuracy → higher priority → appears more often in the path.
    function getPriority(pct) {
        if (pct < 40) return 5;   // Critical
        if (pct < 60) return 4;   // Weak
        if (pct < 75) return 3;   // Moderate
        if (pct < 90) return 2;   // Good
        return 1;                  // Strong (maintenance only)
    }

    const skillAccuracy = {
        Listening: parseFloat(accuracy?.listening) || 50,
        Speaking:  parseFloat(accuracy?.speaking)  || 50,
        Reading:   parseFloat(accuracy?.reading)   || 50,
        Writing:   parseFloat(accuracy?.writing)   || 50,
    };

    const priority = {};
    for (const skill of ALL_SKILLS) {
        priority[skill] = getPriority(skillAccuracy[skill]);
    }

    // ── Step 3: Build weighted skill pool ────────────────────────────────────
    // A skill with priority 5 appears 5× in the pool, so it is selected 5× more often.
    const weightedPool = [];
    for (const skill of ALL_SKILLS) {
        for (let i = 0; i < priority[skill]; i++) weightedPool.push(skill);
    }

    // Sort skills by priority desc for consistent secondary slot filling
    const skillsByPriority = [...ALL_SKILLS].sort((a, b) => priority[b] - priority[a]);

    // ── Step 4: Independent rotating module indices per skill ─────────────────
    // Each skill has its own cursor that advances independently,
    // ensuring no module repeats on back-to-back days.
    const cursor = { Listening: 0, Speaking: 0, Reading: 0, Writing: 0 };

    function nextModule(skill) {
        const pool = modulePool[skill];
        const record = pool[cursor[skill] % pool.length];
        cursor[skill]++;
        return record;
    }

    // ── Step 5: Build 30 days ─────────────────────────────────────────────────
    const PHASES = [
        { days: [1,  10], difficulty: 'easy',   taskCount: 3, count: 2, label: 'Foundation' },
        { days: [11, 20], difficulty: 'medium',  taskCount: 4, count: 3, label: 'Practice'   },
        { days: [21, 30], difficulty: 'hard',    taskCount: 5, count: 4, label: 'Mastery'    },
    ];

    function getPhase(day) {
        return PHASES.find(p => day >= p.days[0] && day <= p.days[1]);
    }

    const path = [];

    for (let day = 1; day <= 30; day++) {
        const phase       = getPhase(day);
        const primarySkill = weightedPool[(day - 1) % weightedPool.length];

        // Fill today's skill slots: primary first, then next highest-priority skills
        const otherSkills  = skillsByPriority.filter(s => s !== primarySkill);
        const todaySkills  = [primarySkill, ...otherSkills].slice(0, phase.taskCount);

        const tasks = todaySkills.map(skill => {
            const mod = nextModule(skill);
            return {
                skill,
                module:      mod.module_name,
                module_icon: mod.module_icon,
                complexity:  mod.complexity || phase.difficulty,
                course_name: mod.course_name,
                count:       phase.count,
                difficulty:  phase.difficulty,
            };
        });

        const focus = `${primarySkill} ${phase.label} — Day ${day}`;
        path.push({ day, focus, tasks });
    }

    return path;
}

// ─── Routes ──────────────────────────────────────────────────────────────────

app.post('/api/get-learning-path', async (req, res) => {
    try {
        const { user_id } = req.body;
        const activePath  = await LearningPath.findOne({ user_id, status: 'active' });
        if (activePath) return res.json({ exists: true, path: activePath });
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

        activePath.path[dayIndex].completed    = true;
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

        if (!user_id) {
            return res.status(400).json({ error: 'user_id is required.' });
        }

        const existingPath = await LearningPath.findOne({ user_id, status: 'active' });
        if (existingPath) {
            return res.status(400).json({ error: 'Active path exists.' });
        }

        console.log(`[PathGen] Generating 30-day path for user: ${user_id}`);
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
                completed:    false,
                completed_at: null,
            })),
        });

        const savedDoc = await newPath.save();
        console.log(`[PathGen] 30-day path saved for user: ${user_id}`);
        res.json(savedDoc);

    } catch (error) {
        console.error('[PathGen] Error:', error.message);
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));