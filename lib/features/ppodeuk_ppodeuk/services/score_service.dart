import 'package:template/core/database/database_helper.dart';
import 'package:template/core/repositories/space_repository.dart';
import 'package:template/core/repositories/task_repository.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/importance.dart';

/// 공간의 점수를 계산하고 업데이트하는 서비스 클래스
class ScoreService {
  ScoreService({
    DatabaseHelper? databaseHelper,
    TaskRepository? taskRepository,
    SpaceRepository? spaceRepository,
  }) : _databaseHelper = databaseHelper ?? DatabaseHelper.instance,
       _taskRepository = taskRepository ?? TaskRepository(),
       _spaceRepository = spaceRepository ?? SpaceRepository();

  final DatabaseHelper _databaseHelper;
  final TaskRepository _taskRepository;
  final SpaceRepository _spaceRepository;

  /// 특정 공간의 점수를 계산합니다.
  ///
  /// [spaceId]에 해당하는 공간의 완료되지 않은 할 일들을 조회하여
  /// 중요도에 따라 점수를 차감하는 방식으로 계산합니다.
  /// 점수는 100점에서 시작하며, 0점 미만으로 내려가지 않습니다.
  Future<int> calculateSpaceScore(int spaceId) async {
    // MVP에서는 기본 사용자를 기준으로 작업을 조회합니다.
    final defaultUserId = await _databaseHelper.getDefaultUserId();

    final tasks = await _taskRepository.getTasks(
      userId: defaultUserId,
      spaceId: spaceId,
      includeCompleted: false,
    );

    var openPoints = 0;
    for (final task in tasks) {
      openPoints += _getPointsForImportance(task.importance);
    }

    final score = 100 - openPoints;
    return score < 0 ? 0 : score;
  }

  /// 할 일의 중요도에 따라 차감할 포인트를 반환합니다.
  int _getPointsForImportance(Importance importance) {
    switch (importance) {
      case Importance.important:
        return 15;
      case Importance.normal:
        return 5;
      case Importance.daily:
        return 2;
    }
  }

  /// 특정 공간의 점수를 최신 상태로 업데이트합니다.
  ///
  /// 할 일이 추가되거나 완료/수정될 때 호출되어
  /// DB에 저장된 공간의 점수를 갱신합니다.
  Future<void> updateSpaceScore(int spaceId) async {
    final newScore = await calculateSpaceScore(spaceId);
    await _spaceRepository.updateSpaceScore(spaceId, newScore);
  }
}
