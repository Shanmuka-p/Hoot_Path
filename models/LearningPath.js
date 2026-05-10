const mongoose = require('mongoose');

const TaskSchema = new mongoose.Schema({
    skill: String,
    module: String,
    module_icon: { type: String, default: '' },
    complexity: { type: String, default: 'easy' },
    course_name: { type: String, default: '' },
    count: Number,
    difficulty: String
}, { _id: false });


const DayPlanSchema = new mongoose.Schema({
    day: Number,
    completed: { type: Boolean, default: false },
    completed_at: { type: Date, default: null },
    focus: String,
    tasks: [TaskSchema]
}, { _id: false });

const LearningPathSchema = new mongoose.Schema({
    user_id: { type: String, required: true, index: true },
    start_date: { type: String, required: true },
    status: { type: String, enum: ['active', 'completed'], default: 'active' },
    accuracy_snapshot: {
        listening: Number,
        speaking: Number,
        reading: Number,
        writing: Number
    },
    path: [DayPlanSchema]
}, { timestamps: true });

module.exports = mongoose.model('LearningPath', LearningPathSchema);