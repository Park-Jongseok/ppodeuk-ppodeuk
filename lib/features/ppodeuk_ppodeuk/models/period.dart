/// 할 일의 주기를 나타내는 열거형
enum Period {
  /// 주간 단위
  weekly,

  /// 월간 단위
  monthly;

  /// 주기를 한글 문자열로 변환
  String get displayName {
    switch (this) {
      case Period.weekly:
        return '주간';
      case Period.monthly:
        return '월간';
    }
  }

  /// 문자열에서 Period 열거형으로 변환
  static Period fromString(String value) {
    switch (value) {
      case 'weekly':
        return Period.weekly;
      case 'monthly':
        return Period.monthly;
      default:
        throw ArgumentError('Invalid period value: $value');
    }
  }
}
