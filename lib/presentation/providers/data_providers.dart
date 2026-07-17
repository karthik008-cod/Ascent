import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_isar_datasource.dart';
import '../../data/datasources/mongo_datasource.dart';
import '../../data/repositories/mission_repository_impl.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../data/repositories/stats_repository_impl.dart';
import '../../domain/repositories/mission_repository.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/stats_repository.dart';

final localIsarProvider = Provider<LocalIsarDataSource>((ref) {
  return LocalIsarDataSource();
});

final mongoDataSourceProvider = Provider<MongoDataSource>((ref) {
  return MongoDataSource();
});

final missionRepositoryProvider = Provider<MissionRepository>((ref) {
  final dataSource = ref.watch(localIsarProvider);
  return MissionRepositoryImpl(dataSource);
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final dataSource = ref.watch(localIsarProvider);
  return StatsRepositoryImpl(dataSource);
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final dataSource = ref.watch(localIsarProvider);
  return ProjectRepositoryImpl(dataSource);
});
