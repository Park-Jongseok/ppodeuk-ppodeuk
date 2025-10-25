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
      setState(() {}); // 할 일 목록도 새로고침
    });
  }

  /// 할 일을 날짜별로 그룹핑
  Map<String, List<Task>> _groupTasksByDate(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final overdueTasks = <Task>[];
    final todayTasks = <Task>[];
    final upcomingTasks = <Task>[];
    final noDueDateTasks = <Task>[];

    for (final task in tasks) {
      if (task.isCompleted) {
        continue; // 완료된 할 일은 제외
      }

      final createdDate = DateTime(
        task.createdAt.year,
        task.createdAt.month,
        task.createdAt.day,
      );

      if (task.includeToday && createdDate.isAtSameMomentAs(today)) {
        todayTasks.add(task);
        continue;
      }

      if (task.dueDate == null) {
        noDueDateTasks.add(task);
      } else {
        final dueDate = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );

        if (dueDate.isBefore(today)) {
          overdueTasks.add(task);
        } else if (dueDate.isAtSameMomentAs(today)) {
          todayTasks.add(task);
        } else {
          upcomingTasks.add(task);
        }
      }
    }

    return {
      'overdue': overdueTasks,
      'today': todayTasks,
      'upcoming': upcomingTasks,
      'noDueDate': noDueDateTasks,
    };
  }

  /// 공간별로 할 일 그룹핑
  Map<int, List<Task>> _groupTasksBySpace(List<Task> tasks) {
    final grouped = <int, List<Task>>{};
    for (final task in tasks) {
      grouped.putIfAbsent(task.spaceId, () => []).add(task);
    }
    return grouped;
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
              setState(() {}); // 화면 새로고침
            },
            child: FutureBuilder<List<Task>>(
              future: _taskRepository.getTasks(userId: defaultUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '할 일을 불러오는 중 오류가 발생했습니다.',
                      style: AppTypography.body.copyWith(color: colors.error),
                    ),
                  );
                }

                final allTasks = snapshot.data ?? [];
                final groupedByDate = _groupTasksByDate(allTasks);
                final groupedBySpace = _groupTasksBySpace(allTasks);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 기한이 지난 할 일
                    if (groupedByDate['overdue']!.isNotEmpty)
                      _TaskSection(
                        title: '기한이 지난 할 일',
                        icon: Icons.warning_amber_rounded,
                        iconColor: colors.error,
                        tasks: groupedByDate['overdue']!,
                        spaces: spaceState.spaces,
                        onTaskTap: _navigateToTaskForm,
                      ),

                    // 오늘 해야할 일
                    if (groupedByDate['today']!.isNotEmpty)
                      _TaskSection(
                        title: '오늘 해야할 일',
                        icon: Icons.today,
                        iconColor: colors.warning,
                        tasks: groupedByDate['today']!,
                        spaces: spaceState.spaces,
                        onTaskTap: _navigateToTaskForm,
                      ),

                    // 예정된 할 일
                    if (groupedByDate['upcoming']!.isNotEmpty)
                      _TaskSection(
                        title: '예정된 할 일',
                        icon: Icons.calendar_today,
                        iconColor: colors.primary,
                        tasks: groupedByDate['upcoming']!,
                        spaces: spaceState.spaces,
                        onTaskTap: _navigateToTaskForm,
                      ),

                    // 공간별 할 일
                    if (groupedBySpace.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 24, bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.space_dashboard,
                              size: 20,
                              color: colors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '공간별 할 일',
                              style: AppTypography.title.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...spaceState.spaces.map((space) {
                        final spaceTasks =
                            groupedBySpace[int.parse(space.id)] ?? [];
                        if (spaceTasks.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _SpaceCategoryCard(
                          space: space,
                          tasks: spaceTasks,
                          onTaskTap: _navigateToTaskForm,
                        );
                      }),
                    ],

                    // 모든 할 일이 없을 때
                    if (allTasks.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            '등록된 할 일이 없습니다.\n+ 버튼을 눌러 할 일을 추가해보세요!',
                            style: AppTypography.body.copyWith(
                              color: colors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
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

/// 날짜별 할 일 섹션 위젯
class _TaskSection extends StatelessWidget {
  const _TaskSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.tasks,
    required this.spaces,
    required this.onTaskTap,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Task> tasks;
  final List<Space> spaces;
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
          // 섹션 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTypography.title.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}개',
                    style: AppTypography.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 할 일 목록
          Column(
            children: tasks.map((task) {
              final space = spaces.firstWhere(
                (s) => int.parse(s.id) == task.spaceId,
                orElse: () => const Space(
                  id: '0',
                  name: '알 수 없음',
                  score: 0,
                ),
              );

              return _TaskListTile(
                task: task,
                space: space,
                onTaskTap: onTaskTap,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 할 일 리스트 타일 위젯
class _TaskListTile extends StatelessWidget {
  const _TaskListTile({
    required this.task,
    required this.space,
    required this.onTaskTap,
  });

  final Task task;
  final Space space;
  final void Function(Task) onTaskTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListTile(
      leading: Checkbox(
        value: task.isCompleted,
        // TODO(feature): 완료 상태 토글 기능 추가
        onChanged: (_) {},
      ),
      title: Text(
        task.name,
        style: AppTypography.body.copyWith(
          decoration:
              task.isCompleted ? TextDecoration.lineThrough : null,
          color: task.isCompleted
              ? colors.textSecondary
              : colors.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            '📍 ${space.name}',
            style: AppTypography.caption.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                '중요도: ${task.importance.displayName}',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '주기: ${task.period.displayName}',
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          if (task.dueDate != null) ...[
            const SizedBox(height: 2),
            Text(
              '마감: ${_formatDate(task.dueDate!)}',
              style: AppTypography.caption.copyWith(
                color: _isOverdue(task.dueDate!)
                    ? colors.error
                    : colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        onPressed: () => onTaskTap(task),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return '오늘';
    } else if (targetDate == today.add(const Duration(days: 1))) {
      return '내일';
    } else if (targetDate == today.subtract(const Duration(days: 1))) {
      return '어제';
    } else {
      return '${date.month}월 ${date.day}일';
    }
  }

  bool _isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return targetDate.isBefore(today);
  }
}

/// 공간별 카테고리 카드 위젯
class _SpaceCategoryCard extends StatelessWidget {
  const _SpaceCategoryCard({
    required this.space,
    required this.tasks,
    required this.onTaskTap,
  });

  final Space space;
  final List<Task> tasks;
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
                        '현재 점수',
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
          Column(
            children: tasks.map((task) {
              return _TaskListTile(
                task: task,
                space: space,
                onTaskTap: onTaskTap,
              );
            }).toList(),
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
