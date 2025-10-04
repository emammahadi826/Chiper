import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveUserData({
    required String uid,
    required String name,
    required String email,
    required String role,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving user data: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserData({required String uid}) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    }
  }


  /// Adds a new task for a given user.
  ///
  /// [uid]: The user's unique ID.
  /// [taskName]: The name of the task.
  /// [totalDays]: The total number of days for the task.
  /// [dailyHours]: The daily hours allocated for the task.
  Future<void> addTask(
      String uid, String title, String description, DateTime dueTime) async {
    try {
      await _db.collection('users').doc(uid).collection('tasks').add({
        'title': title,
        'description': description,
        'dueTime': Timestamp.fromDate(dueTime),
        'createdAt': FieldValue.serverTimestamp(),
        'isCompleted': false,
      });
    } catch (e) {
      print('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTaskCompletion(
      String uid, String taskId, bool isCompleted) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(taskId)
          .update({'isCompleted': isCompleted});
    } catch (e) {
      print('Error updating task completion: $e');
      rethrow;
    }
  }

  /// Updates the progress for a specific day of a task.
  ///
  /// [uid]: The user's unique ID.
  /// [taskId]: The ID of the task to update.
  /// [day]: The day number for which to update progress.
  /// [hoursSpent]: The hours spent on the task for that day.
  Future<void> updateTaskProgress({
    required String uid,
    required String taskId,
    required int day,
    required int hoursSpent,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(taskId)
          .collection('progress')
          .doc(day.toString()) // Using day as document ID for simplicity
          .set({
            'day': day,
            'hoursSpent': hoursSpent,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true)); // Use merge to update if document exists
    } catch (e) {
      print('Error updating task progress: $e');
      rethrow;
    }
  }

  /// Fetches all tasks for a given user.
  ///
  /// [uid]: The user's unique ID.
  /// Returns a stream of lists of task data.
  Stream<QuerySnapshot> getTasks(String uid) {
    return _db.collection('users').doc(uid).collection('tasks').snapshots();
  }

  /// Deletes a specific task and its progress subcollection.
  ///
  /// [uid]: The user's unique ID.
  /// [taskId]: The ID of the task to delete.
  Future<void> deleteTask(String uid, String taskId) async {
    try {
      // Delete the task document
      await _db
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(taskId)
          .delete();

      // Optionally, you might want to delete the subcollection documents as well.
      // Firestore doesn't automatically delete subcollections when a document is deleted.
      // For simplicity, this example only deletes the parent document.
      // For production, consider a Cloud Function to recursively delete subcollections.
      print('Task $taskId deleted for user $uid.');
    } catch (e) {
      print('Error deleting task: $e');
      rethrow;
    }
  }
}
