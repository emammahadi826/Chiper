import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  /// Initializes GoogleSignIn with required scopes for user's email, profile, and OpenID.
  /// These scopes ensure that the app requests necessary permissions to access user data
  /// like display name, email, and profile picture during the Google Sign-In process.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
      'openid',
    ],
  );
  final _storage = const FlutterSecureStorage();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add this method at the end of the class
  Future<void> _saveFcmTokenToFirestore(String? userId) async {
    if (userId == null) return;
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    await _firestore.collection('users').doc(userId).set(
      {'fcmToken': fcmToken},
      SetOptions(merge: true),
    );
    print('FCM token saved to Firestore for user $userId');
    }

  // Stream to listen to authentication state changes
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password, String name) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);
      await _saveFcmTokenToFirestore(userCredential.user?.uid); // Save FCM token
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      return null;
    } catch (e) {
      print('Error during sign up: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await _saveFcmTokenToFirestore(userCredential.user?.uid); // Save FCM token
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.message}');
      return null;
    } catch (e) {
      print('Error during sign in: $e');
      return null;
    }
  }

  /// Initiates the Google Sign-In process.
  /// This method handles the interaction with Google for authentication and then
  /// uses the obtained credentials to sign in with Firebase.
  ///
  /// Note: Biometric (fingerprint) authentication is not part of the default
  /// Google Sign-In flow and must be implemented separately using packages
  /// like `local_auth` if required after successful sign-in.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      /// Attempt to sign in with Google. This will open the Google account
      /// selection dialog to the user.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      /// Check if the user cancelled the Google Sign-In process.
      /// If `googleUser` is null, it means the user closed the dialog
      /// without selecting an account or explicitly cancelled.
      if (googleUser == null) {
        print('Google Sign-In cancelled by user.');
        return null;
      }

      /// Obtain the authentication details from the Google user.
      /// This includes the accessToken and idToken required for Firebase.
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      /// Create a Firebase Auth credential using the Google ID token and access token.
      /// This credential will be used to sign in to Firebase.
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      /// Sign in to Firebase with the Google credential.
      /// This links the Google account to a Firebase user.
      /// The returned `UserCredential` contains information about the signed-in user,
      /// including `user.displayName`, `user.email`, and `user.photoURL`.
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _saveFcmTokenToFirestore(userCredential.user?.uid); // Save FCM token
      print('Successfully signed in with Google to Firebase.');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      /// Catch and handle specific Firebase Authentication errors.
      /// Common errors include network issues, invalid credentials, etc.
      print('Firebase Auth Error during Google Sign-In: ${e.message}');
      // You can add more specific error handling or UI feedback here.
      return null;
    } catch (e) {
      /// Catch any other unexpected errors during the Google Sign-In process.
      print('General Error during Google Sign-In: $e');
      // This can include issues with Google Play Services, device configuration, etc.
      return null;
    }
  }

  // Save authentication token
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  // Read authentication token
  Future<String?> readToken() async {
    return await _storage.read(key: 'auth_token');
  }

  // Sign out from Firebase and Google
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await _storage.delete(key: 'auth_token');
  }

  // Get the current logged-in user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Initialize FCM token saving and listen for token refreshes
  void initializeFcmTokenSaving() {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _saveFcmTokenToFirestore(user.uid); // Save token on login

        FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
          _saveFcmTokenToFirestore(user.uid); // Save token on refresh
        }).onError((error) {
          print('Error refreshing FCM token: $error');
        });
      }
    });
  }
}
