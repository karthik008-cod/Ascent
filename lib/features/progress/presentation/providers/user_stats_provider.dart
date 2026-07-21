import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_stats.dart';
import '../../../tasks/presentation/providers/data_providers.dart';

class LevelSystem {
  /// Total cumulative XP needed to reach [level].
  /// Calibrated so a moderate user (1 Main + 2 Side + 2 Routine = 240 XP/day)
  /// reaches level 50 in ~6 months. Levels are unlimited.
  static int getTotalXpForLevel(int level) {
    if (level <= 1) return 0;
    int cumulative = 0;
    for (int i = 1; i < level; i++) {
      int stepXp = (25 * math.pow(i, 1.1)).round();
      cumulative += stepXp;
    }
    return cumulative;
  }

  /// Calculates current level given total XP.
  static int calculateLevel(int totalXp) {
    if (totalXp <= 0) return 1;
    int lvl = 1;
    while (getTotalXpForLevel(lvl + 1) <= totalXp) {
      lvl++;
    }
    return lvl;
  }

  /// Returns XP required inside current level interval to reach next level.
  static int getXpStepForCurrentLevel(int level) {
    return (25 * math.pow(level, 1.1)).round();
  }

  /// Returns total XP required for next level (`getTotalXpForLevel(level + 1)`).
  static int getNextLevelTotalXp(int level) {
    return getTotalXpForLevel(level + 1);
  }

  /// Returns progress ratio [0.0 - 1.0] towards next level.
  static double getLevelProgress(int totalXp) {
    final currentLevel = calculateLevel(totalXp);
    final currentBaseXp = getTotalXpForLevel(currentLevel);
    final nextTotalXp = getNextLevelTotalXp(currentLevel);
    if (nextTotalXp <= currentBaseXp) return 1.0;
    final progress = (totalXp - currentBaseXp) / (nextTotalXp - currentBaseXp);
    return progress.clamp(0.0, 1.0);
  }
}

class UserStatsNotifier extends StateNotifier<AsyncValue<UserStats>> {
  UserStatsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadStats();
  }

  final Ref ref;

  Future<void> _loadStats() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(statsRepositoryProvider);
      final stats = await repository.getUserStats();
      stats.currentLevel = LevelSystem.calculateLevel(stats.totalXp);
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Returns the new level if a level-up occurred, null otherwise.
  Future<int?> addXp(int xp) async {
    final repository = ref.read(statsRepositoryProvider);
    if (state.value != null) {
      final stats = state.value!;
      final oldLevel = stats.currentLevel;
      stats.totalXp += xp;
      stats.currentLevel = LevelSystem.calculateLevel(stats.totalXp);
      
      await repository.saveUserStats(stats);
      state = AsyncValue.data(stats);

      if (stats.currentLevel > oldLevel) {
        return stats.currentLevel;
      }
    }
    return null;
  }
  
  Future<void> removeXp(int xp) async {
    final repository = ref.read(statsRepositoryProvider);
    if (state.value != null) {
      final stats = state.value!;
      stats.totalXp = (stats.totalXp - xp).clamp(0, double.infinity).toInt();
      stats.currentLevel = LevelSystem.calculateLevel(stats.totalXp);
      
      await repository.saveUserStats(stats);
      state = AsyncValue.data(stats);
    }
  }
}

final userStatsNotifierProvider = StateNotifierProvider<UserStatsNotifier, AsyncValue<UserStats>>((ref) {
  return UserStatsNotifier(ref);
});
