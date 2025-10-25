/// 뽀득뽀득 항목 모델
class Ppodeuk {
  /// 뽀득뽀득 생성자
  const Ppodeuk({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  /// 고유 식별자
  final String id;

  /// 제목
  final String title;

  /// 완료 여부
  final bool isDone;

  /// 완료 상태를 토글한 새로운 뽀득뽀득 반환
  Ppodeuk toggle() => Ppodeuk(
        id: id,
        title: title,
        isDone: !isDone,
      );

  /// 제목을 업데이트한 새로운 뽀득뽀득 반환
  Ppodeuk copyWith({
    String? id,
    String? title,
    bool? isDone,
  }) =>
      Ppodeuk(
        id: id ?? this.id,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
      );
}
