import 'package:template/features/ppodeuk_ppodeuk/models/space.dart';

/// 반려동물 메시지 서비스
///
/// 공간 점수에 따라 다른 메시지를 반환합니다.
class PetMessageService {
  /// 공간 목록을 받아 적절한 메시지를 반환합니다.
  String getPetMessage(List<Space> spaces) {
    if (spaces.isEmpty) {
      return '아직 관리할 공간이 없어요.';
    }

    final allPerfect = spaces.every((space) => space.score == 100);
    if (allPerfect) {
      return '완벽해!';
    }

    final lowestScoreSpace = spaces.reduce(
      (current, next) => current.score < next.score ? current : next,
    );

    final score = lowestScoreSpace.score;
    final name = lowestScoreSpace.name;

    if (score >= 80) {
      return '$name! 조금만 더 힘내면 완벽해! 🐾';
    } else {
      return '$name 때문에 발바닥이 축축해… 오늘 여기 먼저 부탁해요 🥺';
    }
  }
}
