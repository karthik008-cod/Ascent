import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/tasks/data/models/mission.dart';
import '../../features/tasks/data/models/project.dart';
import '../../features/progress/data/models/user_stats.dart';

class MongoDataSource {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://ascent-1-7wj7.onrender.com/api',
  );

  Future<void> connect() async {}
  Future<void> disconnect() async {}

  Future<bool> checkUserExists(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['exists'] == true;
    }
    return false;
  }

  Future<Map<String, dynamic>?> signUp(String email, String password, String name) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to sign up: ${response.body}');
  }

  Future<Map<String, dynamic>?> signIn(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/signin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Invalid email or password');
  }

  Future<Map<String, dynamic>?> signInWithEmailOnly(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/auth/signin-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('User not found');
  }

  Future<void> updatePassword(String email, String newPassword) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/auth/password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'newPassword': newPassword}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update password');
    }
  }

  Future<void> updateProfile(String email, {String? name, String? bio, String? role, String? socialHandle, String? motto}) async {
    final body = <String, dynamic>{'email': email};
    if (name != null) body['name'] = name;
    if (bio != null) body['bio'] = bio;
    if (role != null) body['role'] = role;
    if (socialHandle != null) body['socialHandle'] = socialHandle;
    if (motto != null) body['motto'] = motto;

    final response = await http.put(
      Uri.parse('$_baseUrl/auth/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  Future<void> deleteUser(String email) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/auth/$email'),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  Future<void> backupData(String userId, List<Mission> missions, UserStats stats, [List<Project>? projects]) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/sync/backup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'stats': {
          'totalXp': stats.totalXp,
          'currentLevel': stats.currentLevel,
          'currentStreak': stats.currentStreak,
          'longestStreak': stats.longestStreak,
          'lastActiveDate': stats.lastActiveDate?.toIso8601String(),
        },
        'missions': missions.map((m) => {
          'id': m.id,
          'title': m.title,
          'description': m.description,
          'type': m.type.index,
          'xpReward': m.xpReward,
          'isCompleted': m.isCompleted,
          'date': m.date.toIso8601String(),
          'projectId': m.projectId,
        }).toList(),
        'projects': projects?.map((p) => {
          'id': p.id,
          'title': p.title,
          'description': p.description,
          'notes': p.notes,
          'progress': p.progress,
          'createdAt': p.createdAt.toIso8601String(),
        }).toList(),
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Backup failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> restoreData(String userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/sync/restore/$userId'),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Restore failed');
  }
}
