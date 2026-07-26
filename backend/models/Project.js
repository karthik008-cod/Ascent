const mongoose = require('mongoose');

const projectSchema = new mongoose.Schema({
  id: { type: Number, required: true },
  userId: { type: String, ref: 'User', required: true },
  title: { type: String, required: true },
  description: { type: String },
  notes: { type: String },
  progress: { type: Number, default: 0.0 },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Project', projectSchema);
