import 'package:template/core/repositories/task_repository.dart';

/// 할 일(Task) 관련 비즈니스 로직을 처리하는 서비스
class TaskService {
  TaskService({TaskRepository? taskRepository})
    : _taskRepository = taskRepository ?? TaskRepository();

  final TaskRepository _taskRepository;

  /// 새로운 할 일을 생성합니다.
  Future<int> createTask(Map<String, dynamic> taskData) {
    // TODO: 필요하다면 여기에 추가적인 비즈니스 로직을 구현합니다.
    // 예를 들어, 유효성 검사, 데이터 가공 등
    return _taskRepository.createTask(taskData);
  }

  /// 기존 할 일 정보를 업데이트합니다.
  Future<int> updateTask(int id, Map<String, dynamic> taskData) {
    // TODO: 필요하다면 여기에 추가적인 비즈니스 로직을 구현합니다.
    return _taskRepository.updateTask(id, taskData);
  }

  /// 특정 할 일을 삭제합니다.
  Future<int> deleteTask(int id) {
    // TODO: 필요하다면 여기에 추가적인 비즈니스 로직을 구현합니다.
    return _taskRepository.deleteTask(id);
  }

  /// 모든 할 일 목록을 가져옵니다.
  ///
  /// TODO: 실제 사용자 ID를 받도록 수정해야 합니다.
  Future<List<dynamic>> getTasks() {
    return _taskRepository.getTasks(userId: 1); // 임시로 userId 1 사용
  }
}
