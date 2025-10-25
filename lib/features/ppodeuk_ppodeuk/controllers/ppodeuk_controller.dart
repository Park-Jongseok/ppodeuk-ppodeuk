import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:template/features/ppodeuk_ppodeuk/models/ppodeuk.dart';

/// 뽀득뽀득 리스트 상태 관리
final ppodeukControllerProvider =
    NotifierProvider<PpodeukController, List<Ppodeuk>>(
  PpodeukController.new,
);

/// 뽀득뽀득 리스트 컨트롤러
class PpodeukController extends Notifier<List<Ppodeuk>> {
  @override
  List<Ppodeuk> build() {
    return [
      const Ppodeuk(
        id: '1',
        title: '첫 번째 뽀득뽀득',
        isDone: false,
      ),
      const Ppodeuk(
        id: '2',
        title: '두 번째 뽀득뽀득',
        isDone: true,
      ),
    ];
  }

  /// 뽀득뽀득 추가
  void addPpodeuk(String title) {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newPpodeuk = Ppodeuk(
      id: newId,
      title: title,
      isDone: false,
    );
    state = [...state, newPpodeuk];
  }

  /// 뽀득뽀득 완료 토글
  void togglePpodeuk(String id) {
    state = [
      for (final ppodeuk in state)
        if (ppodeuk.id == id) ppodeuk.toggle() else ppodeuk,
    ];
  }

  /// 뽀득뽀득 삭제
  void removePpodeuk(String id) {
    state = state.where((ppodeuk) => ppodeuk.id != id).toList();
  }

  /// 뽀득뽀득 수정
  void updatePpodeuk(String id, String newTitle) {
    state = [
      for (final ppodeuk in state)
        if (ppodeuk.id == id) ppodeuk.copyWith(title: newTitle) else ppodeuk,
    ];
  }
}
