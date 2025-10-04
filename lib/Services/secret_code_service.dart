import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SecretCodeService {
  static const String _secretCodeKey = 'secret_code';
  static const String _defaultSecretCode = '1234'; // Default secret code

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<String> getSecretCode() async {
    if (currentUser != null) {
      try {
        final doc = await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('secret_code')
            .doc('current_code') // Using a fixed document ID for the secret code
            .get();
        if (doc.exists && doc.data() != null && doc.data()!['code'] != null) {
          return doc.data()!['code'] as String;
        }
      } catch (e) {
        print("Error fetching secret code from Firestore: $e");
      }
    }

    // Fallback to SharedPreferences if not found in Firestore or no user logged in
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_secretCodeKey) ?? _defaultSecretCode;
  }

  Future<void> setSecretCode(String code) async {
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_secretCodeKey, code);

    // Save to Firestore if user is logged in
    if (currentUser != null) {
      try {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('secret_code')
            .doc('current_code') // Using a fixed document ID for the secret code
            .set({'code': code});
      } catch (e) {
        print("Error saving secret code to Firestore: $e");
      }
    }
  }
}