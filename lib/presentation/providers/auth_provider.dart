import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_providers.dart';

class AuthUser {
  final String id;
  final String email;
  final String name;

  AuthUser({required this.id, required this.email, required this.name});

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      id: map['_id'].toString(),
      email: map['email'] ?? '',
      name: map['name'] ?? 'User',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'email': email,
      'name': name,
    };
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
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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
    state = const AsyncValue.data(null);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AuthUser?>>((ref) {
  return AuthNotifier(ref);
});
