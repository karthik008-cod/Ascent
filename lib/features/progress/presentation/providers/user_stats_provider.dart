import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/user_stats.dart';
import '../../../tasks/presentation/providers/data_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LevelUpEvent {
  final int oldLevel;
  final int newLevel;
  LevelUpEvent(this.oldLevel, this.newLevel);
}

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
  UserStatsNotifier(this.ref, {bool loadImmediately = true}) : super(const AsyncValue.loading()) {
    if (loadImmediately) {
      _loadStats();
    }
  }

  void setLoading() {
    state = const AsyncValue.loading();
  }

  final Ref ref;

  Future<void> _loadStats() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(statsRepositoryProvider);
      final stats = await repository.getUserStats();
      stats.currentLevel = LevelSystem.calculateLevel(stats.totalXp);
      state = AsyncValue.data(stats);
      await refreshStreakOnLaunch();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refreshStreakOnLaunch() async {
    final repository = ref.read(statsRepositoryProvider);
    if (state.value != null) {
      final stats = state.value!;
      if (stats.lastActiveDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final last = stats.lastActiveDate!;
        final lastDate = DateTime(last.year, last.month, last.day);
        
        if (today.difference(lastDate).inDays > 1) {
          // Missed a day, reset streak to 0
          if (stats.currentStreak != 0) {
            stats.currentStreak = 0;
            await repository.saveUserStats(stats);
            state = AsyncValue.data(stats);
          }
        }
      }
    }
  }

  Future<void> checkAndUpdateStreak() async {
    final repository = ref.read(statsRepositoryProvider);
    if (state.value != null) {
      final stats = state.value!;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      if (stats.lastActiveDate != null) {
        final last = stats.lastActiveDate!;
        final lastDate = DateTime(last.year, last.month, last.day);
        
        final diff = today.difference(lastDate).inDays;
        if (diff == 1) {
          // Continuous day!
          stats.currentStreak += 1;
          if (stats.currentStreak > stats.longestStreak) {
            stats.longestStreak = stats.currentStreak;
          }
          stats.lastActiveDate = now;
        } else if (diff > 1) {
          // Streak was broken
          stats.currentStreak = 1;
          stats.lastActiveDate = now;
        } else if (diff == 0) {
          // Already active today, just update time
          stats.lastActiveDate = now;
        }
      } else {
        // First time ever active
        stats.currentStreak = 1;
        if (stats.currentStreak > stats.longestStreak) {
          stats.longestStreak = stats.currentStreak;
        }
        stats.lastActiveDate = now;
      }
      
      // Update SharedPreferences for weekly activity history
      final prefs = await SharedPreferences.getInstance();
      final activeDates = prefs.getStringList('active_dates') ?? [];
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      if (!activeDates.contains(dateStr)) {
        activeDates.add(dateStr);
        if (activeDates.length > 30) activeDates.removeAt(0);
        await prefs.setStringList('active_dates', activeDates);
        ref.invalidate(weeklyActivityProvider);
      }
      
      await repository.saveUserStats(stats);
      state = AsyncValue.data(stats);
    }
  }

  /// Returns the LevelUpEvent if a level-up occurred, null otherwise.
  Future<LevelUpEvent?> addXp(int xp) async {
    final repository = ref.read(statsRepositoryProvider);
    if (state.value != null) {
      final stats = state.value!;
      final oldLevel = stats.currentLevel;
      stats.totalXp += xp;
      stats.currentLevel = LevelSystem.calculateLevel(stats.totalXp);
      
      await repository.saveUserStats(stats);
      state = AsyncValue.data(stats);

      if (stats.currentLevel > oldLevel) {
        return LevelUpEvent(oldLevel, stats.currentLevel);
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

  Future<void> incrementCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final storedDate = prefs.getString('completed_today_date') ?? '';
    if (storedDate != dateStr) {
      await prefs.setInt('completed_today_count', 1);
      await prefs.setString('completed_today_date', dateStr);
    } else {
      final current = prefs.getInt('completed_today_count') ?? 0;
      await prefs.setInt('completed_today_count', current + 1);
    }
    ref.invalidate(completedTodayProvider);
  }

  Future<void> decrementCompletedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final storedDate = prefs.getString('completed_today_date') ?? '';
    if (storedDate == dateStr) {
      final current = prefs.getInt('completed_today_count') ?? 0;
      if (current > 0) {
        await prefs.setInt('completed_today_count', current - 1);
        ref.invalidate(completedTodayProvider);
      }
    }
  }
}

final userStatsNotifierProvider = StateNotifierProvider<UserStatsNotifier, AsyncValue<UserStats>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState.isLoading) {
    return UserStatsNotifier(ref, loadImmediately: false)..setLoading();
  }
  return UserStatsNotifier(ref, loadImmediately: true);
});

final completedTodayProvider = FutureProvider<int>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now();
  final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  
  final storedDate = prefs.getString('completed_today_date') ?? '';
  if (storedDate != dateStr) {
    return 0; // Reset for a new day
  }
  return prefs.getInt('completed_today_count') ?? 0;
});

final weeklyActivityProvider = FutureProvider<List<bool>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final activeDates = prefs.getStringList('active_dates') ?? [];
  final now = DateTime.now();
  
  return List.generate(7, (i) {
    final day = now.subtract(Duration(days: 6 - i));
    final dateStr = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return activeDates.contains(dateStr);
  });
});
