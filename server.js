require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const { GoogleGenerativeAI } = require('@google/generative-ai');
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

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

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

        const prompt = `Student accuracy data: ${JSON.stringify(accuracy)}. Generate a 30-day personalized learning path. Rules: 3-5 tasks per day. Weak skills (<60%) get 40% focus. Strong skills (>80%) get 10% maintenance. Difficulty scales up days 1-30. Return ONLY a valid JSON array named 'path' with no markdown blocks.`;

        const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });
        const result = await model.generateContent(prompt);
        let responseText = result.response.text().trim();

        // Strip any markdown code fences Gemini wraps around the JSON
        responseText = responseText.replace(/^```(?:json)?\s*/i, '').replace(/\s*```$/i, '').trim();

        let generatedData;
        try {
            generatedData = JSON.parse(responseText);
        } catch (parseError) {
            return res.status(500).json({ error: "Failed to parse JSON response from Gemini" });
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
        res.status(500).json({ error: error.message });
    }
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));