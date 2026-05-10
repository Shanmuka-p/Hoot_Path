require('dotenv').config();
const express    = require('express');
const mongoose   = require('mongoose');
const cors       = require('cors');
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
//  PERSONALIZED PATH GENERATOR  —  4-Layer Condition Engine
// ═════════════════════════════════════════════════════════════════════════════
//
//  LAYER 1  Skill-level tier (overall % per L/S/R/W):
//    Critical  < 40%  → priority ×5  "Emergency Focus"
//    Weak     40-60%  → priority ×4  "Intensive Practice"
//    Moderate 60-75%  → priority ×3  "Skill Building"
//    Good     75-90%  → priority ×2  "Refinement"
//    Strong   ≥ 90%   → priority ×1  "Mastery Review"
//
//  LAYER 2  Module-level score (per individual module record):
//    score = (100 - pct) × 0.6    → weak accuracy → high urgency
//          + 30  if count === 0   → never attempted → critical slot
//          + 15  if count <  3   → barely touched
//          + 5   if count <  7   → some exposure
//          + 5   if complexity === 'easy'
//          - 5   if complexity === 'hard'
//    Modules with percentage < 50 are doubled for extra repetition.
//
//  LAYER 3  Phase-aware scheduling:
//    easy   → Phase 1  Foundation  days  1-10  (3 tasks/day)
//    medium → Phase 2  Practice    days 11-20  (4 tasks/day)
//    hard   → Phase 3  Mastery     days 21-30  (5 tasks/day)
//
//  LAYER 4  Smart focus labels:
//    "Speaking: Emergency Focus — Day 3"  (not a generic label)
// ─────────────────────────────────────────────────────────────────────────────
function generateSmartPath(accuracy) {
    const SKILL_LABELS = {
        listening: 'Listening',
        speaking:  'Speaking',
        reading:   'Reading',
        writing:   'Writing',
    };
    const ALL_SKILLS = ['Listening', 'Speaking', 'Reading', 'Writing'];

    // ── LAYER 1: skill classification ─────────────────────────────────────────
    function classifySkill(pct) {
        if (pct < 40) return { tier: 'Critical',  priority: 5, verb: 'Emergency Focus'   };
        if (pct < 60) return { tier: 'Weak',      priority: 4, verb: 'Intensive Practice' };
        if (pct < 75) return { tier: 'Moderate',  priority: 3, verb: 'Skill Building'    };
        if (pct < 90) return { tier: 'Good',      priority: 2, verb: 'Refinement'        };
        return             { tier: 'Strong',     priority: 1, verb: 'Mastery Review'    };
    }

    // ── LAYER 2: module priority score ────────────────────────────────────────
    function calcModuleScore(pct, count, complexity) {
        let score = (100 - pct) * 0.6;
        if (count === 0)      score += 30;
        else if (count < 3)   score += 15;
        else if (count < 7)   score += 5;
        if (complexity === 'easy')   score += 5;
        if (complexity === 'hard')   score -= 5;
        return score;
    }

    // ── LAYER 3: preferred phase by complexity ────────────────────────────────
    function preferredPhase(complexity) {
        if (complexity === 'hard')   return 3;
        if (complexity === 'medium') return 2;
        return 1;
    }

    // ── STEP 1: Parse & score modules from API data ───────────────────────────
    const modulePool = {};

    for (const [key, label] of Object.entries(SKILL_LABELS)) {
        const skillData = accuracy?.modules?.[key];
        let records = [];

        if (skillData?.records?.length > 0) {
            records = skillData.records.map(r => {
                const pct        = parseFloat(r.percentage) || 0;
                const count      = r.count || 0;
                const complexity = r.complexity || 'easy';
                return {
                    module_name: r.module_name  || r.moduleName  || '',
                    module_icon: r.module_icon  || r.moduleIcon  || '',
                    complexity,
                    percentage:  pct,
                    count,
                    course_name: r.course_name  || r.courseName  || '',
                    _score:      calcModuleScore(pct, count, complexity),
                    _phase:      preferredPhase(complexity),
                };
            });

            // Sort highest-score first (weakest / untouched modules at the front)
            records.sort((a, b) => b._score - a._score);

            // Double-up urgent modules (< 50%) for extra repetition
            const urgent = records.filter(r => r.percentage < 50);
            records = [...urgent, ...records];
        } else {
            records = FALLBACK_MODULES[label].map((name, i) => ({
                module_name: name, module_icon: '', complexity: 'easy',
                percentage: 0, count: 0, course_name: '',
                _score: 100 - i * 5, _phase: 1,
            }));
        }

        modulePool[label] = records;
    }

    // ── STEP 2: Classify skills & build weighted scheduling pool ──────────────
    const skillAccuracy = {
        Listening: parseFloat(accuracy?.listening) || 50,
        Speaking:  parseFloat(accuracy?.speaking)  || 50,
        Reading:   parseFloat(accuracy?.reading)   || 50,
        Writing:   parseFloat(accuracy?.writing)   || 50,
    };

    const skillInfo = {};
    for (const s of ALL_SKILLS) skillInfo[s] = classifySkill(skillAccuracy[s]);

    const weightedPool = [];
    for (const s of ALL_SKILLS) {
        for (let i = 0; i < skillInfo[s].priority; i++) weightedPool.push(s);
    }

    const skillsByPriority = [...ALL_SKILLS].sort(
        (a, b) => skillInfo[b].priority - skillInfo[a].priority
    );

    // ── STEP 3: Bucket modules per skill × phase, each with its own cursor ────
    const buckets = {};
    const cursor  = {};
    for (const s of ALL_SKILLS) {
        buckets[s] = { 1: [], 2: [], 3: [] };
        cursor[s]  = { 1: 0,  2: 0,  3: 0  };
        for (const mod of modulePool[s]) buckets[s][mod._phase].push(mod);
        // Fill any empty phase bucket as a fallback
        for (const ph of [1, 2, 3]) {
            if (buckets[s][ph].length === 0) buckets[s][ph] = [...modulePool[s]];
        }
    }

    function nextModule(skill, phase) {
        const bucket = buckets[skill][phase];
        const mod    = bucket[cursor[skill][phase] % bucket.length];
        cursor[skill][phase]++;
        return mod;
    }

    // ── STEP 4: Build the 30-day plan ─────────────────────────────────────────
    const PHASE_DEFS = [
        { range: [1,  10], phaseNum: 1, difficulty: 'easy',   taskCount: 3, count: 2 },
        { range: [11, 20], phaseNum: 2, difficulty: 'medium', taskCount: 4, count: 3 },
        { range: [21, 30], phaseNum: 3, difficulty: 'hard',   taskCount: 5, count: 4 },
    ];

    const path = [];

    for (let day = 1; day <= 30; day++) {
        const phase        = PHASE_DEFS.find(p => day >= p.range[0] && day <= p.range[1]);
        const primarySkill = weightedPool[(day - 1) % weightedPool.length];

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

        // LAYER 4: smart label reflects the actual skill tier
        const focus = `${primarySkill}: ${skillInfo[primarySkill].verb} — Day ${day}`;
        path.push({ day, focus, tasks });
    }

    return path;
}

// ─── Routes ──────────────────────────────────────────────────────────────────

app.post('/api/get-learning-path', async (req, res) => {
    try {
        const { user_id } = req.body;
        if (!user_id) return res.status(400).json({ error: 'user_id is required.' });

        const activePath = await LearningPath.findOne({ user_id, status: 'active' });
        if (activePath) return res.json({ exists: true, path: activePath });
        return res.json({ exists: false });
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

        console.log(`[PathGen] Building personalized path for user: ${user_id}`);
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
        console.log(`[PathGen] Path saved for user: ${user_id}`);
        res.json(savedDoc);

    } catch (error) {
        console.error('[PathGen] Error:', error.message);
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/complete-day', async (req, res) => {
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
        res.status(500).json({ error: error.message });
    }
});

// ─── Start Server ─────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
