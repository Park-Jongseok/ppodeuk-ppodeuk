import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template/core/database/database_helper.dart';

/// 기본 사용자 ID 프로바이더
///
/// MVP에서는 단일 사용자를 가정하므로, 앱 시작 시 한 번만 로드하여
/// 전역에서 사용할 수 있도록 제공합니다.
final defaultUserIdProvider = FutureProvider<int>((ref) {
  final databaseHelper = DatabaseHelper.instance;
  return databaseHelper.getDefaultUserId();
});
