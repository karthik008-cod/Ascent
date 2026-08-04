import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/project.dart';
import './data_providers.dart';

class ProjectsNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  ProjectsNotifier(this.ref, {bool loadImmediately = true}) : super(const AsyncValue.loading()) {
    if (loadImmediately) {
      _loadProjects();
    }
  }

  void setLoading() {
    state = const AsyncValue.loading();
  }

  final Ref ref;

  Future<void> _loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(projectRepositoryProvider);
      var projects = await repository.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addProject({
    required String title,
    String? description,
    double progress = 0.0,
    String? notes,
  }) async {
    final repository = ref.read(projectRepositoryProvider);
    final project = Project()
      ..title = title
      ..description = description
      ..progress = progress.clamp(0.0, 1.0)
      ..notes = notes
      ..createdAt = DateTime.now();
    await repository.saveProject(project);
    await _loadProjects();
  }

  Future<void> updateProject(Project project) async {
    final repository = ref.read(projectRepositoryProvider);
    project.progress = project.progress.clamp(0.0, 1.0);
    await repository.saveProject(project);
    await _loadProjects();
  }

  Future<void> deleteProject(int id) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.deleteProject(id);
    await _loadProjects();
  }
}

final projectsNotifierProvider = StateNotifierProvider<ProjectsNotifier, AsyncValue<List<Project>>>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState.isLoading) {
    return ProjectsNotifier(ref, loadImmediately: false)..setLoading();
  }
  return ProjectsNotifier(ref, loadImmediately: true);
});
