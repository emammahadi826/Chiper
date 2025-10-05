import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:chiper/auth/log.dart';
import 'package:chiper/auth/sign_up.dart';
import 'package:chiper/Screens/home_page.dart';
import 'package:chiper/Services/firestore_service.dart'; // Import FirestoreService
import 'package:chiper/Services/auth_service.dart'; // Import AuthService

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _loginFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _signupFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLogin = true;
  bool _isLoginLoading = false; // New loading state for manual login
  bool _isGoogleSignInLoading = false; // New loading state for Google Sign-In
  String? _error;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  final FirestoreService _firestoreService = FirestoreService(); // Initialize FirestoreService

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
      _loginFormKey.currentState?.reset();
      _signupFormKey.currentState?.reset();
    });
  }

  void _submit() async {
    final formKey = _isLogin ? _loginFormKey : _signupFormKey;
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoginLoading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        // Manual Login Logic
        final String email = _emailController.text.trim();
        final String password = _passwordController.text.trim();

        try {
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } on FirebaseAuthException catch (e) {
          print('Firebase Auth Error Code: ${e.code}');
          String errorMessage;
          if (e.code == 'user-not-found') {
            errorMessage = "No user found for that email.";
          } else if (e.code == 'wrong-password') {
            errorMessage = "Wrong password provided for that user.";
          } else if (e.code == 'invalid-credential') {
            errorMessage = "Invalid credentials. Please check your email and password.";
          } else {
            errorMessage = e.message ?? "An unknown error occurred.";
          }
          setState(() {
            _error = errorMessage;
          });
          return; // Exit after handling FirebaseAuthException
        }
      } else {
        // Manual Sign-Up Logic
        final UserCredential? userCredential = await _authService.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(), // Pass the name here
        );

        if (userCredential == null) {
          setState(() {
            _error = "Sign-up failed. Please try again."; // Generic error for now
          });
          return;
        }

        // Save user data to Firestore after successful signup
        if (userCredential.user != null) {
          await _firestoreService.saveUserData(
            uid: userCredential.user!.uid,
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            role: 'user', // Default role
          );
        }
      }
      // Navigate to home page on successful login/signup
      if (!mounted) return; // Add this line
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const UserHomePage()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoginLoading = false;
        });
      }
    }
  }

  final AuthService _authService = AuthService(); // Instantiate AuthService

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleSignInLoading = true;
      _error = null;
    });
    try {
      final UserCredential? userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        // User canceled or an error occurred within signInWithGoogle
        setState(() {
          _isGoogleSignInLoading = false;
        });
        return;
      }

      // The existing check for signInMethods.isEmpty might be problematic if the user expects
      // to create a new account via Google Sign-In. However, the prompt states "Fix any misconfiguration
      // that causes the 'PlatformException(sign_in_failed, ApiException: 10: )' error after account selection."
      // This error is usually not caused by this logic.
      // If the user wants to allow new Google sign-ups, this part needs to be changed.

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const UserHomePage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      print("Firebase Auth Error during Google Sign-In: ${e.code} - ${e.message}");
      if (!mounted) return; // Add this line
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      print("General Error during Google Sign-In: $e");
      if (!mounted) return; // Add this line
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleSignInLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _isLogin
            ? LoginPage(
                key: const ValueKey('login'),
                formKey: _loginFormKey,
                emailController: _emailController,
                passwordController: _passwordController,
                obscurePassword: _obscurePassword,
                onObscurePasswordToggle: (value) {
                  setState(() {
                    _obscurePassword = value;
                  });
                },
                onLoginPressed: _submit,
                onToggleSignUp: _toggleAuthMode,
                onGoogleSignInPressed: _signInWithGoogle, // Pass Google Sign-In callback
                error: _error,
                isLoginLoading: _isLoginLoading,
                isGoogleSignInLoading: _isGoogleSignInLoading,
                emailFocusNode: _emailFocusNode,
                passwordFocusNode: _passwordFocusNode,
              )
            : SignUpPage(
                key: const ValueKey('signup'),
                formKey: _signupFormKey,
                nameController: _nameController,
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                obscurePassword: _obscurePassword,
                obscureConfirmPassword: _obscureConfirmPassword,
                onObscurePasswordToggle: (value) {
                  setState(() {
                    _obscurePassword = value;
                  });
                },
                onObscureConfirmPasswordToggle: (value) {
                  setState(() {
                    _obscureConfirmPassword = value;
                  });
                },
                onSignUpPressed: _submit,
                onToggleLogin: _toggleAuthMode,
                error: _error,
                isLoading: _isLoginLoading,
                nameFocusNode: _nameFocusNode,
                emailFocusNode: _emailFocusNode,
                passwordFocusNode: _passwordFocusNode,
                confirmPasswordFocusNode: _confirmPasswordFocusNode,
              ),
      ),
    );
  }
}