const express = require('express');
const router = express.Router();
const Mission = require('../models/Mission');
const Project = require('../models/Project');
const UserStats = require('../models/UserStats');

router.post('/backup', async (req, res) => {
  console.log('[SYNC] Starting backup process...');
  try {
    const { userId, missions, stats, projects } = req.body;
    console.log(`[SYNC] Received backup request for userId: ${userId}`);

    // Backup Stats
    if (stats) {
      console.log(`[SYNC] Updating stats for userId: ${userId}`);
      await UserStats.findOneAndUpdate(
        { userId },
        { ...stats, userId, updatedAt: new Date() },
        { upsert: true, new: true }
      );
    }

    // Backup Missions
    if (missions) {
      console.log(`[SYNC] Updating ${missions.length} missions for userId: ${userId}`);
      await Mission.deleteMany({ userId });
      if (missions.length > 0) {
        const missionsToInsert = missions.map(m => ({ ...m, userId }));
        await Mission.insertMany(missionsToInsert);
      }
    }

    // Backup Projects
    if (projects) {
      console.log(`[SYNC] Updating ${projects.length} projects for userId: ${userId}`);
      await Project.deleteMany({ userId });
      if (projects.length > 0) {
        const projectsToInsert = projects.map(p => ({ ...p, userId }));
        await Project.insertMany(projectsToInsert);
      }
    }

    console.log('[SYNC] Backup process completed successfully.');
    res.json({ success: true });
  } catch (err) {
    console.error('[SYNC] Backup process failed:', err.message);
    res.status(500).json({ error: err.message });
  }
});

router.get('/restore/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const stats = await UserStats.findOne({ userId });
    const missions = await Mission.find({ userId });
    const projects = await Project.find({ userId });

    res.json({
      stats,
      missions,
      projects
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
