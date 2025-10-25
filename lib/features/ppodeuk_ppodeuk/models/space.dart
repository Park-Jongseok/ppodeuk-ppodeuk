/// 공간(Space) 데이터 모델
///
/// 사용자가 생성한 공간을 나타냅니다.
/// 각 공간은 고유 ID, 이름, 점수를 가집니다.
class Space {
  /// [Space] 생성자
  const Space({
    required this.id,
    required this.name,
    required this.score,
  });

  /// JSON에서 Space 객체 생성
  factory Space.fromJson(Map<String, dynamic> json) {
    return Space(
      id: json['id'] as String,
      name: json['name'] as String,
      score: (json['score'] as num?)?.toInt() ?? 0,
    );
  }

  /// 고유 식별자
  final String id;

  /// 공간 이름
  final String name;

  /// 공간 점수
  final int score;

  /// Space 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'score': score,
    };
  }

  /// Space 객체 복사 (일부 필드 변경)
  ///
  /// id는 고유 식별자이므로 변경할 수 없습니다.
  Space copyWith({
    String? name,
    int? score,
  }) {
    return Space(
      id: id,
      name: name ?? this.name,
      score: score ?? this.score,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Space && other.id == id && other.name == name && other.score == score;
  }

  @override
  int get hashCode => Object.hash(id, name, score);

  @override
  String toString() => 'Space(id: $id, name: $name, score: $score)';
}
