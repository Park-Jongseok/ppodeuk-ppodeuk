import 'package:template/features/ppodeuk_ppodeuk/models/importance.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/period.dart';

/// 할 일(Todo) 데이터 모델
///
/// 사용자가 생성한 할 일을 나타냅니다.
/// 각 할 일은 공간에 속하며, 중요도, 주기, 마감일, 완료 상태를 가집니다.
class Todo {
  /// [Todo] 생성자
  const Todo({
    required this.id,
    required this.name,
    required this.spaceId,
    required this.importance,
    required this.period,
    this.dueDate,
    this.isCompleted = false,
  });

  /// JSON에서 Todo 객체 생성
  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      name: json['name'] as String,
      spaceId: json['spaceId'] as String,
      importance: Importance.fromString(json['importance'] as String),
      period: Period.fromString(json['period'] as String),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  /// 고유 식별자
  final String id;

  /// 할 일 이름
  final String name;

  /// 소속된 공간 ID
  final String spaceId;

  /// 중요도
  final Importance importance;

  /// 주기
  final Period period;

  /// 마감일 (선택적)
  final DateTime? dueDate;

  /// 완료 여부
  final bool isCompleted;

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'spaceId': spaceId,
      'importance': importance.name,
      'period': period.name,
      'dueDate': dueDate?.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  /// 객체 복사 (일부 필드 변경)
  ///
  /// id는 고유 식별자이므로 변경할 수 없습니다.
  Todo copyWith({
    String? name,
    String? spaceId,
    Importance? importance,
    Period? period,
    DateTime? dueDate,
    bool? isCompleted,
  }) {
    return Todo(
      id: id,
      name: name ?? this.name,
      spaceId: spaceId ?? this.spaceId,
      importance: importance ?? this.importance,
      period: period ?? this.period,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Todo &&
        other.id == id &&
        other.name == name &&
        other.spaceId == spaceId &&
        other.importance == importance &&
        other.period == period &&
        other.dueDate == dueDate &&
        other.isCompleted == isCompleted;
  }

  @override
  int get hashCode => Object.hash(id, name, spaceId, importance, period, dueDate, isCompleted);

  @override
  String toString() {
    return 'Todo(id: $id, name: $name, spaceId: $spaceId, importance: $importance, period: $period, dueDate: $dueDate, isCompleted: $isCompleted)';
  }
}
