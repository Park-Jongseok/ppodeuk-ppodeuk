import 'package:template/core/database/database_helper.dart';

/// 공간 멤버십 관계를 다루는 레포지토리
class SpaceMembershipRepository {
  /// [SpaceMembershipRepository]를 생성합니다.
  ///
  /// [databaseHelper]를 전달하면 의존성을 주입할 수 있습니다.
  SpaceMembershipRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  /// 사용자를 공간의 멤버로 추가합니다.
  Future<int> createMembership(Map<String, dynamic> membership) {
    return _databaseHelper.insertSpaceMembership(membership);
  }

  /// 특정 공간의 멤버 목록을 조회합니다.
  Future<List<Map<String, dynamic>>> getSpaceMembers({
    required int spaceId,
    required int userId,
  }) {
    return _databaseHelper.getSpaceMembers(spaceId: spaceId, userId: userId);
  }

  /// 사용자의 공간 멤버십을 삭제합니다.
  Future<int> deleteMembership({
    required int userId,
    required int spaceId,
  }) {
    return _databaseHelper.deleteSpaceMembership(userId, spaceId);
  }
}
