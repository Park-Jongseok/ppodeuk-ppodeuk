import 'package:template/core/repositories/task_repository.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/period.dart';

/// 청소 시작일을 바탕으로 다음 마감일을 계산하는 서비스
class DueDateService {
  /// [DueDateService]를 생성합니다.
  ///
  /// [taskRepository]는 의존성 주입을 위해 사용됩니다.
  DueDateService({required TaskRepository taskRepository})
    : _taskRepository = taskRepository;

  final TaskRepository _taskRepository;

  /// 태스크의 다음 마감일을 계산하고 저장합니다.
  ///
  /// [taskId]가 존재하고 시작일이 설정되어 있어야 합니다.
  Future<void> updateTaskDueDate(int taskId) async {
    final task = await _taskRepository.getTask(taskId);

    if (task == null) {
      throw ArgumentError('Task with id $taskId not found.');
    }

    // dueDate가 null이 아닐 경우에만 다음 마감일 계산
    if (task.startDate == null) {
      throw ArgumentError(
        'Cannot update due date for a task with no initial due date.',
      );
    }

    final nextDueDate = calculateNextDueDate(task.startDate!, task.period);

    await _taskRepository.updateTask(
      taskId,
      {'due_date': nextDueDate.toIso8601String()},
    );
  }

  /// 현재 마감일과 주기를 기반으로 다음 마감일을 반환합니다.
  DateTime calculateNextDueDate(DateTime currentDueDate, Period period) {
    switch (period) {
      case Period.weekly:
        return currentDueDate.add(const Duration(days: 7));
      case Period.monthly:
        var year = currentDueDate.year;
        var month = currentDueDate.month + 1;
        var day = currentDueDate.day;

        if (month > 12) {
          month = 1;
          year++;
        }

        final lastDayOfNextMonth = DateTime(year, month + 1, 0).day;
        if (day > lastDayOfNextMonth) {
          day = lastDayOfNextMonth;
        }

        return DateTime(
          year,
          month,
          day,
          currentDueDate.hour,
          currentDueDate.minute,
          currentDueDate.second,
        );
    }
  }
}
