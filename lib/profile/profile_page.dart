import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';

// To run this example, you need to set up Firebase in your project.
// You'll also need to add the following dependencies to your pubspec.yaml:
// flutter_screenutil: ^5.9.0
// firebase_auth: ^4.17.4

import 'package:chiper/Services/firestore_service.dart'; // Import FirestoreService

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  String? _firestoreUserName;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _firestoreService.getUserData(uid: user.uid);
      if (userData != null && userData.containsKey('name')) {
        setState(() {
          _firestoreUserName = userData['name'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user from Firebase Auth
    final user = FirebaseAuth.instance.currentUser;
    // Get the current theme to ensure the UI adapts to light and dark modes
    final theme = Theme.of(context);

    // If the user is null, show a message or a loading indicator
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not logged in.'),
        ),
      );
    }

    // A modern-looking profile page with a clean layout
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Changed to match hide_page
      appBar: AppBar(
        title: const Text('Profile'),
        // Use colors from the theme for a consistent look
        backgroundColor: theme.appBarTheme.backgroundColor, // Changed to match app bar theme
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row( // Row for image and name
                // mainAxisAlignment: MainAxisAlignment.spaceBetween, // Removed to allow fixed gap
                children: [
                  SizedBox(width: 10.w), // Gap on the left of the image
                  CircleAvatar(
                    radius: 40.r, // Image size
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      user.email != null && user.email!.isNotEmpty
                          ? user.email![0].toUpperCase()
                          : '?',
                      style: theme.textTheme.headlineSmall!.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 20.w), // Increased gap between image and name
                  Expanded(
                    child: Text( // Name
                      user.displayName ?? _firestoreUserName ?? 'Anonymous User',
                      style: theme.textTheme.displayMedium, // Increased size
                      overflow: TextOverflow.ellipsis, // Add ellipsis for long names
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h), // Small gap between name/image row and email
              Text( // Email below
                user.email ?? '',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.textTheme.bodyMedium!.color!.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 32.h),

              // Card for user ID
              _ProfileInfoCard(
                title: 'User ID',
                content: user.uid,
                icon: Icons.fingerprint,
                onCopy: () {
                  Clipboard.setData(ClipboardData(text: user.uid));
                  _showSnackBar(context, 'User ID copied to clipboard!');
                },
              ),
              SizedBox(height: 16.h),

              // Card for user email
              _ProfileInfoCard(
                title: 'Email',
                content: user.email ?? 'Not available',
                icon: Icons.email_outlined,
                onCopy: user.email != null
                    ? () {
                        Clipboard.setData(ClipboardData(text: user.email!));
                        _showSnackBar(context, 'Email copied to clipboard!');
                      }
                    : null,
              ),
              SizedBox(height: 32.h),

              
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to show a SnackBar
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// A reusable widget for displaying profile information in a clean card
class _ProfileInfoCard extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final VoidCallback? onCopy;

  const _ProfileInfoCard({
    required this.title,
    required this.content,
    required this.icon,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: theme.cardColor, // Changed to theme.cardColor
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.1),
          width: 1.0.r,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurface.withOpacity(0.6)),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  content,
                  style: theme.textTheme.bodySmall, // Changed to bodySmall
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onCopy != null) ...[
            SizedBox(width: 12.w),
            IconButton(
              icon: Icon(Icons.copy, color: theme.colorScheme.primary),
              onPressed: onCopy,
            ),
          ],
        ],
      ),
    );
  }
}

