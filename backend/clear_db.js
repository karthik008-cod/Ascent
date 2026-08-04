const mongoose = require('mongoose');
require('dotenv').config();

const User = require('./models/User');
const Mission = require('./models/Mission');
const Project = require('./models/Project');
const UserStats = require('./models/UserStats');

async function clearDB() {
  try {
    const directUri = 'mongodb://yuvaankaarthikeyaa1206_db_user:cu5fnHcbPsbYWDKK@ac-gfrmfwn-shard-00-00.3f9wxcf.mongodb.net:27017,ac-gfrmfwn-shard-00-01.3f9wxcf.mongodb.net:27017,ac-gfrmfwn-shard-00-02.3f9wxcf.mongodb.net:27017/ascent_db?authSource=admin&replicaSet=atlas-gfrmfwn-shard-0&ssl=true';
    await mongoose.connect(directUri);
    console.log('Connected to MongoDB.');

    await User.deleteMany({});
    console.log('Cleared Users.');

    await Mission.deleteMany({});
    console.log('Cleared Missions.');

    await Project.deleteMany({});
    console.log('Cleared Projects.');

    await UserStats.deleteMany({});
    console.log('Cleared UserStats.');

    console.log('All data cleared successfully (schemas preserved).');
    process.exit(0);
  } catch (error) {
    console.error('Error clearing database:', error);
    process.exit(1);
  }
}

clearDB();
