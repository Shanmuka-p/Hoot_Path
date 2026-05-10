require('dotenv').config();
const express  = require('express');
const mongoose = require('mongoose');
const cors     = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const LearningPath = require('./models/LearningPath');

const app = express();
app.use(express.json());
app.use(cors());

// ─── Gemini Client ────────────────────────────────────────────────────────────
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const geminiModel = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

// ─── MongoDB ──────────────────────────────────────────────────────────────────
mongoose.connect(process.env.MONGO_URI, {
    serverSelectionTimeoutMS: 30000,
    socketTimeoutMS: 45000,
    connectTimeoutMS: 30000,
})
    .then(() => console.log('MongoDB Connected'))
    .catch(err => console.log('MongoDB Error:', err));

// ─── Fallback: Local Smart Path Generator ────────────────────────────────────
// Used ONLY when Gemini is unavailable (no key, quota exceeded, etc.)

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

function extractModuleData(accuracy) {
    const modules = accuracy?.modules || {};
    const result  = {};
    const skillMap = { listening: 'Listening', speaking: 'Speaking', reading: 'Reading', writing: 'Writing' };

    for (const [key, capitalized] of Object.entries(skillMap)) {
        const skillData = modules[key];
        if (skillData && skillData.records && Array.isArray(skillData.records) && skillData.records.length > 0) {
            result[capitalized] = skillData.records.map(r => ({
                module_name:  r.module_name  || r.moduleName  || '',
                module_icon:  r.module_icon  || r.moduleIcon  || '',
                complexity:   r.complexity   || 'easy',
                percentage:   parseFloat(r.percentage) || 0,
                count:        r.count        || 0,
                course_name:  r.course_name  || r.courseName  || '',
            }));
        } else {
            result[capitalized] = FALLBACK_MODULES[capitalized].map(name => ({
                module_name: name, module_icon: '', complexity: 'easy',
                percentage: 0, count: 0, course_name: '',
            }));
        }
    }
    return result;
}

function pickModuleRecord(moduleRecords, skill, dayIndex) {
    const records = moduleRecords[skill] || [];
    if (records.length === 0) {
        return { module_name: 'Practice', module_icon: '', complexity: 'easy', percentage: 0, count: 0, course_name: '' };
    }
    return records[dayIndex % records.length];
}

function generateSmartPath(accuracy) {
    const skills    = ['Listening', 'Speaking', 'Reading', 'Writing'];
    const skillKeys = ['listening', 'speaking', 'reading', 'writing'];
    const moduleRecords = extractModuleData(accuracy);

    const weights = {};
    skills.forEach((skill, i) => {
        const acc = parseFloat(accuracy[skillKeys[i]]) || 50;
        if (acc < 60)      weights[skill] = 4;
        else if (acc < 80) weights[skill] = 2;
        else               weights[skill] = 1;
    });

    const skillPool = [];
    Object.entries(weights).forEach(([skill, w]) => {
        for (let i = 0; i < w; i++) skillPool.push(skill);
    });

    const path = [];
    for (let day = 1; day <= 30; day++) {
        const difficulty  = getDifficulty(day);
        const count       = getCount(day);
        const taskCount   = 3 + Math.floor((day - 1) / 10);
        const todaySkills = [];
        const primarySkill = skillPool[(day - 1) % skillPool.length];
        todaySkills.push(primarySkill);

        const remaining = skills.filter(s => s !== primarySkill);
        for (let i = 0; todaySkills.length < Math.min(taskCount, 4); i++) {
            todaySkills.push(remaining[i % remaining.length]);
        }

        const tasks = todaySkills.slice(0, taskCount).map((skill, idx) => {
            const record = pickModuleRecord(moduleRecords, skill, day + idx);
            return { skill, module: record.module_name, module_icon: record.module_icon,
                     complexity: record.complexity, course_name: record.course_name, count, difficulty };
        });

        const focusLabels = { easy: 'Foundation', medium: 'Practice', hard: 'Mastery' };
        path.push({ day, focus: `${tasks[0].skill} ${focusLabels[difficulty]} — Day ${day}`, tasks });
    }
    return path;
}

// ─── Gemini: Generate 30-day learning path ───────────────────────────────────
async function generatePathWithGemini(accuracy) {
    const moduleRecords = extractModuleData(accuracy);

    // Summarise real module names per skill for the prompt
    const moduleSummary = Object.entries(moduleRecords).map(([skill, recs]) => {
        const names = recs.map(r => r.module_name).filter(Boolean).join(', ') || 'General Practice';
        return `${skill} modules: ${names}`;
    }).join('\n');

    const prompt = `
You are an expert English language learning coach. Generate a personalized 30-day learning path.

Student's current accuracy:
- Listening: ${accuracy?.listening || 0}%
- Speaking:  ${accuracy?.speaking  || 0}%
- Reading:   ${accuracy?.reading   || 0}%
- Writing:   ${accuracy?.writing   || 0}%

Available modules from the student's course:
${moduleSummary}

Rules:
- Skills below 60% are WEAK — give them the most focus (appear most days).
- Skills 60–80% are MEDIUM — moderate focus.
- Skills above 80% are STRONG — maintenance only.
- Days 1–10: difficulty = "easy", 2 tasks/module. Days 11–20: difficulty = "medium", 3 tasks. Days 21–30: difficulty = "hard", 4 tasks.
- Each day must have 3–5 tasks drawn from the available modules above.
- Use ONLY the exact module names listed above (copy them exactly).
- Vary the tasks day to day — do not repeat the same module on consecutive days.

Return ONLY a valid JSON array of exactly 30 objects. No markdown, no backticks, no explanation.
Each object must match this exact structure:
{
  "day": 1,
  "focus": "Listening Foundation — Day 1",
  "tasks": [
    { "skill": "Listening", "module": "Audio Comprehension", "difficulty": "easy", "count": 2 }
  ]
}
`;

    const result  = await geminiModel.generateContent(prompt);
    const rawText = result.response.text().trim();

    // Strip markdown fences Gemini sometimes wraps around JSON
    let jsonText = rawText
        .replace(/^```(?:json)?\s*/i, '')
        .replace(/\s*```$/i, '')
        .trim();

    // Some Gemini versions return { "path": [...] } or { "days": [...] } — unwrap if needed
    let parsed = JSON.parse(jsonText);
    if (!Array.isArray(parsed)) {
        // Try to find an array inside a wrapper object
        const inner = Object.values(parsed).find(v => Array.isArray(v));
        if (inner) parsed = inner;
        else throw new Error(`Gemini returned a non-array: ${JSON.stringify(parsed).slice(0, 200)}`);
    }
    if (parsed.length < 25) {
        // Accept 25+ days (Gemini occasionally returns 28-30)
        throw new Error(`Gemini returned only ${parsed.length} days (expected 30)`);
    }

    // Enrich tasks with module_icon from real API data (Gemini only knows module names)
    const iconMap = {};
    Object.values(moduleRecords).forEach(recs => {
        recs.forEach(r => { if (r.module_name) iconMap[r.module_name] = r.module_icon || ''; });
    });

    return parsed.map(dayPlan => ({
        ...dayPlan,
        tasks: (dayPlan.tasks || []).map(task => ({
            ...task,
            module_icon: iconMap[task.module] || '',
        })),
    }));
}

// ─── Routes ──────────────────────────────────────────────────────────────────

// ── Debug: verify Gemini API key is working ──────────────────────────────────
app.get('/api/test-gemini', async (req, res) => {
    try {
        const result  = await geminiModel.generateContent('Reply with exactly the word: OK');
        const text    = result.response.text().trim();
        res.json({ status: 'ok', gemini_reply: text, key_prefix: (process.env.GEMINI_API_KEY || '').slice(0, 8) + '...' });
    } catch (err) {
        res.status(500).json({ status: 'error', message: err.message });
    }
});

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

        const existingPath = await LearningPath.findOne({ user_id, status: 'active' });
        if (existingPath) {
            return res.status(400).json({ error: 'Active path exists.' });
        }

        console.log(`[Gemini] Generating 30-day path for user: ${user_id}`);
        // Throws clearly if Gemini fails — no silent fallback, so errors are visible
        const generatedPath = await generatePathWithGemini(accuracy || {});
        console.log(`[Gemini] Path generated successfully for user: ${user_id}`);
        const source = 'gemini';

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
        console.log(`[${source}] 30-day path saved for user: ${user_id}`);
        // Include source so the client knows which engine generated the path
        res.json({ ...savedDoc.toObject(), _source: source });

    } catch (error) {
        console.error('Generate path error:', error.message);
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));