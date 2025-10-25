import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template/core/controllers/user_controller.dart';
import 'package:template/core/repositories/task_repository.dart';
import 'package:template/core/themes/app_colors.dart';
import 'package:template/core/themes/app_typography.dart';
import 'package:template/features/ppodeuk_ppodeuk/controllers/space_controller.dart';
import 'package:template/features/ppodeuk_ppodeuk/controllers/task_controller.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/space.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/task.dart';
import 'package:template/features/ppodeuk_ppodeuk/screens/task_form_screen.dart';
import 'package:template/features/ppodeuk_ppodeuk/widgets/task_tile.dart';

/// '오늘의 청소' 화면
class TodayTasksScreen extends ConsumerStatefulWidget {
  const TodayTasksScreen({super.key});

  @override
  ConsumerState<TodayTasksScreen> createState() => _TodayTasksScreenState();
}

class _TodayTasksScreenState extends ConsumerState<TodayTasksScreen> {
  final _taskRepository = TaskRepository();
  final _updatingTaskIds = <int>{};
  late Future<List<Task>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _fetchTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spaceControllerProvider.notifier).loadSpaces();
    });
  }

  Future<List<Task>> _fetchTasks() async {
    final defaultUserId = await ref.read(defaultUserIdProvider.future);
    return _taskRepository.getTasks(userId: defaultUserId);
  }

  Future<void> _refreshTasks() async {
    final future = _fetchTasks();
    if (mounted) {
      setState(() {
        _tasksFuture = future;
      });
    }
    await future;
  }

  Future<bool> _confirmCompletion(Task task) async {
    if (!mounted) return false;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('청소 완료 확인'),
          content: Text('오늘의 청소 "${task.name}"을(를) 완료했나요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('완료'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _handleCompletionChanged(Task task, bool? value) async {
    if (value == null) return;
    if (value && !(await _confirmCompletion(task))) {
      return;
    }
    setState(() {
      _updatingTaskIds.add(task.id);
    });

    try {
      await ref
          .read(taskControllerProvider.notifier)
          .setTaskCompletion(
            taskId: task.id,
            isCompleted: value,
          );
      await _refreshTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('청소 완료 상태를 변경하지 못했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingTaskIds.remove(task.id);
        });
      }
    }
  }

  Future<void> _navigateToTaskForm([Task? task]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );
    if (!mounted) return;
    await _refreshTasks();
    await ref.read(spaceControllerProvider.notifier).loadSpaces();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spaceState = ref.watch(spaceControllerProvider);

    // taskControllerProvider의 변경 사항을 감지하여 자동 새로고침
    ref.listen<TaskControllerState>(
      taskControllerProvider,
      (previous, next) {
        if (previous?.tasks != next.tasks) {
          _refreshTasks();
        }
      },
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(spaceControllerProvider.notifier).loadSpaces();
          await _refreshTasks();
        },
        child: FutureBuilder<List<Task>>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  '청소 목록을 불러오지 못했습니다.\n다시 시도해주세요.',
                  style: AppTypography.body.copyWith(
                    color: colors.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final allTasks = snapshot.data ?? [];
            final groupedTasks = _partitionTasks(allTasks);
            final overdueTasks = groupedTasks[_TodayCategory.overdue]!;
            final todayTasks = groupedTasks[_TodayCategory.today]!;

            final spacesById = {
              for (final space in spaceState.spaces) int.parse(space.id): space,
            };

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSection(
                  context: context,
                  title: '기한이 지난 청소',
                  icon: Icons.warning_amber_rounded,
                  color: colors.error,
                  tasks: overdueTasks,
                  spacesById: spacesById,
                ),
                _buildSection(
                  context: context,
                  title: '오늘 해야 할 청소',
                  icon: Icons.today,
                  color: colors.warning,
                  tasks: todayTasks,
                  spacesById: spacesById,
                ),
                if (overdueTasks.isEmpty && todayTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: colors.success,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '오늘은 해야 할 청소가 없어요!\n새로운 청소를 추가해보세요.',
                          style: AppTypography.body.copyWith(
                            color: colors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<_TodayCategory, List<Task>> _partitionTasks(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final map = {
      _TodayCategory.overdue: <Task>[],
      _TodayCategory.today: <Task>[],
    };

    for (final task in tasks) {
      if (task.isCompleted) {
        continue;
      }

      // 시작일이 없으면 무시
      if (task.startDate == null) {
        continue;
      }

      final startDate = DateTime(
        task.startDate!.year,
        task.startDate!.month,
        task.startDate!.day,
      );

      // 시작일이 오늘 이전이면 기한 지남
      if (startDate.isBefore(today)) {
        map[_TodayCategory.overdue]!.add(task);
        continue;
      }

      // 시작일이 오늘이면 오늘 해야 할 청소
      if (startDate.isAtSameMomentAs(today)) {
        map[_TodayCategory.today]!.add(task);
        continue;
      }
    }

    int compareByDate(Task a, Task b) {
      final aDate = a.startDate ?? a.createdAt;
      final bDate = b.startDate ?? b.createdAt;
      final normalizedA = DateTime(aDate.year, aDate.month, aDate.day);
      final normalizedB = DateTime(bDate.year, bDate.month, bDate.day);
      return normalizedA.compareTo(normalizedB);
    }

    map[_TodayCategory.overdue]!.sort(compareByDate);
    map[_TodayCategory.today]!.sort(compareByDate);

    return map;
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required List<Task> tasks,
    required Map<int, Space> spacesById,
  }) {
    final colors = context.colors;

    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
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
                    color: color,
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
          Column(
            children: [
              for (var i = 0; i < tasks.length; i++)
                TaskListTile(
                  task: tasks[i],
                  space: spacesById[tasks[i].spaceId] ?? kUnknownSpace,
                  isUpdating: _updatingTaskIds.contains(tasks[i].id),
                  onCompletionChanged: (value) =>
                      _handleCompletionChanged(tasks[i], value),
                  showBottomDivider: i != tasks.length - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _TodayCategory { overdue, today }
