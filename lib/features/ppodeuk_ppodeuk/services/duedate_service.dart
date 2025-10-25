import 'package:template/core/repositories/task_repository.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/period.dart';

class DueDateService {
  DueDateService({required TaskRepository taskRepository})
    : _taskRepository = taskRepository;
  final TaskRepository _taskRepository;

  Future<void> updateTaskDueDate(int taskId) async {
    final task = await _taskRepository.getTask(taskId);

    if (task == null) {
      throw ArgumentError('Task with id $taskId not found.');
    }

    // dueDate가 null이 아닐 경우에만 다음 마감일 계산
    if (task.dueDate == null) {
      throw ArgumentError(
        'Cannot update due date for a task with no initial due date.',
      );
    }

    final nextDueDate = calculateNextDueDate(task.dueDate!, task.period);

    await _taskRepository.updateTask(
      taskId,
      {'due_date': nextDueDate.toIso8601String()},
    );
  }

  DateTime calculateNextDueDate(DateTime currentDueDate, Period period) {
    if (period == Period.weekly) {
      return currentDueDate.add(const Duration(days: 7));
    } else if (period == Period.monthly) {
      var year = currentDueDate.year;
      var month = currentDueDate.month;
      var day = currentDueDate.day;

      month++;
      if (month > 12) {
        month = 1;
        year++;
      }

      // Handle cases where the next month has fewer days.
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
    } else {
      throw ArgumentError('Invalid period provided: $period');
    }
  }
}
