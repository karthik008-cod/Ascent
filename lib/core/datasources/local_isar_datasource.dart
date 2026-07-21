import '../../data/datasources/dart:io';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/tasks/data/models/mission.dart';
import '../../features/tasks/data/models/project.dart';
import '../../features/tasks/data/models/task_item.dart';
import '../../features/progress/data/models/user_stats.dart';

class LocalIsarDataSource {
  late Future<Isar> db;

  LocalIsarDataSource() {
    db = _initDb();
  }

  Future<Isar> _initDb() async {
    if (Isar.instanceNames.isEmpty) {
      final dir = await getApplicationDocumentsDirectory();
      try {
        return await Isar.open(
          [MissionSchema, ProjectSchema, TaskItemSchema, UserStatsSchema],
          directory: dir.path,
        );
      } catch (e) {
        // Handle collection ID or schema mismatch from previous app runs cleanly
        try {
          await Isar.getInstance()?.close(deleteFromDisk: true);
        } catch (_) {}
        final file = File('${dir.path}/default.isar');
        if (await file.exists()) await file.delete();
        final lockFile = File('${dir.path}/default.isar.lock');
        if (await lockFile.exists()) await lockFile.delete();

        return await Isar.open(
          [MissionSchema, ProjectSchema, TaskItemSchema, UserStatsSchema],
          directory: dir.path,
        );
      }
    }
    return Future.value(Isar.getInstance());
  }

  // User Stats
  Future<UserStats> getUserStats() async {
    final isar = await db;
    var stats = await isar.userStats.get(1);
    if (stats == null) {
      stats = UserStats();
      await isar.writeTxn(() async {
        await isar.userStats.put(stats!);
      });
    }
    return stats;
  }

  Future<void> saveUserStats(UserStats stats) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.userStats.put(stats);
    });
  }

  // Missions
  Future<List<Mission>> getMissionsForDate(DateTime date) async {
    final isar = await db;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
    return await isar.missions
        .filter()
        .dateBetween(startOfDay, endOfDay)
        .findAll();
  }

  Future<void> saveMission(Mission mission) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.missions.put(mission);
    });
  }

  Future<void> deleteMission(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.missions.delete(id);
    });
  }

  // Projects
  Future<List<Project>> getAllProjects() async {
    final isar = await db;
    return await isar.projects.where().findAll();
  }

  Future<void> saveProject(Project project) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.projects.put(project);
    });
  }

  Future<void> deleteProject(int id) async {
    final isar = await db;
    await isar.writeTxn(() async {
      await isar.projects.delete(id);
    });
  }
}
