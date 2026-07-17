import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_stats.dart';
import 'data_providers.dart';

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
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addXp(int xp) async {
    final repository = ref.read(statsRepositoryProvider);
    if (state.value != null) {
      final stats = state.value!;
      stats.totalXp += xp;
      
      // Simple Level calculation (every 100 XP is a level)
      stats.currentLevel = (stats.totalXp ~/ 100) + 1;
      
      await repository.saveUserStats(stats);
      state = AsyncValue.data(stats);
    }
  }
  
  Future<void> removeXp(int xp) async {
    final repository = ref.read(statsRepositoryProvider);
    if (state.value != null) {
      final stats = state.value!;
      stats.totalXp = (stats.totalXp - xp).clamp(0, double.infinity).toInt();
      stats.currentLevel = (stats.totalXp ~/ 100) + 1;
      
      await repository.saveUserStats(stats);
      state = AsyncValue.data(stats);
    }
  }
}

final userStatsNotifierProvider = StateNotifierProvider<UserStatsNotifier, AsyncValue<UserStats>>((ref) {
  return UserStatsNotifier(ref);
});
