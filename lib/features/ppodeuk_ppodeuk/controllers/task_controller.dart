import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template/core/controllers/user_controller.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/importance.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/period.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/task.dart';
import 'package:template/features/ppodeuk_ppodeuk/services/task_service.dart';

/// 할 일 컨트롤러 프로바이더
final taskControllerProvider =
    NotifierProvider<TaskController, TaskControllerState>(
      TaskController.new,
    );

/// 할 일 컨트롤러 상태
class TaskControllerState {
  const TaskControllerState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Task> tasks;
  final bool isLoading;
  final String? error;

  TaskControllerState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
  }) {
    return TaskControllerState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 할 일 관리 컨트롤러
class TaskController extends Notifier<TaskControllerState> {
  late final TaskService _taskService;

  @override
  TaskControllerState build() {
    _taskService = TaskService();
    return const TaskControllerState();
  }

  /// 할 일 목록 로드
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final defaultUserId = await ref.read(defaultUserIdProvider.future);
      final tasks = await _taskService.getTasks(userId: defaultUserId);
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 새 할 일 생성
  Future<void> createTask({
    required String name,
    required int spaceId,
    required Importance importance,
    required Period period,
    DateTime? startDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final taskData = {
        'name': name,
        'space_id': spaceId,
        'importance': importance.index,
        'period': period.index,
        'start_date': startDate?.toIso8601String(),
      };

      await _taskService.createTask(taskData);

      // 할 일 목록 새로고침
      await loadTasks();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow; // UI에서 에러를 처리할 수 있도록 다시 던지기
    }
  }

  /// 할 일 수정
  Future<void> updateTask({
    required int taskId,
    required String name,
    required int spaceId,
    required Importance importance,
    required Period period,
    DateTime? startDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final taskData = {
        'name': name,
        'space_id': spaceId,
        'importance': importance.index,
        'period': period.index,
        'start_date': startDate?.toIso8601String(),
      };

      await _taskService.updateTask(taskId, taskData);

      // 할 일 목록 새로고침
      await loadTasks();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow; // UI에서 에러를 처리할 수 있도록 다시 던지기
    }
  }

  /// 할 일 삭제
  Future<void> deleteTask(int taskId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _taskService.deleteTask(taskId);

      // 할 일 목록 새로고침
      await loadTasks();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow; // UI에서 에러를 처리할 수 있도록 다시 던지기
    }
  }

  /// 에러 상태 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 할 일 완료 상태 설정
  Future<void> setTaskCompletion({
    required int taskId,
    required bool isCompleted,
  }) async {
    try {
      await _taskService.setTaskCompletion(
        taskId: taskId,
        isCompleted: isCompleted,
      );

      // 최신 상태 유지
      await loadTasks();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}
