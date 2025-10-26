import 'package:template/features/ppodeuk_ppodeuk/models/space.dart';

/// 반려동물 메시지 서비스
///
/// 공간 점수에 따라 다른 메시지를 반환합니다.
class PetMessageService {
  /// 공간 점수 목록을 받아 최종 메시지를 결정합니다.
  ///
  /// 주어진 규칙에 따라 가장 낮은 점수의 공간을 찾아 메시지를 분기합니다.
  /// 공간이 비어 있으면 완벽한 상태로 간주합니다.
  String decideMessage(List<Space> spaces) {
    if (spaces.isEmpty) {
      return '[ 뽀롱이 😺: 우리 집은 완벽해! 기분 최고야! ]';
    }

    final allPerfect = spaces.every((space) => space.score == 100);
    if (allPerfect) {
      return '[ 뽀롱이 😺: 우리 집은 완벽해! 기분 최고야! ]';
    }

    final lowestScoreSpace = spaces.reduce(
      (current, next) => current.score < next.score ? current : next,
    );

    final score = lowestScoreSpace.score;
    final name = lowestScoreSpace.name;

    if (score >= 80) {
      return '[ 뽀롱이 😼: $name이(가) 살짝 어질러졌어요. 같이 정리해볼까요? ]';
    }

    return '[ 뽀롱이 🥺: $name 때문에 발바닥이 축축해… 오늘 여기 먼저 부탁해요! ]';
  }
}
