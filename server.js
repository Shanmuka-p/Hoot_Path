require('dotenv').config();
const express      = require('express');
const mongoose     = require('mongoose');
const cors         = require('cors');
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

// ─── OpenRouter Free Models (priority order) ──────────────────────────────────
const DEFAULT_MODELS = [
    'meta-llama/llama-3.1-8b-instruct:free',
    'mistralai/mistral-7b-instruct:free',
    'google/gemma-3-12b-it:free',
    'deepseek/deepseek-r1-distill-qwen-14b:free',
    'microsoft/phi-3-mini-128k-instruct:free',
];

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS — Extract real API module data
// ─────────────────────────────────────────────────────────────────────────────

/** Returns structured module lists per skill from real API accuracy data. */
function extractModules(accuracy) {
    const out = { listening: [], speaking: [], reading: [], writing: [] };
    for (const key of Object.keys(out)) {
        const records = accuracy?.modules?.[key]?.records || [];
        out[key] = records
            .map(r => ({
                module_name: r.module_name || r.moduleName || '',
                module_icon: r.module_icon || r.moduleIcon || '',
                course_name: r.course_name || r.courseName || '',
                complexity:  r.complexity  || 'easy',
                percentage:  parseFloat(r.percentage) || 0,
                count:       r.count || 0,
            }))
            .filter(r => r.module_name.trim() !== '');
    }
    return out;
}

/** Icon lookup map: lowercase module name → { module_icon, course_name } */
function buildIconMap(modules) {
    const map = {};
    for (const list of Object.values(modules)) {
        for (const m of list) {
            map[m.module_name.toLowerCase()] = {
                module_icon: m.module_icon,
                course_name: m.course_name,
            };
        }
    }
    return map;
}

/** Set of all valid lowercase module names for validation. */
function buildValidNameSet(modules) {
    const set = new Set();
    for (const list of Object.values(modules)) {
        for (const m of list) set.add(m.module_name.toLowerCase());
    }
    return set;
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROMPT — Feeds real accuracy + module data to the LLM
// ─────────────────────────────────────────────────────────────────────────────
function buildPrompt(accuracy, modules) {
    const tier = pct => {
        if (pct < 40) return 'CRITICAL';
        if (pct < 60) return 'WEAK';
        if (pct < 75) return 'MODERATE';
        if (pct < 90) return 'GOOD';
        return 'STRONG';
    };

    const l = parseFloat(accuracy?.listening) || 0;
    const s = parseFloat(accuracy?.speaking)  || 0;
    const r = parseFloat(accuracy?.reading)   || 0;
    const w = parseFloat(accuracy?.writing)   || 0;

    const fmtModules = list =>
        list.length === 0
            ? '  (no data)'
            : list
                .sort((a, b) => a.percentage - b.percentage)
                .map(m => `  - "${m.module_name}" | accuracy: ${m.percentage}% | attempts: ${m.count} | complexity: ${m.complexity}`)
                .join('\n');

    const critical = [['Listening',l],['Speaking',s],['Reading',r],['Writing',w]]
        .filter(([,p]) => p < 40).map(([n]) => n);

    return `You are an expert English language AI mentor. Analyze the student's real performance data and generate a personalized 30-day learning path.

=== STUDENT SKILL ACCURACY ===
Listening : ${l}%  [${tier(l)}]
Speaking  : ${s}%  [${tier(s)}]
Reading   : ${r}%  [${tier(r)}]
Writing   : ${w}%  [${tier(w)}]

=== AVAILABLE MODULES — USE ONLY THESE EXACT NAMES ===
LISTENING:
${fmtModules(modules.listening)}

SPEAKING:
${fmtModules(modules.speaking)}

READING:
${fmtModules(modules.reading)}

WRITING:
${fmtModules(modules.writing)}

=== RULES ===
1. Days  1-10 (Foundation): 3 tasks/day, difficulty="easy",   count=2
2. Days 11-20 (Practice):   4 tasks/day, difficulty="medium", count=3
3. Days 21-30 (Mastery):    5 tasks/day, difficulty="hard",   count=4
4. ${critical.length > 0 ? `CRITICAL skills (${critical.join(', ')}) MUST appear in EVERY single day.` : 'Distribute skills proportionally — lowest accuracy = highest frequency.'}
5. Modules with lower accuracy must appear more often across the 30 days.
6. Modules with 0 attempts must be introduced in days 1-10.
7. Never repeat the same module on back-to-back days.
8. STRICT: Use ONLY the exact module names from the lists above. DO NOT invent names.

Return ONLY a valid JSON array of exactly 30 objects. No markdown, no explanation.
[{"day":1,"focus":"Listening: Emergency Focus — Day 1","tasks":[{"skill":"Listening","module":"<exact name>","difficulty":"easy","count":2},...]}]`;
}

// ─────────────────────────────────────────────────────────────────────────────
//  PARSER / VALIDATOR
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Parses the LLM response and validates:
 *   - Valid JSON array of ≥28 days
 *   - Each day has day/focus/tasks fields
 *   - Every module name used exists in the real API data
 * Returns the parsed path or null on any failure.
 */
function parseAndValidate(rawText, validNames) {
    try {
        let text = rawText.trim()
            .replace(/```json\s*/gi, '')
            .replace(/```\s*/gi, '');

        const start = text.indexOf('[');
        const end   = text.lastIndexOf(']');
        if (start === -1 || end <= start) return null;

        const parsed = JSON.parse(text.slice(start, end + 1));
        if (!Array.isArray(parsed) || parsed.length < 28) return null;

        for (const day of parsed) {
            if (typeof day.day !== 'number' || !day.focus) return null;
            if (!Array.isArray(day.tasks) || day.tasks.length === 0) return null;

            for (const task of day.tasks) {
                if (!task.skill || !task.module) return null;
                // Reject if LLM invented a module name not in real API data
                if (validNames.size > 0 && !validNames.has(task.module.toLowerCase())) {
                    console.warn(`[LLM] Rejected — unknown module: "${task.module}"`);
                    return null;
                }
            }
        }
        return parsed;
    } catch {
        return null;
    }
}

/** Injects module_icon and course_name from real API data into LLM tasks. */
function enrichPath(path, iconMap) {
    return path.map(day => ({
        ...day,
        tasks: day.tasks.map(task => ({
            ...task,
            difficulty:  task.difficulty || 'easy',
            count:       task.count || 2,
            module_icon: (iconMap[task.module.toLowerCase()] || {}).module_icon || '',
            course_name: (iconMap[task.module.toLowerCase()] || {}).course_name || '',
        })),
    }));
}

// ─────────────────────────────────────────────────────────────────────────────
//  OPENROUTER CALL
// ─────────────────────────────────────────────────────────────────────────────
async function callOpenRouter(prompt, apiKey, model) {
    const ctrl    = new AbortController();
    const timeout = setTimeout(() => ctrl.abort(), 50000);
    try {
        const res = await fetch('https://openrouter.ai/api/v1/chat/completions', {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${apiKey}`,
                'Content-Type':  'application/json',
                'HTTP-Referer':  'https://hoot-path.onrender.com',
                'X-Title':       'Hoot AI Mentor',
            },
            body: JSON.stringify({
                model,
                messages: [
                    {
                        role:    'system',
                        content: 'You are an expert English language mentor. Return ONLY valid raw JSON arrays. No markdown, no code fences.',
                    },
                    { role: 'user', content: prompt },
                ],
                max_tokens:  6000,
                temperature: 0.3,
            }),
            signal: ctrl.signal,
        });

        if (res.status === 429) {
            const e = new Error('Rate limit'); e.isRateLimit = true; throw e;
        }
        if (!res.ok) {
            throw new Error(`OpenRouter HTTP ${res.status}: ${(await res.text()).slice(0, 150)}`);
        }
        const data = await res.json();
        return data.choices?.[0]?.message?.content || null;
    } finally {
        clearTimeout(timeout);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FALLBACK CHAIN — key 1 × all models → key 2 × all models → ... → error
// ─────────────────────────────────────────────────────────────────────────────
/**
 * Tries every (key × model) combination in order.
 * On rate-limit or invalid response: automatically tries the next combination.
 * Returns { path, model } on success, or throws if all attempts are exhausted.
 */
async function generateWithFallback(accuracy) {
    const keys = (process.env.OPENROUTER_KEYS || '')
        .split(',').map(k => k.trim()).filter(Boolean);

    if (keys.length === 0) {
        throw new Error('No OPENROUTER_KEYS configured. Add keys in Render Dashboard → Environment.');
    }

    const models = process.env.OPENROUTER_MODELS
        ? process.env.OPENROUTER_MODELS.split(',').map(m => m.trim()).filter(Boolean)
        : DEFAULT_MODELS;

    // Extract real API modules once for prompt + validation
    const modules   = extractModules(accuracy);
    const iconMap   = buildIconMap(modules);
    const validNames = buildValidNameSet(modules);
    const prompt    = buildPrompt(accuracy, modules);

    const attempts = [];

    for (const key of keys) {
        const keyLabel = `***${key.slice(-6)}`;
        for (const model of models) {
            try {
                console.log(`[LLM] Trying "${model}" (key ${keyLabel})`);
                const raw = await callOpenRouter(prompt, key, model);

                if (!raw) {
                    console.warn(`[LLM] Empty response from "${model}"`);
                    attempts.push(`${model}: empty response`);
                    continue;
                }

                const parsed = parseAndValidate(raw, validNames);
                if (parsed) {
                    console.log(`[LLM] ✅ Valid ${parsed.length}-day path from "${model}"`);
                    return { path: enrichPath(parsed, iconMap), model };
                }

                console.warn(`[LLM] Invalid/non-API JSON from "${model}"`);
                attempts.push(`${model}: invalid JSON or unknown modules`);

            } catch (err) {
                if (err.isRateLimit) {
                    console.warn(`[LLM] Rate limit on "${model}" (key ${keyLabel})`);
                    attempts.push(`${model}: rate limited`);
                    continue;
                }
                if (err.name === 'AbortError') {
                    console.warn(`[LLM] Timeout on "${model}"`);
                    attempts.push(`${model}: timeout`);
                    continue;
                }
                console.warn(`[LLM] Error from "${model}": ${err.message}`);
                attempts.push(`${model}: ${err.message}`);
            }
        }
        console.log(`[LLM] All models exhausted for key ${keyLabel}. Trying next key.`);
    }

    throw new Error(
        `All LLM keys and models exhausted. Attempts: ${attempts.join(' | ')}`
    );
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROUTES
// ─────────────────────────────────────────────────────────────────────────────

app.post('/api/get-learning-path', async (req, res) => {
    try {
        const { user_id } = req.body;
        if (!user_id) return res.status(400).json({ error: 'user_id is required.' });

        const active = await LearningPath.findOne({ user_id, status: 'active' });
        if (active) return res.json({ exists: true, path: active });
        return res.json({ exists: false });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

app.post('/api/generate-learning-path', async (req, res) => {
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
});

app.post('/api/complete-day', async (req, res) => {
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
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
