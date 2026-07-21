import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/tasks/presentation/providers/missions_provider.dart';
import '../../features/tasks/presentation/providers/projects_provider.dart';
import '../../features/progress/presentation/providers/user_stats_provider.dart';
import '../../features/tasks/presentation/providers/data_providers.dart';

class SyncService {
  final Ref ref;

  SyncService(this.ref) {
    _initListeners();
  }

  void _initListeners() {
    // Listen to changes in missions
    ref.listen(missionNotifierProvider, (previous, next) {
      if (next is AsyncData) _triggerSync();
    });

    // Listen to changes in projects
    ref.listen(projectsNotifierProvider, (previous, next) {
      if (next is AsyncData) _triggerSync();
    });

    // Listen to changes in user stats
    ref.listen(userStatsNotifierProvider, (previous, next) {
      if (next is AsyncData) _triggerSync();
    });
  }

  Future<void> _triggerSync() async {
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null || user.id == 'local_user') return;

    final missions = ref.read(missionNotifierProvider).valueOrNull;
    final projects = ref.read(projectsNotifierProvider).valueOrNull;
    final stats = ref.read(userStatsNotifierProvider).valueOrNull;

    if (missions == null || projects == null || stats == null) return;

    try {
      final mongo = ref.read(mongoDataSourceProvider);
      await mongo.backupData(user.id, missions, stats, projects);
      print('Background sync completed successfully.');
    } catch (e) {
      print('Background sync failed: $e');
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});
