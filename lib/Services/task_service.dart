
import 'package:chiper/Models/task.dart';
import 'package:chiper/Services/firestore_service.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskService {
  final FirestoreService _firestoreService = FirestoreService();
  late Box<Task> _taskBox;

  Future<void> init(String userId) async {
    _taskBox = await Hive.openBox<Task>('tasks_\$userId');
  }

  Future<List<Task>> getTasks(String userId) async {
    if (_taskBox.isNotEmpty) {
      return _taskBox.values.toList();
    } else {
      final snapshot = await _firestoreService.getTasks(userId).first;
      final tasks = snapshot.docs.map((doc) => Task.fromFirestoreMap(doc.data() as Map<String, dynamic>)).toList();
      await _cacheTasks(tasks);
      return tasks;
    }
  }

  Future<void> syncTasks(String userId) async {
    final snapshot = await _firestoreService.getTasks(userId).first;
    final tasks = snapshot.docs.map((doc) => Task.fromFirestoreMap(doc.data() as Map<String, dynamic>)).toList();
    await _cacheTasks(tasks);
  }

  Future<void> _cacheTasks(List<Task> tasks) async {
    await _taskBox.clear();
    for (final task in tasks) {
      await _taskBox.put(task.id, task);
    }
  }

  Future<void> addTask(String userId, String title, String description, DateTime dueTime) async {
    final newTask = Task.createNew(content: title);
    await _taskBox.put(newTask.id, newTask);
    await _firestoreService.addTask(userId, title, description, dueTime);
  }

  Future<void> updateTask(Task task) async {
    await _taskBox.put(task.id, task);
    // TODO: Implement update in FirestoreService
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await _taskBox.delete(taskId);
    await _firestoreService.deleteTask(userId, taskId);
  }
}
