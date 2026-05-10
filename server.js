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

// ─── Fallback module names (when API provides no records) ─────────────────────
const FALLBACK_MODULES = {
    Listening: ['Audio Comprehension', 'Podcast Listening', 'Lecture Notes',
                'Dialogue Practice', 'Story Listening', 'News Listening',
                'Accent Training', 'Speed Listening', 'Inference Practice'],
    Speaking:  ['Pronunciation Drill', 'Mock Interview', 'Topic Discussion',
                'Tongue Twisters', 'Storytelling', 'Debate Practice',
                'Vocabulary Speaking', 'Role Play', 'Presentation Skills'],
    Reading:   ['Passage Comprehension', 'Vocabulary Builder', 'Speed Reading',
                'Critical Analysis', 'Inference Questions', 'Summary Writing',
                'Main Idea Finding', 'Context Clues', 'Article Reading'],
    Writing:   ['Essay Draft', 'Grammar Exercises', 'Sentence Structuring',
                'Paragraph Writing', 'Email Writing', 'Descriptive Writing',
                'Punctuation Practice', 'Vocabulary in Context', 'Story Completion'],
};

// ═════════════════════════════════════════════════════════════════════════════
//  PERSONALIZED PATH GENERATOR — Condition Engine
// ═════════════════════════════════════════════════════════════════════════════
/**
 * Generates a 30-day personalized path using a multi-layer condition engine:
 *
 * LAYER 1 — Skill-level conditions (based on overall % for L/S/R/W):
 *   Critical < 40%  → Priority ×5, intensive focus in all 3 phases
 *   Weak     40-60% → Priority ×4, heavy early-phase emphasis
 *   Moderate 60-75% → Priority ×3, balanced across phases
 *   Good     75-90% → Priority ×2, lighter touch, maintenance
 *   Strong   ≥ 90%  → Priority ×1, spaced review only
 *
 * LAYER 2 — Module-level conditions (based on module %, count, complexity):
 *   Score = (100 - pct) × 0.6             → weak modules score higher
 *         + count bonus (0 attempts = +30) → untouched modules get urgent slot
 *         + complexity bonus              → easy modules slightly more urgent
 *   Modules are sorted by score descending → weakest always scheduled first
 *
 * LAYER 3 — Phase-aware module selection:
 *   Modules are bucketed into 3 learning phases by their complexity:
 *     easy   → Phase 1 (Foundation, days 1-10)
 *     medium → Phase 2 (Practice,   days 11-20)
 *     hard   → Phase 3 (Mastery,    days 21-30)
 *   Within each phase, modules with score < 50% are doubled-up (appear twice)
 *   to ensure the student revisits their worst modules before moving forward.
 *
 * LAYER 4 — Smart focus labels:
 *   The "focus" label for each day reflects the actual condition of the
 *   primary skill (e.g., "Speaking: Emergency Focus — Day 3")
 */
function generateSmartPath(accuracy) {

    const SKILL_LABELS = {
        listening: 'Listening',
        speaking:  'Speaking',
        reading:   'Reading',
        writing:   'Writing',
    };
    const ALL_SKILLS = ['Listening', 'Speaking', 'Reading', 'Writing'];

    // ── CONDITION HELPERS ────────────────────────────────────────────────────

    /** LAYER 1: skill-level classification */
    function classifySkill(pct) {
        if (pct < 40) return { tier: 'Critical',  priority: 5, verb: 'Emergency Focus'  };
        if (pct < 60) return { tier: 'Weak',      priority: 4, verb: 'Intensive Practice'};
        if (pct < 75) return { tier: 'Moderate',  priority: 3, verb: 'Skill Building'   };
        if (pct < 90) return { tier: 'Good',      priority: 2, verb: 'Refinement'       };
        return             { tier: 'Strong',     priority: 1, verb: 'Mastery Review'   };
    }

    /** LAYER 2: module-level priority score — higher = scheduled sooner & more often */
    function moduleScore(pct, count, complexity) {
        let score = (100 - pct) * 0.6;          // low accuracy → high score
        if (count === 0)      score += 30;       // never attempted → urgent
        else if (count < 3)   score += 15;       // barely touched
        else if (count < 7)   score += 5;        // some exposure
        if (complexity === 'easy')   score += 5; // easy first
        else if (complexity === 'hard') score -= 5; // hard later
        return score;
    }

    /** LAYER 3: which learning phase this module belongs to */
    function modulePhase(complexity, pct) {
        if (complexity === 'hard')   return 3;   // hard → Mastery
        if (complexity === 'medium') return 2;   // medium → Practice
        return 1;                                 // easy or unset → Foundation
    }

    // ── STEP 1: Parse & score all modules from API data ──────────────────────
    const modulePool = {};   // { Listening: [...sorted records], ... }

    for (const [key, label] of Object.entries(SKILL_LABELS)) {
        const skillData = accuracy?.modules?.[key];
        let records = [];

        if (skillData?.records?.length > 0) {
            records = skillData.records.map(r => {
                const pct        = parseFloat(r.percentage) || 0;
                const count      = r.count || 0;
                const complexity = r.complexity || 'easy';
                return {
                    module_name:     r.module_name  || r.moduleName  || '',
                    module_icon:     r.module_icon  || r.moduleIcon  || '',
                    complexity,
                    percentage:      pct,
                    count,
                    course_name:     r.course_name  || r.courseName  || '',
                    _score:          moduleScore(pct, count, complexity),
                    _phase:          modulePhase(complexity, pct),
                };
            });

            // Sort by score descending: weakest / untouched modules first
            records.sort((a, b) => b._score - a._score);

            // Double-up modules where percentage < 50 so they get extra repetition
            const urgentMods = records.filter(r => r.percentage < 50);
            records = [...urgentMods, ...records];
        } else {
            // Fallback: generate placeholder records
            records = FALLBACK_MODULES[label].map((name, i) => ({
                module_name: name, module_icon: '', complexity: 'easy',
                percentage: 0, count: 0, course_name: '',
                _score: 100 - i * 5, _phase: 1,
            }));
        }

        modulePool[label] = records;
    }

    // ── STEP 2: Classify each skill and build weighted pool ───────────────────
    const skillAccuracy = {
        Listening: parseFloat(accuracy?.listening) || 50,
        Speaking:  parseFloat(accuracy?.speaking)  || 50,
        Reading:   parseFloat(accuracy?.reading)   || 50,
        Writing:   parseFloat(accuracy?.writing)   || 50,
    };

    const skillInfo = {};
    for (const skill of ALL_SKILLS) {
        skillInfo[skill] = classifySkill(skillAccuracy[skill]);
    }

    // Weighted pool: a skill with priority 5 appears 5× more than one with priority 1
    const weightedPool = [];
    for (const skill of ALL_SKILLS) {
        for (let i = 0; i < skillInfo[skill].priority; i++) {
            weightedPool.push(skill);
        }
    }

    // Sorted order for filling secondary task slots each day
    const skillsByPriority = [...ALL_SKILLS].sort(
        (a, b) => skillInfo[b].priority - skillInfo[a].priority
    );

    // ── STEP 3: Bucket modules per skill per phase ────────────────────────────
    // Each [skill][phase] bucket gets its own rotating cursor so modules
    // within a phase advance independently and don't repeat on consecutive days.
    const phaseBuckets = {};
    const cursor       = {};

    for (const skill of ALL_SKILLS) {
        phaseBuckets[skill] = { 1: [], 2: [], 3: [] };
        cursor[skill]       = { 1: 0, 2: 0, 3: 0 };

        for (const mod of modulePool[skill]) {
            phaseBuckets[skill][mod._phase].push(mod);
        }

        // Ensure no phase is empty (fall back to all modules if needed)
        for (const ph of [1, 2, 3]) {
            if (phaseBuckets[skill][ph].length === 0) {
                phaseBuckets[skill][ph] = [...modulePool[skill]];
            }
        }
    }

    function nextModule(skill, phase) {
        const bucket = phaseBuckets[skill][phase];
        const mod    = bucket[cursor[skill][phase] % bucket.length];
        cursor[skill][phase]++;
        return mod;
    }

    // ── STEP 4: Build the 30-day plan ─────────────────────────────────────────
    const PHASE_DEFS = [
        { range: [1,  10], phaseNum: 1, difficulty: 'easy',   taskCount: 3, count: 2, label: 'Foundation' },
        { range: [11, 20], phaseNum: 2, difficulty: 'medium', taskCount: 4, count: 3, label: 'Practice'   },
        { range: [21, 30], phaseNum: 3, difficulty: 'hard',   taskCount: 5, count: 4, label: 'Mastery'    },
    ];

    function getPhase(day) {
        return PHASE_DEFS.find(p => day >= p.range[0] && day <= p.range[1]);
    }

    const path = [];

    for (let day = 1; day <= 30; day++) {
        const phase        = getPhase(day);
        const primarySkill = weightedPool[(day - 1) % weightedPool.length];

        // Primary skill fills slot 0; remaining slots go to next highest-priority skills
        const otherSkills = skillsByPriority.filter(s => s !== primarySkill);
        const todaySkills = [primarySkill, ...otherSkills].slice(0, phase.taskCount);

        const tasks = todaySkills.map(skill => {
            const mod = nextModule(skill, phase.phaseNum);
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

        // LAYER 4: Smart focus label reflects the actual skill condition
        const info  = skillInfo[primarySkill];
        const focus = `${primarySkill}: ${info.verb} — Day ${day}`;

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

        console.log(`[PathGen] Building personalized 30-day path for user: ${user_id}`);
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

// ── App Setup ─────────────────────────────────────────────────────────────────
const app = express();
app.use(express.json());
app.use(cors());

// ── Routes ────────────────────────────────────────────────────────────────────
app.use('/api', learningPathRoutes);

// ── Server ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));