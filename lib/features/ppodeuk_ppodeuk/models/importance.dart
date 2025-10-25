/// 할 일의 중요도를 나타내는 열거형
enum Importance {
  /// 매일 해야 하는 일
  daily,

  /// 보통 중요도
  normal,

  /// 중요한 일
  important;

  /// 중요도를 한글 문자열로 변환
  String get displayName {
    switch (this) {
      case Importance.daily:
        return '매일';
      case Importance.normal:
        return '보통';
      case Importance.important:
        return '중요';
    }
  }

  /// 문자열에서 Importance 열거형으로 변환
  static Importance fromString(String value) {
    switch (value) {
      case 'daily':
        return Importance.daily;
      case 'normal':
        return Importance.normal;
      case 'important':
        return Importance.important;
      default:
        throw ArgumentError('Invalid importance value: $value');
    }
  }
}
