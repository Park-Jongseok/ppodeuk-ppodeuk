import 'package:template/core/database/database_helper.dart';

/// 사용자 관련 데이터 접근을 담당하는 레포지토리
class UserRepository {
  /// [UserRepository]를 생성합니다.
  ///
  /// [databaseHelper] 주입을 통해 대체 데이터 소스를 사용할 수 있습니다.
  UserRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  /// 새 사용자를 생성하고 생성된 식별자를 반환합니다.
  Future<int> createUser(Map<String, dynamic> user) {
    return _databaseHelper.insertUser(user);
  }

  /// 단일 사용자를 조회합니다.
  Future<Map<String, dynamic>?> getUser(int id) {
    return _databaseHelper.getUser(id);
  }

  /// 사용자와 동일한 공간에 속한 다른 사용자 목록을 조회합니다.
  Future<List<Map<String, dynamic>>> getUsersInSharedSpaces({
    required int userId,
  }) {
    return _databaseHelper.getUsersInSharedSpaces(userId: userId);
  }

  /// 사용자 정보를 갱신합니다.
  Future<int> updateUser(int id, Map<String, dynamic> user) {
    return _databaseHelper.updateUser(id, user);
  }

  /// 사용자를 삭제합니다.
  Future<int> deleteUser(int id) {
    return _databaseHelper.deleteUser(id);
  }
}
