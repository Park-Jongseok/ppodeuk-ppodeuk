import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template/core/themes/app_colors.dart';
import 'package:template/core/themes/app_typography.dart';
import 'package:template/features/ppodeuk_ppodeuk/controllers/space_controller.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/space.dart';
import 'package:template/features/ppodeuk_ppodeuk/services/score_service.dart';

/// 대시보드 화면
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _scoreService = ScoreService();
  Map<int, int> _calculatedScores = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAndCalculateScores();
    });
  }

  Future<void> _loadAndCalculateScores() async {
    await ref.read(spaceControllerProvider.notifier).loadSpaces();
    await _calculateAllScores();
  }

  Future<void> _calculateAllScores() async {
    final spaces = ref.read(spaceControllerProvider).spaces;
    final scores = <int, int>{};

    for (final space in spaces) {
      final spaceId = int.parse(space.id);
      final score = await _scoreService.calculateSpaceScore(spaceId);
      scores[spaceId] = score;
    }

    if (mounted) {
      setState(() {
        _calculatedScores = scores;
      });
    }
  }

  Future<void> _refreshSpaces() async {
    await _loadAndCalculateScores();
  }

  List<Space> _getSpacesWithCalculatedScores(List<Space> spaces) {
    return spaces.map((space) {
      final spaceId = int.parse(space.id);
      final calculatedScore = _calculatedScores[spaceId];
      if (calculatedScore != null) {
        return space.copyWith(score: calculatedScore);
      }
      return space;
    }).toList();
  }

  Color _getScoreColor(int score, AppColors colors) {
    if (score >= 80) {
      return colors.success;
    } else if (score >= 60) {
      return colors.warning;
    } else {
      return colors.error;
    }
  }

  String _getScoreLabel(int score) {
    if (score >= 80) {
      return '깨끗해요!';
    } else if (score >= 60) {
      return '괜찮아요';
    } else if (score >= 40) {
      return '청소 필요';
    } else {
      return '시급!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spaceState = ref.watch(spaceControllerProvider);

    // 점수 계산이 완료될 때까지 로딩 표시
    if ((spaceState.isLoading && spaceState.spaces.isEmpty) ||
        _calculatedScores.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (spaceState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colors.error),
              const SizedBox(height: 16),
              Text(
                '공간 목록을 불러오지 못했습니다.',
                style: AppTypography.body.copyWith(color: colors.error),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _refreshSpaces,
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    // 실시간 계산된 점수를 사용
    final spaces = _getSpacesWithCalculatedScores(spaceState.spaces);

    if (spaces.isEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home_outlined,
                size: 64,
                color: colors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                '아직 공간이 없어요.\n새로운 공간을 추가해보세요!',
                style: AppTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 점수 기준 정렬 (낮은 순)
    final sortedSpaces = [...spaces]..sort((a, b) => a.score.compareTo(b.score));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshSpaces,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '공간별 청결도',
                    style: AppTypography.heading.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '각 공간의 현재 청결도를 확인하세요',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // 공간 카드 목록
            ...sortedSpaces.map((space) {
              final scoreColor = _getScoreColor(space.score, colors);
              final scoreLabel = _getScoreLabel(space.score);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              space.name,
                              style: AppTypography.title.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: scoreColor, width: 1.5),
                            ),
                            child: Text(
                              scoreLabel,
                              style: AppTypography.caption.copyWith(
                                color: scoreColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: space.score / 100,
                                minHeight: 12,
                                backgroundColor: colors.textSecondary
                                    .withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation(scoreColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${space.score}점',
                            style: AppTypography.body.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
