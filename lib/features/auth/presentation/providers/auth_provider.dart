import 'dart:convert';
import 'dart:math' as _math;
import 'package:isar/isar.dart';
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
    this.role = 'Novice Explorer',
    this.socialHandle = '@new_user',
    this.motto = '1% better every single day.',
  });

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['_id']?.toString() ?? map['id']?.toString() ?? '1',
      email: map['email'] ?? '',
      name: map['name'] ?? 'Yuvaan',
      bio: map['bio'] ?? 'Leveling up daily in tech, habits & productivity.',
      role: map['role'] ?? 'Novice Explorer',
      socialHandle: map['socialHandle'] ?? '@new_user',
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
    
    final isar = ref.read(localIsarProvider);
    final mongo = ref.read(mongoDataSourceProvider);
    final missions = await isar.getAllMissions();
    final missionsToBackup = missions.where((m) => !(m.description?.contains('[TUTORIAL_TASK]') ?? false)).toList();
    final stats = await isar.getUserStats();
    final projects = await isar.getAllProjects();
    
    // We intentionally do NOT catch the error here. If backup fails, we MUST NOT switch accounts,
    // otherwise the user will permanently lose their local data!
    await mongo.backupData(currentUser.id, missionsToBackup, stats, projects);
  }

  // --- Restore a user's data from MongoDB into local Isar ---
  Future<void> _restoreUserData(String userId) async {
    final isar = ref.read(localIsarProvider);
    final mongo = ref.read(mongoDataSourceProvider);
    
    try {
      // Fetch data FIRST before wiping local DB!
      final data = await mongo.restoreData(userId);
      
      // If we got the data successfully, now we can safely clear the local DB
      await isar.clearAllData();
      
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
      final missionDocs = data['missions'] as List<dynamic>? ?? [];
      if (missionDocs.isNotEmpty) {
        final missions = missionDocs.map((doc) {
          final docMap = doc as Map<String, dynamic>;
          final m = Mission()
            ..id = docMap['id'] ?? Isar.autoIncrement
            ..title = docMap['title'] ?? ''
            ..description = docMap['description']
            ..type = MissionType.values[docMap['type'] ?? 0]
            ..xpReward = docMap['xpReward'] ?? 0
            ..isCompleted = docMap['isCompleted'] ?? false
            ..date = (DateTime.tryParse(docMap['date'] ?? '') ?? DateTime.now()).toLocal()
            ..projectId = docMap['projectId'];
          return m;
        }).toList();
        await isar.importMissions(missions);
      } else {
        // If they have 0 missions, ensure tutorial tasks are seeded!
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('tutorial_tasks_seeded', false);
      }
      
      // Restore projects
      final projectDocs = data['projects'] as List<dynamic>? ?? [];
      if (projectDocs.isNotEmpty) {
        final projects = projectDocs.map((doc) {
          final docMap = doc as Map<String, dynamic>;
          final p = Project()
            ..id = docMap['id'] ?? Isar.autoIncrement
            ..title = docMap['title'] ?? ''
            ..description = docMap['description']
            ..notes = docMap['notes']
            ..progress = (docMap['progress'] ?? 0.0).toDouble()
            ..createdAt = (DateTime.tryParse(docMap['createdAt'] ?? '') ?? DateTime.now()).toLocal();
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
    final previousUser = state.valueOrNull;
    state = const AsyncValue.loading();
    try {
      // 1. Backup current user's data to MongoDB
      await _backupCurrentUser();
      
      // 2. Restore the new user's data from MongoDB
      await _restoreUserData(user.id);
      
      // 3. Update auth state
      state = AsyncValue.data(user);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toMap()));
      await _saveUserToHistory(user);
    } catch (e) {
      if (previousUser != null) {
        state = AsyncValue.data(previousUser);
      } else {
        state = const AsyncValue.data(null);
      }
      rethrow;
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final map = jsonDecode(userJson);
        final user = AuthUser.fromMap(map);
        state = AsyncValue.data(user);
        
        // Silently verify session against backend in background
        _verifySession(user.email);
      } else {
        // No user is logged in, require explicit auth
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _verifySession(String email) async {
    try {
      if (email == 'yuvaan@ascent.app') return; // Bypass for local dev account
      final exists = await checkUserExists(email);
      if (!exists) {
        // User was deleted from the backend cloud, but local session exists.
        // Force log them out.
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_userKey);
        
        final isar = ref.read(localIsarProvider);
        await isar.clearAllData();
        
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      // Ignore network errors so offline mode still works
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
    
    // Sync with backend
    try {
      final mongo = ref.read(mongoDataSourceProvider);
      await mongo.updateProfile(
        current.email,
        name: name,
        bio: bio,
        role: role,
        socialHandle: socialHandle,
        motto: motto,
      );
    } catch (e) {
      print('Failed to update profile on backend: $e');
      // Decide if we should throw or just proceed locally. Usually we want to throw.
      rethrow;
    }

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

  Future<bool> sendOtp(String email, {String purpose = 'login'}) async {
    // Generate a 6-digit random OTP
    final random = _math.Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    
    // Store temporarily in memory or shared prefs (for this demo, we can just return it or let the UI manage it, but securely we should store it and compare)
    // For simplicity without a backend session, we will store it in SharedPreferences temporarily
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('temp_otp_$email', otp);
    
    // Call EmailService with the purpose
    final success = await EmailService.sendOtpEmail(email, otp, purpose: purpose);
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
    state = const AsyncValue.loading();
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
    state = const AsyncValue.loading();
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
    state = const AsyncValue.loading();
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
        
        // Ensure tutorial tasks will be seeded for this new account
        await prefs.setBool('tutorial_tasks_seeded', false);
        
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
    state = const AsyncValue.loading();
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
