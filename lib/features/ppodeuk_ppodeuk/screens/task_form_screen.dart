import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:template/features/ppodeuk_ppodeuk/controllers/space_controller.dart';
import 'package:template/features/ppodeuk_ppodeuk/controllers/task_controller.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/importance.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/period.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/task.dart';

/// 청소를 생성하거나 수정하는 폼 화면
class TaskFormScreen extends ConsumerStatefulWidget {
  /// [TaskFormScreen]을 생성합니다.
  ///
  /// [task]가 주어지면 해당 청소를 수정하는 모드로 동작합니다.
  const TaskFormScreen({super.key, this.task});

  /// 편집할 청소. 없으면 신규 생성 모드로 동작합니다.
  final Task? task;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late int _spaceId;
  late Importance _importance;
  late Period _period;
  DateTime? _startDate;

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _name = widget.task!.name;
      _spaceId = widget.task!.spaceId;
      _importance = widget.task!.importance;
      _period = widget.task!.period;
      _startDate = widget.task!.startDate;
    } else {
      _name = '';
      _spaceId = 1; // 기본값, 공간 로드 후 첫 번째 공간으로 설정됨
      _importance = Importance.normal;
      _period = Period.weekly;
      _startDate = DateTime.now(); // 기본값: 오늘
    }

    // 공간 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(spaceControllerProvider.notifier).loadSpaces().then((_) {
        // 공간 로드 완료 후 첫 번째 공간을 기본값으로 설정
        final spaceState = ref.read(spaceControllerProvider);
        if (spaceState.spaces.isNotEmpty && widget.task == null) {
          setState(() {
            _spaceId = int.parse(spaceState.spaces.first.id);
          });
        }
      });
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final taskController = ref.read(taskControllerProvider.notifier);

        if (widget.task == null) {
          // 새 청소 추가
          await taskController.createTask(
            name: _name,
            spaceId: _spaceId,
            importance: _importance,
            period: _period,
            startDate: _startDate,
          );
        } else {
          // 기존 청소 수정
          await taskController.updateTask(
            taskId: widget.task!.id,
            name: _name,
            spaceId: _spaceId,
            importance: _importance,
            period: _period,
            startDate: _startDate,
          );
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } on Exception catch (e) {
        if (mounted) {
          // 에러 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _delete() async {
    if (widget.task == null) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 청소를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final taskController = ref.read(taskControllerProvider.notifier);
        await taskController.deleteTask(widget.task!.id);

        if (mounted) {
          Navigator.pop(context);
        }
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today, // 오늘 이전 날짜 선택 불가
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskControllerProvider);
    final spaceState = ref.watch(spaceControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? '청소 추가' : '청소 수정'),
        actions: [
          if (widget.task != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: taskState.isLoading ? null : _delete,
            ),
          IconButton(
            icon: taskState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: taskState.isLoading ? null : _submit,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                enabled: !taskState.isLoading,
                decoration: const InputDecoration(labelText: '청소 이름'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '청소 이름을 입력하세요.';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: ValueKey<String>(
                  'space-${spaceState.spaces.isNotEmpty ? _spaceId : "empty"}',
                ),
                initialValue: spaceState.spaces.isNotEmpty ? _spaceId : null,
                decoration: InputDecoration(
                  labelText: '공간',
                  hintText: spaceState.isLoading
                      ? '공간 로딩 중...'
                      : spaceState.spaces.isEmpty
                      ? '공간이 없습니다'
                      : '공간을 선택하세요',
                ),
                items: spaceState.spaces.map((space) {
                  return DropdownMenuItem(
                    value: int.parse(space.id),
                    child: Text(space.name),
                  );
                }).toList(),
                onChanged:
                    (taskState.isLoading ||
                        spaceState.isLoading ||
                        spaceState.spaces.isEmpty)
                    ? null
                    : (value) {
                        setState(() {
                          _spaceId = value!;
                        });
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Importance>(
                key: ValueKey(_importance),
                initialValue: _importance,
                decoration: const InputDecoration(labelText: '중요도'),
                items: Importance.values.map((importance) {
                  return DropdownMenuItem(
                    value: importance,
                    child: Text(importance.displayName),
                  );
                }).toList(),
                onChanged: taskState.isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _importance = value!;
                        });
                      },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Period>(
                key: ValueKey(_period),
                initialValue: _period,
                decoration: const InputDecoration(labelText: '주기'),
                items: Period.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period.displayName),
                  );
                }).toList(),
                onChanged: taskState.isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _period = value!;
                        });
                      },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _startDate == null
                          ? '시작일 미설정'
                          : '시작일: ${_formatDate(_startDate!)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_calendar),
                    onPressed: taskState.isLoading
                        ? null
                        : () => _selectStartDate(context),
                    tooltip: '시작일 선택',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 날짜를 형식화합니다 (예: 2025.10.26)
  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
