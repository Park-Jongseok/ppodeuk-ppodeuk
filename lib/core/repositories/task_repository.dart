import 'package:template/core/database/database_helper.dart';

/// 청소/할일(Task) 데이터를 다루는 레포지토리
class TaskRepository {
  TaskRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  /// 새로운 태스크를 생성합니다.
  Future<int> createTask(Map<String, dynamic> task) {
    return _databaseHelper.insertTask(task);
  }

  /// 사용자 권한에 기반해 태스크 목록을 조회합니다.
  Future<List<Map<String, dynamic>>> getTasks({
    required int userId,
    int? spaceId,
    int? assignedUserId,
    bool includeCompleted = true,
  }) {
    return _databaseHelper.getTasks(
      userId: userId,
      spaceId: spaceId,
      assignedUserId: assignedUserId,
      includeCompleted: includeCompleted,
    );
  }

  /// 태스크 정보를 갱신합니다.
  Future<int> updateTask(int id, Map<String, dynamic> task) {
    return _databaseHelper.updateTask(id, task);
  }

  /// 태스크를 삭제합니다.
  Future<int> deleteTask(int id) {
    return _databaseHelper.deleteTask(id);
  }
}
