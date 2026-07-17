import '../../data/models/project.dart';

abstract class ProjectRepository {
  Future<List<Project>> getAllProjects();
  Future<void> saveProject(Project project);
  Future<void> deleteProject(int id);
}
