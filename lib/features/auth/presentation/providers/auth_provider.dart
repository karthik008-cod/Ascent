import 'dart:convert';
import 'dart:math' as _math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/email_service.dart';
import '../../../tasks/presentation/providers/data_providers.dart';
import '../../../tasks/data/models/mission.dart';
import '../../../tasks/data/models/project.dart';
import '../../../progress/data/models/user_stats.dart';

class AuthUser {
  final String id;
  final String email;
  final String name;
  final String bio;
  final String role;
  final String socialHandle;
  final String motto;

  AuthUser({
    required this.id,
    required this.email,
    required this.name,
    this.bio = 'Leveling up daily in tech, habits & productivity.',
    this.role = 'Ascent Pioneer',
    this.socialHandle = '@yuvaan_dev',
    this.motto = '1% better every single day.',
  });

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '1',
      email: map['email'] ?? '',
      name: map['name'] ?? 'Yuvaan',
      bio: map['bio'] ?? 'Leveling up daily in tech, habits & productivity.',
      role: map['role'] ?? 'Ascent Pioneer',
      socialHandle: map['socialHandle'] ?? '@yuvaan_dev',
      motto: map['motto'] ?? '1% better every single day.',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'bio': bio,
      'role': role,
      'socialHandle': socialHandle,
      'motto': motto,
    };
  }

  AuthUser copyWith({
    String? name,
    String? bio,
    String? role,
    String? socialHandle,
    String? motto,
  }) {
    return AuthUser(
      id: id,
      email: email,
      name: name ?? this.name,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      socialHandle: socialHandle ?? this.socialHandle,
      motto: motto ?? this.motto,
    );
  }
}

class AuthNotifier extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthNotifier(this.ref) : super(const AsyncValue.loading()) {
    _checkLoginStatus();
  }

  final Ref ref;
  static const String _userKey = 'logged_in_user';
  static const String _savedUsersKey = 'saved_users_history';

  Future<void> _saveUserToHistory(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsersJson = prefs.getString(_savedUsersKey);
    List<Map<String, dynamic>> savedUsers = [];
    if (savedUsersJson != null) {
      final List<dynamic> decoded = jsonDecode(savedUsersJson);
      savedUsers = decoded.cast<Map<String, dynamic>>();
    }
    // Remove if exists to move to top
    savedUsers.removeWhere((u) => u['email'] == user.email);
    // Add to top
    savedUsers.insert(0, user.toMap());
    await prefs.setString(_savedUsersKey, jsonEncode(savedUsers));
  }

  Future<List<AuthUser>> getSavedUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsersJson = prefs.getString(_savedUsersKey);
    if (savedUsersJson == null) return [];
    final List<dynamic> decoded = jsonDecode(savedUsersJson);
    final list = decoded.cast<Map<String, dynamic>>();
    return list.map((m) => AuthUser.fromMap(m)).toList();
  }

  // --- Backup current user's local data to MongoDB ---
  Future<void> _backupCurrentUser() async {
    final currentUser = state.valueOrNull;
    if (currentUser == null || currentUser.id == 'local_user') return;
    
    try {
      final isar = ref.read(localIsarProvider);
      final mongo = ref.read(mongoDataSourceProvider);
      final missions = await isar.getAllMissions();
      final stats = await isar.getUserStats();
      final projects = await isar.getAllProjects();
      await mongo.backupData(currentUser.id, missions, stats, projects);
    } catch (e) {
      print('Backup before switch failed: $e');
    }
  }

  // --- Restore a user's data from MongoDB into local Isar ---
  Future<void> _restoreUserData(String userId) async {
    final isar = ref.read(localIsarProvider);
    final mongo = ref.read(mongoDataSourceProvider);
    
    // Clear all local data first
    await isar.clearAllData();
    
    try {
      final data = await mongo.restoreData(userId);
      
      // Restore stats
      final statsDoc = data['stats'] as Map<String, dynamic>?;
      if (statsDoc != null) {
        final stats = UserStats()
          ..totalXp = statsDoc['totalXp'] ?? 0
          ..currentLevel = statsDoc['currentLevel'] ?? 1
          ..currentStreak = statsDoc['currentStreak'] ?? 0
          ..longestStreak = statsDoc['longestStreak'] ?? 0
          ..lastActiveDate = statsDoc['lastActiveDate'] != null 
              ? DateTime.tryParse(statsDoc['lastActiveDate']) 
              : null;
        await isar.importStats(stats);
      }
      
      // Restore missions
      final missionDocs = data['missions'] as List<Map<String, dynamic>>? ?? [];
      if (missionDocs.isNotEmpty) {
        final missions = missionDocs.map((doc) {
          final m = Mission()
            ..title = doc['title'] ?? ''
            ..description = doc['description']
            ..type = MissionType.values[doc['type'] ?? 0]
            ..xpReward = doc['xpReward'] ?? 0
            ..isCompleted = doc['isCompleted'] ?? false
            ..date = DateTime.tryParse(doc['date'] ?? '') ?? DateTime.now()
            ..projectId = doc['projectId'];
          return m;
        }).toList();
        await isar.importMissions(missions);
      }
      
      // Restore projects
      final projectDocs = data['projects'] as List<Map<String, dynamic>>? ?? [];
      if (projectDocs.isNotEmpty) {
        final projects = projectDocs.map((doc) {
          final p = Project()
            ..title = doc['title'] ?? ''
            ..description = doc['description']
            ..notes = doc['notes']
            ..progress = (doc['progress'] ?? 0.0).toDouble()
            ..createdAt = DateTime.tryParse(doc['createdAt'] ?? '') ?? DateTime.now();
          return p;
        }).toList();
        await isar.importProjects(projects);
      }
    } catch (e) {
      print('Restore from cloud failed: $e');
      // User will start with fresh data if restore fails
    }
  }

  Future<void> switchAccount(AuthUser user) async {
    // 1. Backup current user's data to MongoDB
    await _backupCurrentUser();
    
    // 2. Restore the new user's data from MongoDB
    await _restoreUserData(user.id);
    
    // 3. Update auth state
    state = AsyncValue.data(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
    await _saveUserToHistory(user);
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final map = jsonDecode(userJson);
        state = AsyncValue.data(AuthUser.fromMap(map));
      } else {
        // No user is logged in, require explicit auth
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? role,
    String? socialHandle,
    String? motto,
  }) async {
    final current = state.value ?? AuthUser(id: 'local_user', email: 'yuvaan@ascent.app', name: 'Yuvaan');
    final updatedUser = current.copyWith(
      name: name,
      bio: bio,
      role: role,
      socialHandle: socialHandle,
      motto: motto,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(updatedUser.toMap()));
    state = AsyncValue.data(updatedUser);
  }

  Future<bool> checkUserExists(String email) async {
    final mongo = ref.read(mongoDataSourceProvider);
    return await mongo.checkUserExists(email);
  }

  Future<bool> sendOtp(String email) async {
    // Generate a 6-digit random OTP
    final random = _math.Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    
    // Store temporarily in memory or shared prefs (for this demo, we can just return it or let the UI manage it, but securely we should store it and compare)
    // For simplicity without a backend session, we will store it in SharedPreferences temporarily
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temp_otp_$email', otp);
    
    // Call EmailService
    // Note: We need to import email_service.dart and dart:math at the top
    final success = await EmailService.sendOtpEmail(email, otp);
    return success;
  }
  
  Future<bool> verifyOtp(String email, String inputOtp) async {
    final prefs = await SharedPreferences.getInstance();
    final storedOtp = prefs.getString('temp_otp_$email');
    if (storedOtp != null && storedOtp == inputOtp) {
      await prefs.remove('temp_otp_$email');
      return true;
    }
    return false;
  }

  Future<void> signIn(String email, String password) async {
    try {
      // Backup current user before switching
      await _backupCurrentUser();
      
      final mongo = ref.read(mongoDataSourceProvider);
      final userData = await mongo.signIn(email, password);
      if (userData != null) {
        final user = AuthUser.fromMap(userData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toMap()));
        await _saveUserToHistory(user);
        
        // Restore this user's data from cloud
        await _restoreUserData(user.id);
        
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
        throw Exception('Sign In Failed');
      }
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> loginWithOtp(String email) async {
    try {
      // Backup current user before switching
      await _backupCurrentUser();
      
      final mongo = ref.read(mongoDataSourceProvider);
      final userData = await mongo.signInWithEmailOnly(email);
      if (userData != null) {
        final user = AuthUser.fromMap(userData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toMap()));
        await _saveUserToHistory(user);
        
        // Restore this user's data from cloud
        await _restoreUserData(user.id);
        
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
        throw Exception('OTP Sign In Failed');
      }
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    try {
      // Backup current user before switching
      await _backupCurrentUser();
      
      final mongo = ref.read(mongoDataSourceProvider);
      final userData = await mongo.signUp(email, password, name);
      if (userData != null) {
        final user = AuthUser.fromMap(userData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toMap()));
        await _saveUserToHistory(user);
        
        // Clear local data for the new user (fresh start)
        final isar = ref.read(localIsarProvider);
        await isar.clearAllData();
        
        state = AsyncValue.data(user);
      } else {
        state = const AsyncValue.data(null);
        throw Exception('Sign Up Failed');
      }
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> updatePassword(String email, String newPassword) async {
    try {
      final mongo = ref.read(mongoDataSourceProvider);
      await mongo.updatePassword(email, newPassword);
      state = const AsyncValue.data(null);
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> signOut() async {
    // Backup before signing out
    await _backupCurrentUser();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    
    // Clear local data so the next user starts fresh
    final isar = ref.read(localIsarProvider);
    await isar.clearAllData();
    
    // Explicitly sign out, forcing router to redirect to auth screen
    state = const AsyncValue.data(null);
  }

  /// Deletes the user account from MongoDB and clears all local data.
  Future<void> deleteAccount() async {
    final currentUser = state.valueOrNull;
    if (currentUser == null) return;
    
    try {
      // Delete from MongoDB
      final mongo = ref.read(mongoDataSourceProvider);
      await mongo.deleteUser(currentUser.email);
    } catch (e) {
      print('MongoDB account deletion failed: $e');
    }
    
    // Remove from saved users history
    final prefs = await SharedPreferences.getInstance();
    final savedUsersJson = prefs.getString(_savedUsersKey);
    if (savedUsersJson != null) {
      final List<dynamic> decoded = jsonDecode(savedUsersJson);
      final savedUsers = decoded.cast<Map<String, dynamic>>();
      savedUsers.removeWhere((u) => u['email'] == currentUser.email);
      await prefs.setString(_savedUsersKey, jsonEncode(savedUsers));
    }
    
    // Clear local data
    await prefs.remove(_userKey);
    final isar = ref.read(localIsarProvider);
    await isar.clearAllData();
    
    // Sign out
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>((ref) {
  return AuthNotifier(ref);
});
