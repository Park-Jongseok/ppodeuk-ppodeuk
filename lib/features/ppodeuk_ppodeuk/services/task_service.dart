import 'package:template/core/repositories/task_repository.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/importance.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/task.dart';
import 'package:template/features/ppodeuk_ppodeuk/services/score_service.dart';
import 'package:template/features/ppodeuk_ppodeuk/services/startdate_service.dart';

/// 청소(Task) 관련 비즈니스 로직을 처리하는 서비스
class TaskService {
  /// [TaskService] 생성자
  TaskService({
    TaskRepository? taskRepository,
    ScoreService? scoreService,
    StartDateService? startDateService,
  }) : _taskRepository = taskRepository ?? TaskRepository(),
       _scoreService = scoreService ?? ScoreService() {
    _startDateService =
        startDateService ?? StartDateService(taskRepository: _taskRepository);
  }

  final TaskRepository _taskRepository;
  final ScoreService _scoreService;
  late final StartDateService _startDateService;

  /// 청소 생성 및 수정 시 점수 제한을 검증합니다.
  ///
  /// [oldTaskPoints]가 제공되면, 해당 점수를 현재 `openPoints`에서 제외하고 계산합니다.
  /// 이는 할 일 수정 시 기존 점수를 중복 계산하지 않기 위함입니다.
  Future<void> _validateTaskPoints({
    required int spaceId,
    required Importance newImportance,
    int? oldTaskPoints,
  }) async {
    // 현재 공간의 점수 계산 (100 - open_points)
    final currentScore = await _scoreService.calculateSpaceScore(spaceId);
    var openPoints = 100 - currentScore;

    // 청소 수정 시, 기존 청소의 점수를 openPoints에서 제외
    if (oldTaskPoints != null) {
      openPoints -= oldTaskPoints;
    }

    // 신규 청소의 포인트 계산
    final newTaskPoints = _getPointsForImportance(newImportance);

    // 총 포인트가 100을 초과하는지 확인
    if (openPoints + newTaskPoints > 100) {
      throw Exception(
        '해당 공간의 남은 점수가 부족합니다. 현재 남은 점수: ${100 - openPoints}점, 필요한 점수: $newTaskPoints점',
      );
    }
  }

  /// 청소 중요도에 따라 차감할 포인트를 반환합니다.
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

  /// 새로운 청소를 생성합니다.
  Future<int> createTask(Map<String, dynamic> taskData) async {
    // 점수 제한 검증
    final spaceId = taskData['space_id'] as int;
    final importance = Importance.values[taskData['importance'] as int];
    await _validateTaskPoints(spaceId: spaceId, newImportance: importance);

    // 청소 생성
    final taskId = await _taskRepository.createTask(taskData);

    // 공간 점수 업데이트
    await _scoreService.updateSpaceScore(spaceId);

    return taskId;
  }

  /// 기존 청소 정보를 업데이트합니다.
  Future<int> updateTask(int id, Map<String, dynamic> taskData) async {
    // 1. 기존 청소 정보 조회
    final oldTask = await _taskRepository.getTask(id);
    if (oldTask == null) {
      throw Exception('수정할 청소를 찾을 수 없습니다.');
    }

    // 2. 점수 제한 검증
    final spaceId = taskData['space_id'] as int;
    final newImportance = Importance.values[taskData['importance'] as int];
    final oldTaskPoints = _getPointsForImportance(oldTask.importance);

    await _validateTaskPoints(
      spaceId: spaceId,
      newImportance: newImportance,
      oldTaskPoints: oldTaskPoints,
    );

    // 3. 청소 업데이트
    final result = await _taskRepository.updateTask(id, taskData);

    // 4. 공간 점수 업데이트
    await _scoreService.updateSpaceScore(spaceId);

    return result;
  }

  /// 특정 청소를 삭제합니다.
  Future<int> deleteTask(int id) async {
    final result = await _taskRepository.deleteTask(id);

    // 공간 점수 업데이트 (삭제된 청소의 공간 ID를 알아야 하지만,
    // 현재 구조에서는 공간 ID를 알 수 없으므로 전체 공간 점수를 업데이트해야 함)
    // TODO(ppodeuk-team): 청소 삭제 시 해당 공간의 점수만 업데이트하도록 개선 필요

    return result;
  }

  /// 청소 완료 상태를 설정합니다.
  ///
  /// 완료 시 시작일이 있으면 다음 주기로 자동 업데이트하고 미완료 상태로 되돌립니다.
  Future<void> setTaskCompletion({
    required int taskId,
    required bool isCompleted,
  }) async {
    final task = await _taskRepository.getTask(taskId);
    if (task == null) {
      throw Exception('청소를 찾을 수 없습니다.');
    }

    await _taskRepository.updateTask(taskId, {
      'is_completed': isCompleted ? 1 : 0,
    });

    // 완료 시 시작일이 있으면 다음 주기로 자동 업데이트
    if (isCompleted && task.startDate != null) {
      await _startDateService.updateTaskStartDate(taskId);
      await _taskRepository.updateTask(taskId, {
        'is_completed': 0,
      });
    }

    await _scoreService.updateSpaceScore(task.spaceId);
  }

  /// 모든 청소 목록을 가져옵니다.
  ///
  /// 현재는 기본 사용자 ID를 사용합니다.
  Future<List<Task>> getTasks({
    required int userId,
    int? spaceId,
    int? assignedUserId,
    bool includeCompleted = true,
  }) {
    return _taskRepository.getTasks(
      userId: userId,
      spaceId: spaceId,
      assignedUserId: assignedUserId,
      includeCompleted: includeCompleted,
    );
  }
}
