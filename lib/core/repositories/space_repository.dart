import 'package:template/core/database/database_helper.dart';

/// 공간(Space) 관련 데이터 접근을 담당하는 레포지토리
class SpaceRepository {
  SpaceRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  /// 새 공간을 추가합니다.
  Future<int> createSpace(Map<String, dynamic> space) {
    return _databaseHelper.insertSpace(space);
  }

  /// 특정 사용자가 속한 모든 공간 목록을 반환합니다.
  Future<List<Map<String, dynamic>>> getSpacesForUser(int userId) {
    return _databaseHelper.getSpaces(userId: userId);
  }

  /// 공간 점수를 업데이트합니다.
  Future<int> updateSpaceScore(int id, int score) {
    return _databaseHelper.updateSpaceScore(id, score);
  }

  /// 공간을 삭제합니다.
  Future<int> deleteSpace(int id) {
    return _databaseHelper.deleteSpace(id);
  }
}
