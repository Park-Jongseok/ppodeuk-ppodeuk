import 'package:flutter/material.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/importance.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/period.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/space.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/task.dart';
import 'package:template/features/ppodeuk_ppodeuk/services/task_service.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _taskService = TaskService();

  late String _name;
  late int _spaceId;
  late Importance _importance;
  late Period _period;
  DateTime? _dueDate;

  // 임시 데이터
  final List<Space> _spaces = [
    const Space(id: '1', name: '집', score: 100),
    const Space(id: '2', name: '회사', score: 200),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.task != null) {
      _name = widget.task!.name;
      _spaceId = widget.task!.spaceId;
      _importance = widget.task!.importance;
      _period = widget.task!.period;
      _dueDate = widget.task!.dueDate;
    } else {
      _name = '';
      _spaceId = int.parse(_spaces.first.id);
      _importance = Importance.normal;
      _period = Period.weekly;
      _dueDate = null;
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final taskData = {
        'name': _name,
        'space_id': _spaceId,
        'importance': _importance.index,
        'period': _period.index,
        'due_date': _dueDate?.toIso8601String(),
      };

      if (widget.task == null) {
        // 새 할 일 추가
        await _taskService.createTask(taskData);
      } else {
        // 기존 할 일 수정
        await _taskService.updateTask(widget.task!.id, taskData);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _delete() async {
    if (widget.task == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말로 이 할 일을 삭제하시겠습니까?'),
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
      await _taskService.deleteTask(widget.task!.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? '할 일 추가' : '할 일 수정'),
        actions: [
          if (widget.task != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submit,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: '할 일 이름'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '할 일 이름을 입력하세요.';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _spaceId,
                decoration: const InputDecoration(labelText: '공간'),
                items: _spaces.map((space) {
                  return DropdownMenuItem(
                    value: int.parse(space.id),
                    child: Text(space.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _spaceId = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Importance>(
                value: _importance,
                decoration: const InputDecoration(labelText: '중요도'),
                items: Importance.values.map((importance) {
                  return DropdownMenuItem(
                    value: importance,
                    child: Text(importance.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _importance = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Period>(
                value: _period,
                decoration: const InputDecoration(labelText: '주기'),
                items: Period.values.map((period) {
                  return DropdownMenuItem(
                    value: period,
                    child: Text(period.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _period = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _dueDate == null
                          ? '마감일 미설정'
                          : '마감일: ${_dueDate!.toLocal()}'.split(' ')[0],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectDueDate(context),
                    child: const Text('선택'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
