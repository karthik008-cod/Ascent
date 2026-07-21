import 'package:mongo_dart/mongo_dart.dart';
import '../../features/tasks/data/models/mission.dart';
import '../../features/progress/data/models/user_stats.dart';

class MongoDataSource {
  static const String _connectionString = 'mongodb://yuvaankaarthikeyaa1206_db_user:aykMDB_1206@ac-gfrmfwn-shard-00-00.3f9wxcf.mongodb.net:27017,ac-gfrmfwn-shard-00-01.3f9wxcf.mongodb.net:27017,ac-gfrmfwn-shard-00-02.3f9wxcf.mongodb.net:27017/ascent_db?authSource=admin&replicaSet=atlas-co8mro-shard-0&tls=true';
  Db? _db;

  Future<void> connect() async {
    if (_db != null && _db!.state == State.OPEN) return;
    _db = await Db.create(_connectionString);
    await _db!.open();
  }

  Future<void> disconnect() async {
    if (_db != null && _db!.state == State.OPEN) {
      await _db!.close();
    }
  }

  // --- Auth ---
  Future<bool> checkUserExists(String email) async {
    await connect();
    final usersCollection = _db!.collection('users');
    final existingUser = await usersCollection.findOne({'email': email});
    return existingUser != null;
  }

  Future<Map<String, dynamic>?> signUp(String email, String password, String name) async {
    await connect();
    final usersCollection = _db!.collection('users');
    
    final existingUser = await usersCollection.findOne({'email': email});
    if (existingUser != null) {
      throw Exception('User already exists');
    }

    final userId = ObjectId().toHexString();
    final newUser = {
      '_id': userId,
      'email': email,
      'password': password, // In production, this should be hashed.
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await usersCollection.insert(newUser);
    return newUser;
  }

  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    await connect();
    final usersCollection = _db!.collection('users');
    
    final user = await usersCollection.findOne({'email': email, 'password': password});
    if (user == null) {
      throw Exception('Invalid email or password');
    }
    
    // Ensure _id is treated as a string for SharedPreferences
    final Map<String, dynamic> normalizedUser = Map<String, dynamic>.from(user);
    if (normalizedUser['_id'] is ObjectId) {
       normalizedUser['_id'] = (normalizedUser['_id'] as ObjectId).toHexString();
    }
    return normalizedUser;
  }
  
  Future<Map<String, dynamic>?> signInWithEmailOnly(String email) async {
    await connect();
    final usersCollection = _db!.collection('users');
    
    final user = await usersCollection.findOne({'email': email});
    if (user == null) {
      throw Exception('User not found');
    }
    
    final Map<String, dynamic> normalizedUser = Map<String, dynamic>.from(user);
    if (normalizedUser['_id'] is ObjectId) {
       normalizedUser['_id'] = (normalizedUser['_id'] as ObjectId).toHexString();
    }
    return normalizedUser;
  }
  
  // --- Backup (Sync) ---
  Future<void> backupData(String userId, List<Mission> missions, UserStats stats) async {
    await connect();
    
    // Backup Stats
    final statsCollection = _db!.collection('user_stats');
    await statsCollection.update(
      where.eq('userId', userId),
      {
        'userId': userId,
        'totalXp': stats.totalXp,
        'currentLevel': stats.currentLevel,
        'currentStreak': stats.currentStreak,
        'longestStreak': stats.longestStreak,
        'lastActiveDate': stats.lastActiveDate?.toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      },
      upsert: true,
    );
    
    // Backup Missions
    final missionsCollection = _db!.collection('missions');
    for (var m in missions) {
      await missionsCollection.update(
        where.eq('id', m.id).and(where.eq('userId', userId)),
        {
          'id': m.id,
          'userId': userId,
          'title': m.title,
          'description': m.description,
          'type': m.type.index,
          'xpReward': m.xpReward,
          'isCompleted': m.isCompleted,
          'date': m.date.toIso8601String(),
        },
        upsert: true,
      );
    }
  }
}
