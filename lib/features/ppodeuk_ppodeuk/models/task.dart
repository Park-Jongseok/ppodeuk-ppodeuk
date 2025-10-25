import 'package:template/features/ppodeuk_ppodeuk/models/importance.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/period.dart';

/// 할 일(Task) 데이터 모델
///
/// 데이터베이스의 'Tasks' 테이블과 매핑됩니다.
class Task {
  /// [Task] 생성자
  const Task({
    required this.id,
    required this.name,
    required this.spaceId,
    required this.importance,
    required this.period,
    this.assignedUserId,
    this.startDate,
    this.isCompleted = false,
    required this.createdAt,
  });

  /// JSON에서 Task 객체 생성
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      name: json['name'] as String,
      spaceId: json['space_id'] as int,
      assignedUserId: json['assigned_user_id'] as int?,
      importance: Importance.values[json['importance'] as int],
      period: Period.values[json['period'] as int],
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      isCompleted: (json['is_completed'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 고유 식별자
  final int id;

  /// 할 일 이름
  final String name;

  /// 소속된 공간 ID
  final int spaceId;

  /// 담당자 ID (선택적)
  final int? assignedUserId;

  /// 중요도
  final Importance importance;

  /// 주기
  final Period period;

  /// 시작일 (선택적)
  final DateTime? startDate;

  /// 완료 여부
  final bool isCompleted;

  /// 생성일
  final DateTime createdAt;

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'space_id': spaceId,
      'assigned_user_id': assignedUserId,
      'importance': importance.index,
      'period': period.index,
      'start_date': startDate?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 객체 복사 (일부 필드 변경)
  Task copyWith({
    String? name,
    int? spaceId,
    int? assignedUserId,
    Importance? importance,
    Period? period,
    DateTime? startDate,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return Task(
      id: id,
      name: name ?? this.name,
      spaceId: spaceId ?? this.spaceId,
      assignedUserId: assignedUserId ?? this.assignedUserId,
      importance: importance ?? this.importance,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
