import 'package:template/core/repositories/task_repository.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/period.dart';

/// 청소 시작일 관리 서비스
///
/// 주기적 청소의 시작일을 계산하고 업데이트합니다.
class StartDateService {
  /// [StartDateService] 생성자
  StartDateService({required TaskRepository taskRepository})
      : _taskRepository = taskRepository;
  final TaskRepository _taskRepository;

  /// 청소 완료 시 다음 시작일로 업데이트합니다.
  Future<void> updateTaskStartDate(int taskId) async {
    final task = await _taskRepository.getTask(taskId);

    if (task == null) {
      throw ArgumentError('Task with id $taskId not found.');
    }

    // startDate가 null이 아닐 경우에만 다음 시작일 계산
    if (task.startDate == null) {
      throw ArgumentError(
        'Cannot update start date for a task with no initial start date.',
      );
    }

    final nextStartDate = calculateNextStartDate(task.startDate!, task.period);

    await _taskRepository.updateTask(
      taskId,
      {'start_date': nextStartDate.toIso8601String()},
    );
  }

  /// 주기에 따라 다음 시작일을 계산합니다.
  DateTime calculateNextStartDate(DateTime currentStartDate, Period period) {
    if (period == Period.weekly) {
      return currentStartDate.add(const Duration(days: 7));
    } else if (period == Period.monthly) {
      var year = currentStartDate.year;
      var month = currentStartDate.month;
      var day = currentStartDate.day;

      month++;
      if (month > 12) {
        month = 1;
        year++;
      }

      // 다음 달의 일수가 적을 경우 처리
      final lastDayOfNextMonth = DateTime(year, month + 1, 0).day;
      if (day > lastDayOfNextMonth) {
        day = lastDayOfNextMonth;
      }

      return DateTime(
        year,
        month,
        day,
        currentStartDate.hour,
        currentStartDate.minute,
        currentStartDate.second,
      );
    } else {
      throw ArgumentError('Invalid period provided: $period');
    }
  }
}
