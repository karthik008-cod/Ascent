const mongoose = require('mongoose');

const userStatsSchema = new mongoose.Schema({
  userId: { type: String, ref: 'User', required: true, unique: true },
  totalXp: { type: Number, default: 0 },
  currentLevel: { type: Number, default: 1 },
  currentStreak: { type: Number, default: 0 },
  longestStreak: { type: Number, default: 0 },
  lastActiveDate: { type: Date },
  updatedAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('UserStats', userStatsSchema);
