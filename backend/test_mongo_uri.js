const mongoose = require('mongoose');

const uri1 = 'mongodb+srv://yuvaankaarthikeyaa1206_db_user:cu5fnHcbPsbYWDKK@cluster0.3f9wxcf.mongodb.net/?appName=Cluster0';
const uri2 = 'mongodb://yuvaankaarthikeyaa1206_db_user:aykMDB_1206@ac-gfrmfwn-shard-00-00.3f9wxcf.mongodb.net:27017,ac-gfrmfwn-shard-00-01.3f9wxcf.mongodb.net:27017,ac-gfrmfwn-shard-00-02.3f9wxcf.mongodb.net:27017/ascent_db?authSource=admin&replicaSet=atlas-gfrmfwn-shard-0&ssl=true';
const uri3 = 'mongodb+srv://yuvaankaarthikeyaa1206_db_user:aykMDB_1206@cluster0.3f9wxcf.mongodb.net/ascent_db?appName=Cluster0';
const uri4 = 'mongodb+srv://yuvaankaarthikeyaa1206_db_user:cu5fnHcbPsbYWDKK@cluster0.3f9wxcf.mongodb.net/ascent_db?appName=Cluster0';

async function testUri(name, uri) {
  try {
    console.log(`Testing ${name}...`);
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });
    console.log(`${name} CONNECTED SUCCESSFULLY!`);
    await mongoose.disconnect();
  } catch (err) {
    console.log(`${name} FAILED:`, err.message);
  }
}

async function run() {
  await testUri('URI 1 (From .env)', uri1);
  await testUri('URI 2 (From old dart)', uri2);
  await testUri('URI 3 (Old password + srv)', uri3);
  await testUri('URI 4 (New password + srv + db)', uri4);
}

run();
