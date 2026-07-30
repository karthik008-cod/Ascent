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
  console.log('[AUTH] Starting signup process...');
  try {
    const { email, password, name } = req.body;
    console.log(`[AUTH] Checking if user exists: ${email}`);
    let user = await User.findOne({ email });
    if (user) {
      console.warn(`[AUTH] Signup failed: User ${email} already exists`);
      return res.status(400).json({ error: 'User already exists' });
    }
    const mongoose = require('mongoose');
    const _id = new mongoose.Types.ObjectId().toHexString();
    user = new User({ _id, email, password, name });
    console.log(`[AUTH] Creating new user: ${email} with ID: ${_id}`);
    await user.save();
    console.log('[AUTH] Signup successful');
    res.json(user);
  } catch (err) {
    console.error('[AUTH] Signup error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.post('/signin', async (req, res) => {
  console.log('[AUTH] Starting signin process...');
  try {
    const { email, password } = req.body;
    console.log(`[AUTH] Searching for user: ${email}`);
    const user = await User.findOne({ email, password });
    if (!user) {
      console.warn(`[AUTH] Signin failed: Invalid credentials for ${email}`);
      return res.status(401).json({ error: 'Invalid email or password' });
    }
    console.log(`[AUTH] Signin successful for ${email}`);
    res.json(user);
  } catch (err) {
    console.error('[AUTH] Signin error:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.post('/signin-email', async (req, res) => {
  console.log('[AUTH] Starting email-only signin process...');
  try {
    const { email } = req.body;
    console.log(`[AUTH] Searching for user: ${email}`);
    const user = await User.findOne({ email });
    if (!user) {
      console.warn(`[AUTH] Email signin failed: User ${email} not found`);
      return res.status(404).json({ error: 'User not found' });
    }
    console.log(`[AUTH] Email signin successful for ${email}`);
    res.json(user);
  } catch (err) {
    console.error('[AUTH] Email signin error:', err.message);
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
