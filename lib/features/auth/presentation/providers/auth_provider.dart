import 'dart:convert';
import 'dart:math' as _math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/email_service.dart';
import '../../../tasks/presentation/providers/data_providers.dart';

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
    state = const AsyncValue.loading();
    try {
      final mongo = ref.read(mongoDataSourceProvider);
      final userData = await mongo.signIn(email, password);
      if (userData != null) {
        final user = AuthUser.fromMap(userData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toMap()));
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
      final mongo = ref.read(mongoDataSourceProvider);
      final userData = await mongo.signInWithEmailOnly(email);
      if (userData != null) {
        final user = AuthUser.fromMap(userData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toMap()));
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
      final mongo = ref.read(mongoDataSourceProvider);
      final userData = await mongo.signUp(email, password, name);
      if (userData != null) {
        final user = AuthUser.fromMap(userData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, jsonEncode(user.toMap()));
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

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    // Explicitly sign out, forcing router to redirect to auth screen
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>((ref) {
  return AuthNotifier(ref);
});
