require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const OpenAI = require('openai');
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

// Grok is OpenAI-compatible — just point the baseURL to api.x.ai
const grok = new OpenAI({
    apiKey: process.env.GROK_API_KEY,
    baseURL: 'https://api.x.ai/v1',
});

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
        if (!activePath) {
            return res.status(404).json({ error: "No active path found" });
        }

        const dayIndex = activePath.path.findIndex(d => d.day === day);
        if (dayIndex === -1) {
            return res.status(400).json({ error: "Invalid day" });
        }

        activePath.path[dayIndex].completed = true;
        activePath.path[dayIndex].completed_at = new Date();

        const allCompleted = activePath.path.every(d => d.completed);
        let pathCompleted = false;

        if (allCompleted) {
            activePath.status = 'completed';
            pathCompleted = true;
        }

        await activePath.save();
        res.json({ success: true, path_completed: pathCompleted });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/generate-learning-path', async (req, res) => {
    try {
        const { user_id, accuracy } = req.body;

        const existingPath = await LearningPath.findOne({ user_id, status: 'active' });
        if (existingPath) {
            return res.status(400).json({ error: "Active path exists." });
        }

        const prompt = `You are a language learning expert. Generate a personalized 30-day English learning path based on this student accuracy data: ${JSON.stringify(accuracy)}.

Rules:
- 3 to 5 tasks per day
- Weak skills (below 60%) get 40% focus
- Strong skills (above 80%) get only 10% maintenance
- Difficulty increases progressively from day 1 to day 30
- Each task must have: skill (Listening/Speaking/Reading/Writing), module (task name), count (reps), difficulty (easy/medium/hard)
- Each day must have: day (number 1-30), focus (short title like "Listening Focus"), tasks (array)

Return ONLY a valid JSON object with a single key "path" containing an array of 30 day objects. No markdown, no explanation, just the JSON.`;

        const completion = await grok.chat.completions.create({
            model: 'grok-3-mini',
            messages: [
                {
                    role: 'system',
                    content: 'You are a language learning AI that returns only valid JSON.',
                },
                {
                    role: 'user',
                    content: prompt,
                },
            ],
            temperature: 0.7,
        });

        let responseText = completion.choices[0].message.content.trim();

        // Strip markdown code fences if present
        responseText = responseText.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '').trim();

        let generatedData;
        try {
            generatedData = JSON.parse(responseText);
        } catch (parseError) {
            console.error('Grok raw response:', responseText);
            return res.status(500).json({ error: "Failed to parse JSON response from Grok" });
        }

        const newPath = new LearningPath({
            user_id,
            start_date: new Date().toISOString().split('T')[0],
            status: 'active',
            accuracy_snapshot: {
                listening: accuracy.listening,
                speaking: accuracy.speaking,
                reading: accuracy.reading,
                writing: accuracy.writing
            },
            path: generatedData.path.map(dayPlan => ({
                ...dayPlan,
                completed: false,
                completed_at: null
            }))
        });

        const savedDoc = await newPath.save();
        res.json(savedDoc);
    } catch (error) {
        console.error('Generate path error:', error.message);
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));