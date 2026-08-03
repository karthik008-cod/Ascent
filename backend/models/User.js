const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  _id: { type: String },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  name: { type: String, required: true },
  bio: { type: String, default: 'Leveling up daily in tech, habits & productivity.' },
  role: { type: String, default: 'Ascent Pioneer' },
  socialHandle: { type: String, default: '@ascent_user' },
  motto: { type: String, default: '1% better every single day.' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('User', userSchema);
