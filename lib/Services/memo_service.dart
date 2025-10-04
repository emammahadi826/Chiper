import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chiper/Models/memo.dart';

class MemoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  String? get userId => currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _memosCollection {
    if (userId == null) {
      return null;
    }
    return _firestore.collection('users').doc(userId).collection('memos');
  }

  // Create or update a memo
  Future<void> saveMemo(Memo memo) async {
    if (_memosCollection == null) {
      throw Exception("User not logged in.");
    }
    if (memo.id == null) {
      // Create new memo
      DocumentReference docRef = await _memosCollection!.add(memo.toMap()..['timestamp'] = FieldValue.serverTimestamp());
      memo.id = docRef.id; // Update memo object with generated ID
      await docRef.update({'id': docRef.id}); // Save ID to document
    } else {
      // Update existing memo
      await _memosCollection!.doc(memo.id).update(memo.toMap());
    }
  }

  // Get all memos for the current user
  Stream<List<Memo>> getMemos() {
    if (_memosCollection == null) {
      return Stream.value([]);
    }
    return _memosCollection!
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Memo.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  // Delete a memo
  Future<void> deleteMemo(String memoId) async {
    if (_memosCollection == null) {
      throw Exception("User not logged in.");
    }
    await _memosCollection!.doc(memoId).delete();
  }

  // Toggle pin status of a memo
  Future<void> togglePin(String memoId, bool isPinned) async {
    if (_memosCollection == null) {
      throw Exception("User not logged in.");
    }
    await _memosCollection!.doc(memoId).update({'isPinned': isPinned});
  }
}
