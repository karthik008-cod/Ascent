const mongoose = require('mongoose');

const missionSchema = new mongoose.Schema({
  id: { type: Number, required: true },
  userId: { type: String, ref: 'User', required: true },
  date: { type: Date, required: true },
  title: { type: String, required: true },
  description: { type: String },
  type: { type: Number, required: true },
  isCompleted: { type: Boolean, default: false },
  xpReward: { type: Number, default: 0 },
  projectId: { type: Number }
});

module.exports = mongoose.model('Mission', missionSchema);
