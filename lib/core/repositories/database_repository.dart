import 'package:template/core/database/database_helper.dart';

/// DatabaseHelper의 공용 기능을 래핑하는 상위 레포지토리
class DatabaseRepository {
  /// [DatabaseRepository]를 생성합니다.
  ///
  /// [databaseHelper]가 주어지면 해당 헬퍼를 사용하고, 그렇지 않으면 기본 인스턴스를 사용합니다.
  DatabaseRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  /// MVP 환경에서 기본 사용자가 접근 가능한 공간 목록을 반환합니다.
  Future<List<Map<String, dynamic>>> getDefaultUserSpaces() {
    return _databaseHelper.getDefaultUserSpaces();
  }

  /// MVP 환경에서 기본 사용자가 접근 가능한 태스크 목록을 반환합니다.
  Future<List<Map<String, dynamic>>> getDefaultUserTasks({
    int? assignedUserId,
    bool includeCompleted = true,
  }) {
    return _databaseHelper.getDefaultUserTasks(
      assignedUserId: assignedUserId,
      includeCompleted: includeCompleted,
    );
  }

  /// 데이터베이스 연결을 닫습니다.
  Future<void> close() {
    return _databaseHelper.close();
  }
}
