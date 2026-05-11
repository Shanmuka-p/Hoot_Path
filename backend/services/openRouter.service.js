// ─── services/openRouter.service.js ──────────────────────────────────────────
//  Service layer — all OpenRouter LLM interaction, prompt building,
//  response parsing, enrichment, and the algorithm safety-net fallback.
//  No HTTP request/response objects here; purely business logic.
// ─────────────────────────────────────────────────────────────────────────────

// ─── OpenRouter Free Models (priority order — most reliable first) ────────────
const DEFAULT_MODELS = [
    'meta-llama/llama-3.1-8b-instruct:free',
    'mistralai/mistral-7b-instruct:free',
    'qwen/qwen-2-7b-instruct:free',
    'google/gemma-2-9b-it:free',
    'nousresearch/hermes-3-llama-3.1-8b:free',
    'deepseek/deepseek-r1-distill-qwen-14b:free',
    'microsoft/phi-3-mini-128k-instruct:free',
];

// ─────────────────────────────────────────────────────────────────────────────
//  HELPERS — Extract real API module data
// ─────────────────────────────────────────────────────────────────────────────

// Normalise a module name for comparison: lowercase + collapse whitespace
const normName = str => (str || '').toLowerCase().replace(/\s+/g, ' ').trim();

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
                sub_modules: r.sub_modules || r.subModules || [],
            }))
            .filter(r => r.module_name.trim() !== '');
    }
    return out;
}

/** Icon lookup map: normalised module name → { module_icon, course_name } */
function buildIconMap(modules) {
    const map = {};
    for (const list of Object.values(modules)) {
        for (const m of list) {
            map[normName(m.module_name)] = {
                module_icon: m.module_icon,
                course_name: m.course_name,
                sub_modules: m.sub_modules,
            };
        }
    }
    return map;
}

/** Set of all valid normalised module names for validation. */
function buildValidNameSet(modules) {
    const set = new Set();
    for (const list of Object.values(modules)) {
        for (const m of list) set.add(normName(m.module_name));
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

    return `You are an expert English language AI mentor. Analyze the student's real performance data and generate a personalized 30-level learning path.

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
4. The "focus" for each day MUST be for exactly ONE skill (e.g., "Listening: Emergency Focus — Day 1"), and EVERY task in that day MUST strictly belong to that same skill. Do not mix skills in a single day.
5. Modules with lower accuracy must appear more often across the 30 days.
6. Modules with 0 attempts must be introduced in Levels 1-10.
7. Never repeat the same module on back-to-back Levels.
8. STRICT: Use ONLY the exact module names from the lists above. DO NOT invent names.

Return ONLY a valid JSON array of exactly 30 objects. No markdown, no explanation.
[{"session":1,"focus":"Listening: Emergency Focus — Levels 1","tasks":[{"skill":"Listening","module":"<exact name>","difficulty":"easy","count":2},...]}]`;
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
                // Reject only if module is truly unknown (normalised comparison)
                if (validNames.size > 0 && !validNames.has(normName(task.module))) {
                    console.warn(`[LLM] Unknown module: "${task.module}" — trying next model.`);
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
            module_icon: (iconMap[normName(task.module)] || {}).module_icon || '',
            course_name: (iconMap[normName(task.module)] || {}).course_name || '',
            sub_modules: (iconMap[normName(task.module)] || {}).sub_modules || [],
        })),
    }));
}

// ─────────────────────────────────────────────────────────────────────────────
//  ALGORITHM SAFETY NET — Uses ONLY real API modules, no invented names.
//  Runs only when every LLM key+model combination has failed.
// ─────────────────────────────────────────────────────────────────────────────
function buildAlgorithmPath(accuracy, modules) {
    const ALL_SKILLS = ['Listening', 'Speaking', 'Reading', 'Writing'];
    const keyMap     = { Listening: 'listening', Speaking: 'speaking', Reading: 'reading', Writing: 'writing' };

    function classify(pct) {
        if (pct < 40) return { priority: 5, verb: 'Emergency Focus'    };
        if (pct < 60) return { priority: 4, verb: 'Intensive Practice'  };
        if (pct < 75) return { priority: 3, verb: 'Skill Building'      };
        if (pct < 90) return { priority: 2, verb: 'Refinement'          };
        return             { priority: 1, verb: 'Mastery Review'       };
    }

    const pct  = { Listening: parseFloat(accuracy?.listening)||50, Speaking: parseFloat(accuracy?.speaking)||50, Reading: parseFloat(accuracy?.reading)||50, Writing: parseFloat(accuracy?.writing)||50 };
    const info = {};
    for (const s of ALL_SKILLS) info[s] = classify(pct[s]);

    // Build module pools from real API data only
    const pool = {};
    for (const s of ALL_SKILLS) {
        const key  = keyMap[s];
        let recs   = modules[key] || [];
        if (recs.length === 0) {
            // No data for this skill at all — create one placeholder from API
            recs = [{ module_name: s + ' Practice', module_icon: '', course_name: '', complexity: 'easy', percentage: 0, count: 0, sub_modules: [] }];
        }
        pool[s] = [...recs].sort((a, b) => a.percentage - b.percentage);
    }

    const weighted = [];
    for (const s of ALL_SKILLS)
        for (let i = 0; i < info[s].priority; i++) weighted.push(s);

    const byPriority = [...ALL_SKILLS].sort((a, b) => info[b].priority - info[a].priority);
    const cursor = { Listening: 0, Speaking: 0, Reading: 0, Writing: 0 };
    const next = s => { const m = pool[s][cursor[s] % pool[s].length]; cursor[s]++; return m; };

    const PHASES = [
        { range:[1,10],  diff:'easy',   tasks:3, count:2 },
        { range:[11,20], diff:'medium', tasks:4, count:3 },
        { range:[21,30], diff:'hard',   tasks:5, count:4 },
    ];

    const path = [];
    for (let day = 1; day <= 30; day++) {
        const ph      = PHASES.find(p => day >= p.range[0] && day <= p.range[1]);
        const primary = weighted[(day-1) % weighted.length];
        const skills  = [primary, ...byPriority.filter(s => s !== primary)].slice(0, ph.tasks);
        const tasks   = skills.map(s => { const m = next(s); return { skill:s, module:m.module_name, module_icon:m.module_icon, course_name:m.course_name, complexity:m.complexity||ph.diff, count:ph.count, difficulty:ph.diff, sub_modules:m.sub_modules||[] }; });
        path.push({ day, focus:`${primary}: ${info[primary].verb} — Day ${day}`, tasks });
    }
    return path;
}

// ─────────────────────────────────────────────────────────────────────────────
//  OPENROUTER HTTP CALL
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
//  API KEY COLLECTION
// ─────────────────────────────────────────────────────────────────────────────
/**
 * Collects all OpenRouter API keys from environment variables.
 * Supports two formats (both can be used together):
 *   Format 1 — individual vars:  OPENROUTER_KEY, OPENROUTER_KEY1, OPENROUTER_KEY2, ...
 *   Format 2 — comma-separated:  OPENROUTER_KEYS=sk-or-xxx,sk-or-yyy
 */
function collectApiKeys() {
    const found = new Set();

    // Format 1: OPENROUTER_KEY (no suffix), OPENROUTER_KEY1 … OPENROUTER_KEY9
    if (process.env.OPENROUTER_KEY)  found.add(process.env.OPENROUTER_KEY.trim());
    for (let i = 1; i <= 9; i++) {
        const val = process.env[`OPENROUTER_KEY${i}`];
        if (val) found.add(val.trim());
    }

    // Format 2: OPENROUTER_KEYS=key1,key2,...
    (process.env.OPENROUTER_KEYS || '')
        .split(',').map(k => k.trim()).filter(Boolean)
        .forEach(k => found.add(k));

    return [...found];
}

// ─────────────────────────────────────────────────────────────────────────────
//  FALLBACK CHAIN — key 1 × all models → key 2 × all models → ... → algorithm
// ─────────────────────────────────────────────────────────────────────────────
/**
 * Tries every (key × model) combination in order.
 * On rate-limit or invalid response: automatically tries the next combination.
 * Returns { path, model } on success; falls back to algorithm if all fail.
 */
async function generateWithFallback(accuracy) {
    const keys = collectApiKeys();

    if (keys.length === 0) {
        throw new Error('No OpenRouter keys configured. Add OPENROUTER_KEY or OPENROUTER_KEY1 in Render Dashboard → Environment.');
    }

    const models = process.env.OPENROUTER_MODELS
        ? process.env.OPENROUTER_MODELS.split(',').map(m => m.trim()).filter(Boolean)
        : DEFAULT_MODELS;

    // Extract real API modules once for prompt + validation
    const modules    = extractModules(accuracy);
    const iconMap    = buildIconMap(modules);
    const validNames = buildValidNameSet(modules);
    const prompt     = buildPrompt(accuracy, modules);

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

    // ── Safety net: all LLMs failed — build a path from real API data ──────
    console.warn('[LLM] All keys/models failed. Using API-data algorithm as safety net.');
    const safetyPath = buildAlgorithmPath(accuracy, modules);
    return { path: safetyPath, model: 'algorithm-fallback' };
}

module.exports = { generateWithFallback };
module.exports = { generateWithFallback };
