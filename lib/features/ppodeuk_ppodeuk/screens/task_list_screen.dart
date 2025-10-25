import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template/core/controllers/user_controller.dart';
import 'package:template/core/repositories/task_repository.dart';
import 'package:template/core/themes/app_colors.dart';
import 'package:template/core/themes/app_typography.dart';
import 'package:template/features/ppodeuk_ppodeuk/controllers/space_controller.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/space.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/task.dart';
import 'package:template/features/ppodeuk_ppodeuk/screens/task_form_screen.dart';

/// 공간별 청소 목록 화면
class TaskListScreen extends ConsumerStatefulWidget {
  /// [TaskListScreen] 생성자
  const TaskListScreen({super.key});

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _taskRepository = TaskRepository();

  @override
  void initState() {
    super.initState();
    // 화면 로드 시 공간 목록 가져오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spaceControllerProvider.notifier).loadSpaces();
    });
  }

  void _navigateToTaskForm([Task? task]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    ).then((_) {
      // 돌아온 후 공간 목록 새로고침 (점수 업데이트 반영)
      ref.read(spaceControllerProvider.notifier).loadSpaces();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spaceState = ref.watch(spaceControllerProvider);
    final defaultUserIdAsync = ref.watch(defaultUserIdProvider);

    // 기본 사용자 ID 로딩 중 또는 오류
    return defaultUserIdAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(
          child: Text(
            '사용자 정보를 불러올 수 없습니다: $error',
            style: AppTypography.body.copyWith(color: colors.error),
          ),
        ),
      ),
      data: (defaultUserId) {
        if (spaceState.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (spaceState.error != null) {
          return Scaffold(
            body: Center(
              child: Text(
                '오류: ${spaceState.error}',
                style: AppTypography.body.copyWith(color: colors.error),
              ),
            ),
          );
        }

        if (spaceState.spaces.isEmpty) {
          return Scaffold(
            body: Center(
              child: Text(
                '공간이 없습니다.\n공간을 먼저 생성해주세요.',
                style: AppTypography.body.copyWith(color: colors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _navigateToTaskForm,
              child: const Icon(Icons.add),
            ),
          );
        }

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              await ref.read(spaceControllerProvider.notifier).loadSpaces();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: spaceState.spaces.length,
              itemBuilder: (context, index) {
                final space = spaceState.spaces[index];
                return _SpaceCategoryCard(
                  space: space,
                  taskRepository: _taskRepository,
                  defaultUserId: defaultUserId,
                  onTaskTap: _navigateToTaskForm,
                );
              },
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _navigateToTaskForm,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

/// 공간별 카테고리 카드 위젯
class _SpaceCategoryCard extends StatelessWidget {
  const _SpaceCategoryCard({
    required this.space,
    required this.taskRepository,
    required this.defaultUserId,
    required this.onTaskTap,
  });

  final Space space;
  final TaskRepository taskRepository;
  final int defaultUserId;
  final void Function(Task) onTaskTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 공간 헤더 (이름 + 점수)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  space.name,
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getScoreColor(space.score, colors),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '남은 점수',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${space.score}점',
                        style: AppTypography.title.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 할 일 목록
          FutureBuilder<List<Task>>(
            future: taskRepository.getTasks(
              userId: defaultUserId,
              spaceId: int.parse(space.id),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '할 일을 불러오는 중 오류가 발생했습니다.',
                    style: AppTypography.caption.copyWith(
                      color: colors.error,
                    ),
                  ),
                );
              }

              final tasks = snapshot.data ?? [];

              if (tasks.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '이 공간에 할 일이 없습니다.',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                );
              }

              return Column(
                children: tasks.map((task) {
                  return ListTile(
                    leading: Checkbox(
                      value: task.isCompleted,
                      // TODO(feature): 완료 상태 토글 기능 추가
                      onChanged: (_) {},
                    ),
                    title: Text(
                      task.name,
                      style: AppTypography.body.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? colors.textSecondary
                            : colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      '중요도: ${task.importance.displayName} | 주기: ${task.period.displayName}',
                      style: AppTypography.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => onTaskTap(task),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 점수에 따른 배지 색상 반환
  Color _getScoreColor(int score, AppColors colors) {
    if (score >= 80) {
      return colors.success;
    } else if (score >= 50) {
      return colors.warning;
    } else {
      return colors.error;
    }
  }
}
