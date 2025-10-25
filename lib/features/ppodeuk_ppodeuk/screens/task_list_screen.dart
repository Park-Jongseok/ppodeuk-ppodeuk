import 'package:flutter/material.dart';
import 'package:template/features/ppodeuk_ppodeuk/models/task.dart';
import 'package:template/features/ppodeuk_ppodeuk/screens/task_form_screen.dart';
import 'package:template/features/ppodeuk_ppodeuk/services/task_service.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TaskService _taskService = TaskService();
  late Future<List<Task>> _tasks;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() {
    setState(() {
      _tasks = _taskService.getTasks().then((value) => value.cast<Task>());
    });
  }

  void _navigateToTaskForm([Task? task]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    ).then((_) => _loadTasks());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Task>>(
        future: _tasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('오류: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('할 일이 없습니다.'));
          }

          final tasks = snapshot.data!;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task.name),
                subtitle: Text('중요도: ${task.importance.displayName}'),
                onTap: () => _navigateToTaskForm(task),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToTaskForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
