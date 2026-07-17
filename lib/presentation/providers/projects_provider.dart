import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/project.dart';
import 'data_providers.dart';

class ProjectsNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  ProjectsNotifier(this.ref) : super(const AsyncValue.loading()) {
    loadProjects();
  }

  final Ref ref;

  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(projectRepositoryProvider);
      var projects = await repository.getAllProjects();
      if (projects.isEmpty) {
        // Create initial default starter projects for user flexibility
        final p1 = Project()
          ..title = 'Ascent Mobile & Web App'
          ..description = 'Building full-stack productivity ecosystem with Level & XP gamification'
          ..progress = 0.75
          ..notes = 'Integrated with Isar local storage and Render web deployment.';
        final p2 = Project()
          ..title = 'Skill Mastery & Career Goals'
          ..description = 'Tracking long-term learning milestones and professional projects'
          ..progress = 0.40
          ..notes = 'Focus on scalable architectures and modern UI design.';
        await repository.saveProject(p1);
        await repository.saveProject(p2);
        projects = await repository.getAllProjects();
      }
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
    await loadProjects();
  }

  Future<void> updateProject(Project project) async {
    final repository = ref.read(projectRepositoryProvider);
    project.progress = project.progress.clamp(0.0, 1.0);
    await repository.saveProject(project);
    await loadProjects();
  }

  Future<void> deleteProject(int id) async {
    final repository = ref.read(projectRepositoryProvider);
    await repository.deleteProject(id);
    await loadProjects();
  }
}

final projectsNotifierProvider = StateNotifierProvider<ProjectsNotifier, AsyncValue<List<Project>>>((ref) {
  return ProjectsNotifier(ref);
});
