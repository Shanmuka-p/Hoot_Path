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
//    score = (100 - pct) × 0.6              weak accuracy → high urgency
//          + 30  if count === 0             never attempted → critical slot
//          + 15  if count <  3              barely touched
//          + 5   if count <  7             some exposure
//          + 5   if complexity === 'easy'  easy first
//          - 5   if complexity === 'hard'  hard deferred
//    Modules with percentage < 50 are doubled in the pool for extra repetition.
//
//  LAYER 3  Phase-aware scheduling:
//    Modules are bucketed by complexity into 3 learning phases:
//      easy   → Phase 1  Foundation  days  1-10
//      medium → Phase 2  Practice    days 11-20
//      hard   → Phase 3  Mastery     days 21-30
//    Each phase × skill pair has its own independent rotation cursor.
//
//  LAYER 4  Smart focus labels:
//    Day focus reflects the actual skill tier, e.g.
//    "Speaking: Emergency Focus — Day 3" instead of a generic label.
// ─────────────────────────────────────────────────────────────────────────────

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

// ── Layer 1: skill classification ────────────────────────────────────────────
function classifySkill(pct) {
    if (pct < 40) return { tier: 'Critical',  priority: 5, verb: 'Emergency Focus'   };
    if (pct < 60) return { tier: 'Weak',      priority: 4, verb: 'Intensive Practice' };
    if (pct < 75) return { tier: 'Moderate',  priority: 3, verb: 'Skill Building'    };
    if (pct < 90) return { tier: 'Good',      priority: 2, verb: 'Refinement'        };
    return             { tier: 'Strong',     priority: 1, verb: 'Mastery Review'    };
}

// ── Layer 2: module priority score ───────────────────────────────────────────
function calcModuleScore(pct, count, complexity) {
    let score = (100 - pct) * 0.6;
    if (count === 0)      score += 30;
    else if (count < 3)   score += 15;
    else if (count < 7)   score += 5;
    if (complexity === 'easy')   score += 5;
    if (complexity === 'hard')   score -= 5;
    return score;
}

// ── Layer 3: preferred phase by module complexity ─────────────────────────────
function preferredPhase(complexity) {
    if (complexity === 'hard')   return 3;
    if (complexity === 'medium') return 2;
    return 1;
}

/**
 * Main export — builds a fully personalized 30-day learning path.
 * @param {object} accuracy  The payload sent by the Flutter client:
 *   { listening, speaking, reading, writing, modules: { listening: {records:[...]}, ... } }
 * @returns {Array}  Array of 30 day objects.
 */
function generateSmartPath(accuracy) {
    const SKILL_LABELS = { listening: 'Listening', speaking: 'Speaking',
                           reading: 'Reading',    writing:  'Writing' };
    const ALL_SKILLS   = ['Listening', 'Speaking', 'Reading', 'Writing'];

    // ── Step 1: Parse & score modules from real API data ─────────────────────
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
                    sub_modules: r.sub_modules  || r.subModules  || [],
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

    // ── Step 2: Classify skills & build weighted scheduling pool ─────────────
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

    // ── Step 3: Bucket modules per skill × phase, each with its own cursor ───
    const buckets = {};
    const cursor  = {};
    for (const s of ALL_SKILLS) {
        buckets[s] = { 1: [], 2: [], 3: [] };
        cursor[s]  = { 1: 0, 2: 0, 3: 0 };
        for (const mod of modulePool[s]) buckets[s][mod._phase].push(mod);
        // Fill any empty phase bucket with all modules as fallback
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

    // ── Step 4: Build 30 days ─────────────────────────────────────────────────
    const PHASE_DEFS = [
        { range: [1,  10], phaseNum: 1, difficulty: 'easy',   taskCount: 3, count: 2 },
        { range: [11, 20], phaseNum: 2, difficulty: 'medium', taskCount: 4, count: 3 },
        { range: [21, 30], phaseNum: 3, difficulty: 'hard',   taskCount: 5, count: 4 },
    ];

    const path = [];

    for (let day = 1; day <= 30; day++) {
        const phase        = PHASE_DEFS.find(p => day >= p.range[0] && day <= p.range[1]);
        const primarySkill = weightedPool[(day - 1) % weightedPool.length];

        // All tasks for the day must belong to the primarySkill to match the focus heading
        const todaySkills = Array(phase.taskCount).fill(primarySkill);

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
                sub_modules: mod.sub_modules || [],
            };
        });

        // Layer 4: smart label reflects the actual skill tier condition
        const focus = `${primarySkill}: ${skillInfo[primarySkill].verb} — Level ${day}`;
        path.push({ day, focus, tasks });
    }

    return path;
}

module.exports = { generateSmartPath };
