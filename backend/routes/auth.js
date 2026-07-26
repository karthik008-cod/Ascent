const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Mission = require('../models/Mission');
const Project = require('../models/Project');
const UserStats = require('../models/UserStats');

router.post('/check', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    res.json({ exists: !!user });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/signup', async (req, res) => {
  try {
    const { email, password, name } = req.body;
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ error: 'User already exists' });
    }
    const mongoose = require('mongoose');
    const _id = new mongoose.Types.ObjectId().toHexString();
    user = new User({ _id, email, password, name });
    await user.save();
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/signin', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email, password });
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/signin-email', async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(user);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.put('/password', async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    await User.updateOne({ email }, { password: newPassword });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.delete('/:email', async (req, res) => {
  try {
    const { email } = req.params;
    const user = await User.findOne({ email });
    if (user) {
      await Mission.deleteMany({ userId: user._id });
      await Project.deleteMany({ userId: user._id });
      await UserStats.deleteOne({ userId: user._id });
      await User.deleteOne({ email });
    }
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
