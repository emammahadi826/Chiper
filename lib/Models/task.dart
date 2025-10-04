import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'task.g.dart';

@HiveType(typeId: 0) // Unique typeId for Task model
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String content;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  bool isCompleted;

  @HiveField(4)
  bool isSynced; // New field to track sync status

  Task({
    required this.id,
    required this.content,
    required this.timestamp,
    this.isCompleted = false,
    this.isSynced = false,
  });

  factory Task.createNew({required String content}) {
    return Task(
      id: const Uuid().v4(),
      content: content,
      timestamp: DateTime.now(),
      isCompleted: false,
      isSynced: false,
    );
  }

  // Convert Task object to a Map for Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'task': content,
      'timestamp': timestamp,
      'completed': isCompleted,
    };
  }

  // Create Task object from Firestore Map
  factory Task.fromFirestoreMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      content: map['task'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isCompleted: map['completed'] as bool,
      isSynced: true, // Assume tasks from Firestore are synced
    );
  }
}
