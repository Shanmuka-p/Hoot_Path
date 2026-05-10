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

// ─── OpenRouter Free Models (tried in priority order) ─────────────────────────
// Add OPENROUTER_MODELS to .env to override this list.
const DEFAULT_OPENROUTER_MODELS = [
    'meta-llama/llama-3.1-8b-instruct:free',
    'mistralai/mistral-7b-instruct:free',
    'google/gemma-3-12b-it:free',
    'deepseek/deepseek-r1-distill-qwen-14b:free',
    'microsoft/phi-3-mini-128k-instruct:free',
];

// ─── Fallback Module Names (used when API has no records) ─────────────────────
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
//  SECTION A — LLM INTEGRATION (OpenRouter, multi-key × multi-model fallback)
// ═════════════════════════════════════════════════════════════════════════════

/**
 * Builds a highly detailed prompt for the LLM.
 * Includes real skill % and actual module names from the student's API data,
 * so the LLM generates a genuinely personalised plan.
 */
function buildLLMPrompt(accuracy) {
    const tierLabel = pct => {
        if (pct < 40) return '🔴 CRITICAL';
        if (pct < 60) return '🟠 WEAK';
        if (pct < 75) return '🟡 MODERATE';
        if (pct < 90) return '🟢 GOOD';
        return '⭐ STRONG';
    };

    const l = parseFloat(accuracy?.listening) || 0;
    const s = parseFloat(accuracy?.speaking)  || 0;
    const r = parseFloat(accuracy?.reading)   || 0;
    const w = parseFloat(accuracy?.writing)   || 0;

    // Extract sorted module names (weakest first) from real API data
    const getModules = key => {
        const records = accuracy?.modules?.[key]?.records || [];
        if (records.length === 0) return FALLBACK_MODULES[key.charAt(0).toUpperCase() + key.slice(1)].slice(0, 5).join(', ');
        return records
            .sort((a, b) => (parseFloat(a.percentage) || 0) - (parseFloat(b.percentage) || 0))
            .map(r => `"${r.module_name || r.moduleName}" (${parseFloat(r.percentage) || 0}%)`)
            .join(', ');
    };

    const criticalSkills = [
        ['Listening', l], ['Speaking', s], ['Reading', r], ['Writing', w],
    ].filter(([, pct]) => pct < 40).map(([name]) => name);

    return `You are an expert English language AI coach generating a 30-day personalised study plan.

STUDENT SKILL REPORT:
  Listening : ${l}%  ${tierLabel(l)}
  Speaking  : ${s}%  ${tierLabel(s)}
  Reading   : ${r}%  ${tierLabel(r)}
  Writing   : ${w}%  ${tierLabel(w)}

ACTUAL MODULES FROM STUDENT'S HISTORY (weakest first — USE THESE EXACT NAMES):
  Listening: ${getModules('listening')}
  Speaking : ${getModules('speaking')}
  Reading  : ${getModules('reading')}
  Writing  : ${getModules('writing')}

PERSONALISATION RULES — follow all of them exactly:
1. Days  1-10 (Foundation): 3 tasks per day, difficulty = "easy",  count = 2
2. Days 11-20 (Practice):   4 tasks per day, difficulty = "medium", count = 3
3. Days 21-30 (Mastery):    5 tasks per day, difficulty = "hard",  count = 4
4. ${criticalSkills.length > 0 ? `CRITICAL RULE: ${criticalSkills.join(' and ')} is CRITICAL (<40%). These MUST appear in EVERY single day.` : 'Distribute all 4 skills proportional to their weakness.'}
5. Weakest skills (lowest %) should appear most frequently across all 30 days.
6. Use the EXACT module names listed above — do NOT invent new ones.
7. Each day's "focus" must name the primary skill and phase, e.g. "Speaking: Intensive Practice — Day 5".
8. Vary the modules — do not repeat the same module on consecutive days.

OUTPUT FORMAT: Return ONLY a raw JSON array of exactly 30 objects. No markdown, no code fences, no explanation.
[
  {
    "day": 1,
    "focus": "Listening: Emergency Focus — Day 1",
    "tasks": [
      { "skill": "Listening", "module": "Audio Comprehension", "difficulty": "easy", "count": 2 },
      { "skill": "Speaking",  "module": "Pronunciation Drill", "difficulty": "easy", "count": 2 },
      { "skill": "Reading",   "module": "Passage Comprehension", "difficulty": "easy", "count": 2 }
    ]
  },
  ...
]`;
}

/**
 * Parses and validates the raw string returned by the LLM.
 * Strips markdown code fences, extracts the JSON array, and checks structure.
 * Returns the parsed array on success, or null if invalid.
 */
function parseAndValidateLLMPath(rawText) {
    try {
        let cleaned = rawText.trim();
        // Strip markdown code fences (```json ... ```)
        cleaned = cleaned.replace(/```json\s*/gi, '').replace(/```\s*/gi, '');
        // Find the outermost JSON array
        const start = cleaned.indexOf('[');
        const end   = cleaned.lastIndexOf(']');
        if (start === -1 || end === -1 || end < start) return null;

        const parsed = JSON.parse(cleaned.slice(start, end + 1));

        // Must be an array of at least 28 days (allow slight LLM variance)
        if (!Array.isArray(parsed) || parsed.length < 28) return null;

        // Validate each day object
        for (const dayObj of parsed) {
            if (typeof dayObj.day !== 'number') return null;
            if (!dayObj.focus) return null;
            if (!Array.isArray(dayObj.tasks) || dayObj.tasks.length === 0) return null;
            for (const task of dayObj.tasks) {
                if (!task.skill || !task.module) return null;
            }
        }

        return parsed;
    } catch {
        return null;
    }
}

/**
 * Builds a map of { module_name_lowercase → { module_icon, course_name } }
 * from the real API data so we can enrich the LLM's output with actual icons.
 */
function buildIconMap(accuracy) {
    const iconMap = {};
    const skillKeys = ['listening', 'speaking', 'reading', 'writing'];
    for (const key of skillKeys) {
        const records = accuracy?.modules?.[key]?.records || [];
        for (const r of records) {
            const name = (r.module_name || r.moduleName || '').toLowerCase();
            if (name) {
                iconMap[name] = {
                    module_icon: r.module_icon || r.moduleIcon || '',
                    course_name: r.course_name || r.courseName || '',
                };
            }
        }
    }
    return iconMap;
}

/**
 * Injects module_icon and course_name into every task produced by the LLM,
 * matching by lower-cased module name. Falls back to empty string if not found.
 */
function enrichLLMPath(path, iconMap) {
    return path.map(dayObj => ({
        ...dayObj,
        tasks: dayObj.tasks.map(task => ({
            ...task,
            difficulty: task.difficulty || 'easy',
            count:      task.count      || 2,
            module_icon: (iconMap[(task.module || '').toLowerCase()] || {}).module_icon || '',
            course_name: (iconMap[(task.module || '').toLowerCase()] || {}).course_name || '',
        })),
    }));
}

/**
 * Calls one OpenRouter model with one API key.
 * Throws an error with err.isRateLimit = true on HTTP 429.
 */
async function callOpenRouter(prompt, apiKey, model) {
    const controller = new AbortController();
    const timeout    = setTimeout(() => controller.abort(), 45000); // 45-second hard timeout

    try {
        const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
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
                        content: 'You are an expert English language coach. Return ONLY valid raw JSON arrays. No markdown, no code fences, no explanation.',
                    },
                    { role: 'user', content: prompt },
                ],
                max_tokens:  6000,
                temperature: 0.3,
            }),
            signal: controller.signal,
        });

        if (response.status === 429) {
            const err = new Error(`Rate limited on model ${model}`);
            err.isRateLimit = true;
            throw err;
        }

        if (!response.ok) {
            const body = await response.text();
            throw new Error(`OpenRouter HTTP ${response.status}: ${body.slice(0, 200)}`);
        }

        const data = await response.json();
        return data.choices?.[0]?.message?.content || null;

    } finally {
        clearTimeout(timeout);
    }
}

/**
 * Main LLM orchestrator — multi-key × multi-model fallback chain.
 *
 * Flow:
 *   For each API key in OPENROUTER_KEYS:
 *     For each model in OPENROUTER_FREE_MODELS:
 *       1. Call OpenRouter
 *       2. Parse & validate response
 *       3. If valid → enrich with real icons → return
 *       4. If rate-limited / invalid → try next model
 *   If ALL combinations fail → return null (triggers algorithm fallback)
 */
async function generateWithLLMFallback(accuracy) {
    const rawKeys = (process.env.OPENROUTER_KEYS || '').split(',').map(k => k.trim()).filter(Boolean);

    if (rawKeys.length === 0) {
        console.log('[LLM] No OPENROUTER_KEYS configured — skipping LLM, using algorithm.');
        return null;
    }

    const models   = process.env.OPENROUTER_MODELS
        ? process.env.OPENROUTER_MODELS.split(',').map(m => m.trim()).filter(Boolean)
        : DEFAULT_OPENROUTER_MODELS;

    const prompt  = buildLLMPrompt(accuracy);
    const iconMap = buildIconMap(accuracy);

    for (const key of rawKeys) {
        const keyLabel = `***${key.slice(-6)}`;  // never log the full key

        for (const model of models) {
            try {
                console.log(`[LLM] Trying model "${model}" (key ${keyLabel})`);

                const rawText = await callOpenRouter(prompt, key, model);

                if (!rawText) {
                    console.warn(`[LLM] Empty response from "${model}", trying next model.`);
                    continue;
                }

                const parsed = parseAndValidateLLMPath(rawText);

                if (parsed) {
                    console.log(`[LLM] ✅ Valid ${parsed.length}-day path from "${model}" (key ${keyLabel})`);
                    const enriched = enrichLLMPath(parsed, iconMap);
                    return { path: enriched, model, source: 'llm' };
                }

                console.warn(`[LLM] "${model}" returned invalid/incomplete JSON, trying next model.`);

            } catch (err) {
                if (err.isRateLimit) {
                    console.warn(`[LLM] Rate limit hit on "${model}" (key ${keyLabel}), trying next.`);
                    continue;
                }
                if (err.name === 'AbortError') {
                    console.warn(`[LLM] Timeout on "${model}" (key ${keyLabel}), trying next.`);
                    continue;
                }
                console.warn(`[LLM] Error from "${model}": ${err.message}`);
            }
        }

        console.log(`[LLM] All models exhausted for key ${keyLabel}. Trying next key.`);
    }

    console.log('[LLM] All keys and models exhausted. Falling back to deterministic algorithm.');
    return null;
}

// ═════════════════════════════════════════════════════════════════════════════
//  SECTION B — DETERMINISTIC ALGORITHM (guaranteed fallback, no external calls)
// ═════════════════════════════════════════════════════════════════════════════
//
//  LAYER 1  Skill-level tier (overall % per L/S/R/W):
//    Critical  < 40%  → priority ×5  "Emergency Focus"
//    Weak     40-60%  → priority ×4  "Intensive Practice"
//    Moderate 60-75%  → priority ×3  "Skill Building"
//    Good     75-90%  → priority ×2  "Refinement"
//    Strong   ≥ 90%   → priority ×1  "Mastery Review"
//
//  LAYER 2  Module-level score:
//    score = (100 - pct) × 0.6 + count_bonus + complexity_bonus
//    Modules < 50% are doubled in the pool for extra repetition.
//
//  LAYER 3  Phase-aware scheduling:
//    easy → Phase 1 (Foundation), medium → Phase 2 (Practice), hard → Phase 3 (Mastery)
//
//  LAYER 4  Smart focus labels per tier
// ─────────────────────────────────────────────────────────────────────────────
function generateSmartPath(accuracy) {
    const SKILL_LABELS = { listening: 'Listening', speaking: 'Speaking', reading: 'Reading', writing: 'Writing' };
    const ALL_SKILLS   = ['Listening', 'Speaking', 'Reading', 'Writing'];

    function classifySkill(pct) {
        if (pct < 40) return { priority: 5, verb: 'Emergency Focus'    };
        if (pct < 60) return { priority: 4, verb: 'Intensive Practice'  };
        if (pct < 75) return { priority: 3, verb: 'Skill Building'      };
        if (pct < 90) return { priority: 2, verb: 'Refinement'          };
        return             { priority: 1, verb: 'Mastery Review'       };
    }

    function calcModuleScore(pct, count, complexity) {
        let score = (100 - pct) * 0.6;
        if (count === 0)    score += 30;
        else if (count < 3) score += 15;
        else if (count < 7) score += 5;
        if (complexity === 'easy') score += 5;
        if (complexity === 'hard') score -= 5;
        return score;
    }

    function preferredPhase(complexity) {
        if (complexity === 'hard')   return 3;
        if (complexity === 'medium') return 2;
        return 1;
    }

    // Build and score module pools from API data
    const modulePool = {};
    for (const [key, label] of Object.entries(SKILL_LABELS)) {
        const skillData = accuracy?.modules?.[key];
        let records = [];
        if (skillData?.records?.length > 0) {
            records = skillData.records.map(r => {
                const pct = parseFloat(r.percentage) || 0;
                const cnt = r.count || 0;
                const cpx = r.complexity || 'easy';
                return {
                    module_name: r.module_name || r.moduleName || '',
                    module_icon: r.module_icon || r.moduleIcon || '',
                    complexity:  cpx,
                    percentage:  pct,
                    count:       cnt,
                    course_name: r.course_name || r.courseName || '',
                    _score:      calcModuleScore(pct, cnt, cpx),
                    _phase:      preferredPhase(cpx),
                };
            });
            records.sort((a, b) => b._score - a._score);
            const urgent = records.filter(r => r.percentage < 50);
            records = [...urgent, ...records];  // double-up urgent modules
        } else {
            records = FALLBACK_MODULES[label].map((name, i) => ({
                module_name: name, module_icon: '', complexity: 'easy',
                percentage: 0, count: 0, course_name: '',
                _score: 100 - i * 5, _phase: 1,
            }));
        }
        modulePool[label] = records;
    }

    const skillAccuracy = {
        Listening: parseFloat(accuracy?.listening) || 50,
        Speaking:  parseFloat(accuracy?.speaking)  || 50,
        Reading:   parseFloat(accuracy?.reading)   || 50,
        Writing:   parseFloat(accuracy?.writing)   || 50,
    };

    const skillInfo = {};
    for (const s of ALL_SKILLS) skillInfo[s] = classifySkill(skillAccuracy[s]);

    const weightedPool = [];
    for (const s of ALL_SKILLS)
        for (let i = 0; i < skillInfo[s].priority; i++) weightedPool.push(s);

    const skillsByPriority = [...ALL_SKILLS].sort((a, b) => skillInfo[b].priority - skillInfo[a].priority);

    const buckets = {};
    const cursor  = {};
    for (const s of ALL_SKILLS) {
        buckets[s] = { 1: [], 2: [], 3: [] };
        cursor[s]  = { 1: 0,  2: 0,  3: 0  };
        for (const mod of modulePool[s]) buckets[s][mod._phase].push(mod);
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

    const PHASE_DEFS = [
        { range: [1,  10], phaseNum: 1, difficulty: 'easy',   taskCount: 3, count: 2 },
        { range: [11, 20], phaseNum: 2, difficulty: 'medium', taskCount: 4, count: 3 },
        { range: [21, 30], phaseNum: 3, difficulty: 'hard',   taskCount: 5, count: 4 },
    ];

    const path = [];
    for (let day = 1; day <= 30; day++) {
        const phase        = PHASE_DEFS.find(p => day >= p.range[0] && day <= p.range[1]);
        const primarySkill = weightedPool[(day - 1) % weightedPool.length];
        const otherSkills  = skillsByPriority.filter(s => s !== primarySkill);
        const todaySkills  = [primarySkill, ...otherSkills].slice(0, phase.taskCount);

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

        const focus = `${primarySkill}: ${skillInfo[primarySkill].verb} — Day ${day}`;
        path.push({ day, focus, tasks });
    }

    return path;
}

// ═════════════════════════════════════════════════════════════════════════════
//  ROUTES
// ═════════════════════════════════════════════════════════════════════════════

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

        if (!user_id) return res.status(400).json({ error: 'user_id is required.' });

        const existing = await LearningPath.findOne({ user_id, status: 'active' });
        if (existing) return res.status(400).json({ error: 'Active path already exists.' });

        // ── Step 1: Try LLM (multi-key × multi-model fallback chain) ────────
        const llmResult = await generateWithLLMFallback(accuracy || {});

        // ── Step 2: Use LLM result or fall back to deterministic algorithm ──
        let generatedPath, pathSource;

        if (llmResult) {
            generatedPath = llmResult.path;
            pathSource    = `llm:${llmResult.model}`;
            console.log(`[PathGen] Using LLM path from "${llmResult.model}" for user: ${user_id}`);
        } else {
            generatedPath = generateSmartPath(accuracy || {});
            pathSource    = 'algorithm';
            console.log(`[PathGen] Using algorithm path for user: ${user_id}`);
        }

        // ── Step 3: Save to MongoDB ──────────────────────────────────────────
        const doc = new LearningPath({
            user_id,
            start_date:   new Date().toISOString().split('T')[0],
            status:       'active',
            path_source:  pathSource,
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
        console.log(`[PathGen] Path saved (source: ${pathSource}) for user: ${user_id}`);
        res.json(saved);

    } catch (error) {
        console.error('[PathGen] Fatal error:', error.message);
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
