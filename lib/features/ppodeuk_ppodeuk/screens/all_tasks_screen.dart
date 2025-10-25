import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template/core/controllers/user_controller.dart';
import 'package:template/core/repositories/task_repository.dart';
import 'package:template/core/themes/app_colors.dart';
import 'package:template/core/themes/app_typography.dart';
import 'package:template/features/ppodeuk_ppodeuk/controllers/space_controller.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/importance.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/space.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/task.dart';
import 'package:template/features/ppodeuk_ppodeuk/screens/task_form_screen.dart';
import 'package:template/features/ppodeuk_ppodeuk/widgets/task_tile.dart';

/// '전체 청소' 화면
class AllTasksScreen extends ConsumerStatefulWidget {
  const AllTasksScreen({super.key});

  @override
  ConsumerState<AllTasksScreen> createState() => _AllTasksScreenState();
}

class _AllTasksScreenState extends ConsumerState<AllTasksScreen> {
  final _taskRepository = TaskRepository();
  late Future<List<Task>> _tasksFuture;
  _AllTasksSortOption _sortOption = _AllTasksSortOption.startDate;

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
    return _taskRepository.getTasks(
      userId: defaultUserId,
      includeCompleted: true,
    );
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

            final tasks = snapshot.data ?? [];
            if (tasks.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSortChips(colors),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      '등록된 청소가 없습니다.\n+ 버튼을 눌러 새로운 청소를 추가해보세요!',
                      style: AppTypography.body.copyWith(
                        color: colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              );
            }

            final spacesById = {
              for (final space in spaceState.spaces) int.parse(space.id): space,
            };

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSortChips(colors),
                const SizedBox(height: 16),
                ..._buildTaskContent(tasks, spacesById),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'allTasksFab',
        onPressed: () => _navigateToTaskForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSortChips(AppColors colors) {
    return Wrap(
      spacing: 8,
      children: _AllTasksSortOption.values.map((option) {
        final selected = option == _sortOption;
        return ChoiceChip(
          label: Text(_labelForOption(option)),
          selected: selected,
          onSelected: (value) {
            if (value) {
              setState(() {
                _sortOption = option;
              });
            }
          },
          selectedColor: colors.primary.withValues(alpha: 0.15),
          labelStyle: AppTypography.caption.copyWith(
            color: selected ? colors.primary : colors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildTaskContent(
    List<Task> tasks,
    Map<int, Space> spacesById,
  ) {
    switch (_sortOption) {
      case _AllTasksSortOption.startDate:
        final sorted = [...tasks]..sort(_startDateComparator);
        return _buildFlatTaskList(sorted, spacesById);
      case _AllTasksSortOption.importance:
        final sorted = [...tasks]..sort(_importanceComparator);
        return _buildFlatTaskList(sorted, spacesById);
      case _AllTasksSortOption.space:
        return _buildGroupedBySpace(tasks, spacesById);
    }
  }

  List<Widget> _buildFlatTaskList(
    List<Task> tasks,
    Map<int, Space> spacesById,
  ) {
    return tasks.map((task) {
      final space = spacesById[task.spaceId] ?? kUnknownSpace;
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: TaskListTile(
          task: task,
          space: space,
          onEdit: () => _navigateToTaskForm(task),
          showCompletionControl: false,
        ),
      );
    }).toList();
  }

  List<Widget> _buildGroupedBySpace(
    List<Task> tasks,
    Map<int, Space> spacesById,
  ) {
    final colors = context.colors;
    final Map<int, List<Task>> grouped = {};
    for (final task in tasks) {
      grouped.putIfAbsent(task.spaceId, () => []).add(task);
    }

    final sortedSpaceIds = grouped.keys.toList()
      ..sort((a, b) {
        final spaceA = spacesById[a] ?? kUnknownSpace;
        final spaceB = spacesById[b] ?? kUnknownSpace;
        return spaceA.name.compareTo(spaceB.name);
      });

    return sortedSpaceIds.map((spaceId) {
      final space = spacesById[spaceId] ?? kUnknownSpace;
      final spaceTasks = grouped[spaceId]!..sort(_startDateComparator);
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
                color: colors.primary.withValues(
                  alpha: spaceTasks.any((task) => !task.isCompleted)
                      ? 0.05
                      : 0.08,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.space_dashboard, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    space.name,
                    style: AppTypography.title,
                  ),
                  const Spacer(),
                  Text(
                    '${spaceTasks.length}개',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                for (var i = 0; i < spaceTasks.length; i++)
                  TaskListTile(
                    task: spaceTasks[i],
                    space: space,
                    onEdit: () => _navigateToTaskForm(spaceTasks[i]),
                    showCompletionControl: false,
                    showBottomDivider: i != spaceTasks.length - 1,
                  ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  String _labelForOption(_AllTasksSortOption option) {
    switch (option) {
      case _AllTasksSortOption.startDate:
        return '시작일순';
      case _AllTasksSortOption.importance:
        return '중요도순';
      case _AllTasksSortOption.space:
        return '공간별';
    }
  }

  int _startDateComparator(Task a, Task b) {
    final completionResult = _compareCompletion(a, b);
    if (completionResult != 0) {
      return completionResult;
    }

    final dateA = a.startDate;
    final dateB = b.startDate;

    if (dateA == null && dateB == null) {
      return a.name.compareTo(b.name);
    } else if (dateA == null) {
      return 1;
    } else if (dateB == null) {
      return -1;
    }

    final result = dateA.compareTo(dateB);
    if (result != 0) {
      return result;
    }
    return a.name.compareTo(b.name);
  }

  int _importanceComparator(Task a, Task b) {
    final completionResult = _compareCompletion(a, b);
    if (completionResult != 0) {
      return completionResult;
    }

    final weight = {
      Importance.important: 0,
      Importance.normal: 1,
      Importance.daily: 2,
    };

    final result = weight[a.importance]!.compareTo(weight[b.importance]!);
    if (result != 0) {
      return result;
    }
    return _startDateComparator(a, b);
  }

  int _compareCompletion(Task a, Task b) {
    if (a.isCompleted == b.isCompleted) {
      return 0;
    }
    return a.isCompleted ? 1 : -1;
  }
}

enum _AllTasksSortOption { startDate, importance, space }
