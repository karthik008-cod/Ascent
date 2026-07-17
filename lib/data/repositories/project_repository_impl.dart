import '../../domain/repositories/project_repository.dart';
import '../datasources/local_isar_datasource.dart';
import '../models/project.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final LocalIsarDataSource _dataSource;

  ProjectRepositoryImpl(this._dataSource);

  @override
  Future<List<Project>> getAllProjects() async {
    return await _dataSource.getAllProjects();
  }

  @override
  Future<void> saveProject(Project project) async {
    await _dataSource.saveProject(project);
  }

  @override
  Future<void> deleteProject(int id) async {
    await _dataSource.deleteProject(id);
  }
}
