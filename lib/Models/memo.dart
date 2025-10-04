import 'package:cloud_firestore/cloud_firestore.dart';

class Memo {
  String? id;
  String title;
  String content;
  DateTime timestamp;
  bool isPinned;

  Memo({
    this.id,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isPinned = false,
  });

  // Convert a Memo object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
      'isPinned': isPinned,
    };
  }

  // Extract a Memo object from a Map object
  factory Memo.fromMap(Map<String, dynamic> map) {
    return Memo(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isPinned: map['isPinned'] ?? false,
    );
  }

  // For Firebase DocumentSnapshot
  factory Memo.fromFirestore(Map<String, dynamic> map, String documentId) {
    DateTime parseTimestamp(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else {
        return DateTime.now(); // Default or throw error
      }
    }
    return Memo(
      id: documentId,
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      timestamp: parseTimestamp(map['timestamp']),
      isPinned: map['isPinned'] ?? false,
    );
  }
}
