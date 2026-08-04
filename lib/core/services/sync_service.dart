import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/tasks/presentation/providers/missions_provider.dart';
import '../../features/tasks/presentation/providers/projects_provider.dart';
import '../../features/progress/presentation/providers/user_stats_provider.dart';
import '../../features/tasks/presentation/providers/data_providers.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  final Ref ref;
  bool _isSyncing = false;

  SyncService(this.ref) {
    _initListeners();
    _checkPendingSyncOnStartup();
  }

  void _initListeners() {
    // Listen to changes in local data
    ref.listen(missionNotifierProvider, (previous, next) {
      if (next is AsyncData) _triggerSync();
    });
    ref.listen(projectsNotifierProvider, (previous, next) {
      if (next is AsyncData) _triggerSync();
    });
    ref.listen(userStatsNotifierProvider, (previous, next) {
      if (next is AsyncData) _triggerSync();
    });

    // Listen to network connectivity changes
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none)) {
        // We have internet, check if there's pending data
        _checkPendingSyncOnStartup();
      }
    });
  }

  Future<void> _checkPendingSyncOnStartup() async {
    final prefs = await SharedPreferences.getInstance();
    final needsSync = prefs.getBool('needs_sync') ?? false;
    if (needsSync) {
      print('Detected pending offline data, attempting sync now...');
      await _triggerSync();
    }
  }

  Future<void> _triggerSync() async {
    if (_isSyncing) return;
    
    final user = ref.read(authNotifierProvider).valueOrNull;
    if (user == null || user.id == 'local_user') return;

    final missions = ref.read(missionNotifierProvider).valueOrNull;
    final projects = ref.read(projectsNotifierProvider).valueOrNull;
    final stats = ref.read(userStatsNotifierProvider).valueOrNull;

    if (missions == null || projects == null || stats == null) return;

    _isSyncing = true;
    final prefs = await SharedPreferences.getInstance();
    
    try {
      final mongo = ref.read(mongoDataSourceProvider);
      final missionsToBackup = missions.where((m) => !(m.description?.contains('[TUTORIAL_TASK]') ?? false)).toList();
      
      // Perform the upload
      await mongo.backupData(user.id, missionsToBackup, stats, projects);
      
      // Clear the pending sync flag on success
      await prefs.setBool('needs_sync', false);
      print('Background sync completed successfully.');
    } catch (e) {
      // Offline or network error: mark as needing sync
      await prefs.setBool('needs_sync', true);
      print('Background sync failed (saved locally, will retry later): $e');
    } finally {
      _isSyncing = false;
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});
