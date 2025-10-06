import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:chiper/Models/task.dart';

class TaskUpdaterService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Box<Task> _taskBox;
  final Connectivity _connectivity = Connectivity();

  TaskUpdaterService(Box<Task> taskBox) {
    _taskBox = taskBox;
  }

  User? get currentUser => _auth.currentUser;

  Future<void> syncTasks() async {
    if (currentUser == null) return;

    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('TaskUpdaterService: No internet connection. Skipping sync.');
      return;
    }

    print('TaskUpdaterService: Starting task synchronization...');

    try {
      final firestoreSnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks')
          .get();
      final firestoreTasks = firestoreSnapshot.docs.map((doc) => Task.fromFirestoreMap(doc.data())).toList();

      await _taskBox.clear();
      for (final task in firestoreTasks) {
        await _taskBox.put(task.id, task);
      }

      print('TaskUpdaterService: Task synchronization complete.');
    } catch (e) {
      print('TaskUpdaterService: Error during task synchronization: $e');
    }
  }

  Future<void> addTask(Task task) async {
    print('addTask called with content: ${task.content}');
    if (currentUser == null) {
      print('TaskUpdaterService: User is not authenticated. Cannot add task.');
      return;
    }
    print('Current user: ${currentUser?.uid}');

    // Add to local cache immediately
    await _taskBox.put(task.id, task);
    print('Task saved to local cache with id: ${task.id}');

    // Then add to Firestore
    try {
      print('Saving task to Firestore...');
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks')
          .doc(task.id)
          .set(task.toFirestoreMap());
      task.isSynced = true;
      await task.save();
      print('Task saved to Firestore successfully.');
    } catch (e) {
      print('TaskUpdaterService: Error adding task to Firestore: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    if (currentUser == null) return;

    // Update local cache immediately
    await _taskBox.put(task.id, task);

    // Then update Firestore
    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks')
          .doc(task.id)
          .update(task.toFirestoreMap());
      task.isSynced = true;
      await task.save();
    } catch (e) {
      print('TaskUpdaterService: Error updating task in Firestore: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (currentUser == null) return;

    // Delete from local cache immediately
    await _taskBox.delete(taskId);

    // Then delete from Firestore
    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      print('TaskUpdaterService: Error deleting task from Firestore: $e');
    }
  }
}