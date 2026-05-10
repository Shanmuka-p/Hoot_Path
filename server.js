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

// ─── Smart Path Generator (uses real API module data) ─────────────────────────

// Fallback module names — only used if no real API data is provided
const FALLBACK_MODULES = {
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

/**
 * Extract real module records from the API data sent by the client.
 * Returns a map like { Listening: [{module_name, module_icon, complexity, ...}], ... }
 */
function extractModuleData(accuracy) {
    const modules = accuracy?.modules || {};
    const result = {};
    const skillMap = { listening: 'Listening', speaking: 'Speaking', reading: 'Reading', writing: 'Writing' };

    for (const [key, capitalized] of Object.entries(skillMap)) {
        const skillData = modules[key];
        if (skillData && skillData.records && Array.isArray(skillData.records) && skillData.records.length > 0) {
            result[capitalized] = skillData.records.map(r => ({
                module_name:  r.module_name || r.moduleName || '',
                module_icon:  r.module_icon || r.moduleIcon || '',
                complexity:   r.complexity || 'easy',
                percentage:   parseFloat(r.percentage) || 0,
                count:        r.count || 0,
                course_name:  r.course_name || r.courseName || '',
            }));
        } else {
            // Fallback: build records from fallback names
            result[capitalized] = FALLBACK_MODULES[capitalized].map(name => ({
                module_name: name,
                module_icon: '',
                complexity: 'easy',
                percentage: 0,
                count: 0,
                course_name: '',
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

/**
 * Generates a personalized 30-day learning path based on accuracy data.
 * Uses REAL module names from the API data (accuracy.modules).
 * - Weak skills (<60%) → prioritized, more daily tasks
 * - Medium skills (60-80%) → moderate focus
 * - Strong skills (>80%) → maintenance only
 */
function generateSmartPath(accuracy) {
    const skills = ['Listening', 'Speaking', 'Reading', 'Writing'];
    const skillKeys = ['listening', 'speaking', 'reading', 'writing'];

    // Extract real module records from API data
    const moduleRecords = extractModuleData(accuracy);

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

        // Build tasks using real module data from the API
        const tasks = todaySkills.slice(0, taskCount).map((skill, idx) => {
            const record = pickModuleRecord(moduleRecords, skill, day + idx);
            return {
                skill,
                module: record.module_name,
                module_icon: record.module_icon,
                complexity: record.complexity,
                course_name: record.course_name,
                count,
                difficulty,
            };
        });

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

        // 1. Construct the prompt for Ollama
        const prompt = `
        You are an AI language mentor. Generate a 30-day learning path based on this student's accuracy data:
        Listening: ${accuracy?.listening || 0}%
        Speaking: ${accuracy?.speaking || 0}%
        Reading: ${accuracy?.reading || 0}%
        Writing: ${accuracy?.writing || 0}%

        Focus heavily on their weakest skills.
        You MUST return ONLY valid JSON. The JSON must be an array of 30 objects.
        Do not include any markdown formatting, backticks, or explanation. Just the raw JSON array.
        
        Exact structure required:
        [
          {
            "day": 1,
            "focus": "Listening Foundation",
            "tasks": [
               { "skill": "Listening", "module": "Audio Comprehension", "difficulty": "easy", "count": 2 }
            ]
          }
        ]
        `;

        // 2. Call the Ollama API using an environment variable for the base URL
        let ollamaBaseUrl = process.env.OLLAMA_BASE_URL || 'http://localhost:11434';
        if (ollamaBaseUrl.endsWith('/')) {
            ollamaBaseUrl = ollamaBaseUrl.slice(0, -1);
        }
        
        console.log(`Calling Ollama at ${ollamaBaseUrl} to generate path...`);
        
        const response = await fetch(`${ollamaBaseUrl}/api/generate`, {
            method: 'POST',
            headers: { 
                'Content-Type': 'application/json',
                'ngrok-skip-browser-warning': 'true'
            },
            body: JSON.stringify({
                model: 'llama3.2:1b', 
                prompt: prompt,
                stream: false,   
                format: 'json'   
            })
        });

        if (!response.ok) {
             const errText = await response.text();
             throw new Error(`Ollama failed with status: ${response.status}, message: ${errText}`);
        }

        const data = await response.json();
        
        // 3. Parse the JSON returned by Ollama
        let generatedPath;
        try {
            generatedPath = JSON.parse(data.response);
        } catch (parseError) {
             console.error("Failed to parse Ollama response as JSON:", data.response);
             throw new Error("AI returned invalid JSON");
        }

        // 4. Save to MongoDB
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
        console.log(`Successfully generated path with Ollama for user: ${user_id}`);
        res.json(savedDoc);

    } catch (error) {
        console.error('Generate path error:', error.message);
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));