import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:intl/intl.dart';

void main() => runApp(ToDoListApp());

class ToDoListApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ToDoListScreen(),
    );
  }
}

class ToDoListScreen extends StatefulWidget {
  @override
  _ToDoListScreenState createState() => _ToDoListScreenState();
}

class _ToDoListScreenState extends State<ToDoListScreen> {
  List<TaskModel> todoList = [];
  TextEditingController taskController = TextEditingController();

  Future<void> loadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['md'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String contents = await file.readAsString();
        List<String> tasks = _extractTasksFromMd(contents);
        setState(() {
          todoList = tasks
              .map((task) => TaskModel(title: task, isCompleted: false))
              .toList();
        });
      }
    } catch (e) {
      print("Error selecting file: $e");
    }
  }

  List<String> _extractTasksFromMd(String contents) {
    List<String> tasks = [];
    List<String> lines = contents.split('\n');
    for (String line in lines) {
      if (line.trim().startsWith('-')) {
        tasks.add(line.trim().substring(1).trim());
      }
    }
    return tasks;
  }

  int _getTotalTasks() {
    return todoList.length;
  }

  int _getCompletedTasks() {
    return todoList.where((task) => task.isCompleted).length;
  }

  int _getWaitingTasks() {
    return todoList.where((task) => !task.isCompleted).length;
  }

  void _addTask(String task) {
    setState(() {
      todoList.add(TaskModel(title: task, isCompleted: false));
    });
    taskController.clear();
  }

  void _clearCompletedTasks() {
    setState(() {
      todoList.removeWhere((task) => task.isCompleted);
    });
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMMM d, y').format(date);
  }

  Widget _buildTaskTile(TaskModel task) {
    String taskText = _highlightTime(task.title);

    return ListTile(
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: (value) => _onTaskComplete(task, value),
      ),
      title: Text(
        taskText,
        style: task.isCompleted
            ? TextStyle(
                decoration: TextDecoration.lineThrough, color: Colors.red)
            : null,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _changeTaskTitle(task),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteTask(task),
          ),
        ],
      ),
    );
  }

  String _highlightTime(String task) {
    DateTime now = DateTime.now();
    RegExp timePattern = RegExp(r'(\d{1,2}):(\d{2})');
    return task.replaceAllMapped(
      timePattern,
      (match) {
        DateTime taskTime = DateTime(now.year, now.month, now.day,
            int.parse(match.group(1)!), int.parse(match.group(2)!));
        if (taskTime.isBefore(now)) {
          return '**${match.group(0)}**'; // Highlight past times in bold
        }
        return '*${match.group(0)}*'; // Highlight future times in italics
      },
    );
  }

  void _onTaskComplete(TaskModel task, bool? value) {
    setState(() {
      task.isCompleted = value ?? false;
    });
  }

  void _changeTaskTitle(TaskModel task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Task Title'),
        content: TextField(
          controller: taskController,
          decoration: InputDecoration(hintText: 'Enter new task title'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              String newTitle = taskController.text.trim();
              if (newTitle.isNotEmpty) {
                setState(() {
                  task.title = newTitle;
                });
                Navigator.of(context).pop();
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteTask(TaskModel task) {
    setState(() {
      todoList.remove(task);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Total Tasks: ${_getTotalTasks()}'),
                SizedBox(width: 20),
                Text('Completed Tasks: ${_getCompletedTasks()}'),
                SizedBox(width: 20),
                Text('Waiting Tasks: ${_getWaitingTasks()}'),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: todoList.length,
              itemBuilder: (context, index) {
                return _buildTaskTile(todoList[index]);
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: InputDecoration(
                      hintText: 'Enter task',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (taskController.text.trim().isNotEmpty) {
                      _addTask(taskController.text.trim());
                    }
                  },
                  child: Text('Add Task'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: loadFile,
                  child: Text('Select MD File'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearCompletedTasks,
                  child: Text('Clear Completed'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TaskModel {
  String title;
  bool isCompleted;

  TaskModel({required this.title, required this.isCompleted});
}
