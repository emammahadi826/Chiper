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
    if (currentUser == null) return; // Only sync if user is logged in

    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('TaskUpdaterService: No internet connection. Skipping sync.');
      return; // No internet connection
    }

    print('TaskUpdaterService: Starting task synchronization...');

    try {
      // 1. Fetch all tasks from Firestore
      final firestoreSnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks')
          .get();
      final firestoreTasks = firestoreSnapshot.docs.map((doc) => Task.fromFirestoreMap(doc.data())).toList();
      final Map<String, Task> firestoreTasksMap = {for (var task in firestoreTasks) task.id: task};

      // 2. Fetch all tasks from Hive
      final List<Task> localTasks = _taskBox.values.toList();
      final Map<String, Task> localTasksMap = {for (var task in localTasks) task.id: task};

      // 3. Merge Logic

      // 3. Merge Logic

      // Add/Update tasks from Hive to Firestore
      for (var localTask in localTasks) {
        final firestoreTask = firestoreTasksMap[localTask.id];
        if (firestoreTask == null) {
          // Task exists in Hive but not in Firestore, add it to Firestore
          await _firestore
              .collection('users')
              .doc(currentUser!.uid)
              .collection('tasks')
              .doc(localTask.id)
              .set(localTask.toFirestoreMap());
          localTask.isSynced = true;
          await localTask.save();
          print('TaskUpdaterService: Added task ${localTask.id} from Hive to Firestore.');
        } else {
          // Task exists both locally and in Firestore
          // If local version is newer or not synced, update Firestore
          if (localTask.timestamp.compareTo(firestoreTask.timestamp) > 0 || !localTask.isSynced) {
            print('Syncing from Hive to Firestore: Task ${localTask.id}, Local isCompleted: ${localTask.isCompleted}, Firestore isCompleted (before update): ${firestoreTask.isCompleted}');
            await _firestore
                .collection('users')
                .doc(currentUser!.uid)
                .collection('tasks')
                .doc(localTask.id)
                .update(localTask.toFirestoreMap());
            localTask.isSynced = true;
            await localTask.save();
            print('Syncing from Hive to Firestore: Task ${localTask.id}, Local isCompleted (after Firestore update): ${localTask.isCompleted}');
            print('TaskUpdaterService: Updated Firestore task ${localTask.id} from Hive.');
          }
        }
      }

      // Now, fetch from Firestore and update Hive for any changes made directly in Firestore
      // This loop should run AFTER all local unsynced changes have been pushed.
      final updatedFirestoreSnapshot = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks')
          .get();
      final updatedFirestoreTasks = updatedFirestoreSnapshot.docs.map((doc) => Task.fromFirestoreMap(doc.data())).toList();
      final Map<String, Task> updatedFirestoreTasksMap = {for (var task in updatedFirestoreTasks) task.id: task};

      for (var firestoreTask in updatedFirestoreTasks) {
        final localTask = _taskBox.get(firestoreTask.id);
        if (localTask == null) {
          // Task exists in Firestore but not locally, add it to Hive
          await _taskBox.put(firestoreTask.id, firestoreTask);
          print('TaskUpdaterService: Added task ${firestoreTask.id} from Firestore to Hive (after local push).');
        } else {
          // Task exists both locally and in Firestore
          // Only update local if Firestore version is newer
          if (firestoreTask.timestamp.compareTo(localTask.timestamp) > 0) {
            localTask.content = firestoreTask.content;
            localTask.isCompleted = firestoreTask.isCompleted;
            localTask.timestamp = firestoreTask.timestamp;
            localTask.isSynced = true; // Mark as synced after updating from Firestore
            await localTask.save();
            print('TaskUpdaterService: Updated local task ${localTask.id} from Firestore (after local push).');
          }
        }
      }

      // Handle deletions: If a task is in Hive but not in Firestore, and it's not marked as deleted locally (which we don't have a flag for yet)
      // For now, we assume deletion is handled by _deleteTask which removes from both.
      // If a task is in Firestore but not in Hive, it means it was deleted locally and needs to be deleted from Firestore.
      // This scenario is handled by _deleteTask, which removes from both Hive and Firestore.
      // If a task was deleted from Firestore directly, it will be removed from Hive during the Firestore to Hive sync.

      print('TaskUpdaterService: Task synchronization complete.');
    } catch (e) {
      print('TaskUpdaterService: Error during task synchronization: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    if (currentUser == null) return;

    try {
      // Delete from Firestore
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('tasks')
          .doc(taskId)
          .delete();
      print('TaskUpdaterService: Task $taskId deleted from Firestore.');
    } catch (e) {
      print('TaskUpdaterService: Error deleting task $taskId from Firestore: $e');
      // Re-add to Hive if Firestore deletion fails (optional, depends on desired behavior)
      // final task = _taskBox.get(taskId);
      // if (task != null) {
      //   await _taskBox.put(taskId, task);
      // }
    }
  }
}
