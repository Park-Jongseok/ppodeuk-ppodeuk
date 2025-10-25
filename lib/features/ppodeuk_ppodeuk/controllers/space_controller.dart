import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template/core/controllers/user_controller.dart';
import 'package:template/core/repositories/space_repository.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/space.dart';

/// 공간 컨트롤러 프로바이더
final spaceControllerProvider =
    NotifierProvider<SpaceController, SpaceControllerState>(
      SpaceController.new,
    );

/// 공간 컨트롤러 상태
class SpaceControllerState {
  const SpaceControllerState({
    this.spaces = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Space> spaces;
  final bool isLoading;
  final String? error;

  SpaceControllerState copyWith({
    List<Space>? spaces,
    bool? isLoading,
    String? error,
  }) {
    return SpaceControllerState(
      spaces: spaces ?? this.spaces,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 공간 관리 컨트롤러
class SpaceController extends Notifier<SpaceControllerState> {
  late final SpaceRepository _spaceRepository;

  @override
  SpaceControllerState build() {
    _spaceRepository = SpaceRepository();
    return const SpaceControllerState();
  }

  /// 공간 목록 로드
  Future<void> loadSpaces() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Provider를 통해 기본 사용자 ID를 가져옴
      final defaultUserId = await ref.read(defaultUserIdProvider.future);
      final spacesData = await _spaceRepository.getSpacesForUser(defaultUserId);
      final spaces = spacesData.map((data) => Space.fromJson(data)).toList();
      state = state.copyWith(spaces: spaces, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 새 공간 생성
  Future<void> createSpace({
    required String name,
    int score = 100,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final spaceData = {
        'name': name,
        'score': score,
      };

      await _spaceRepository.createSpace(spaceData);

      // 공간 목록 새로고침
      await loadSpaces();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 공간 점수 업데이트
  Future<void> updateSpaceScore(int spaceId, int score) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _spaceRepository.updateSpaceScore(spaceId, score);

      // 공간 목록 새로고침
      await loadSpaces();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 공간 삭제
  Future<void> deleteSpace(int spaceId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _spaceRepository.deleteSpace(spaceId);

      // 공간 목록 새로고침
      await loadSpaces();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// 에러 상태 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }
}
