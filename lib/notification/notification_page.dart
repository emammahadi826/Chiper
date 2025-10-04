import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // Import for Timer
import 'package:cloud_firestore/cloud_firestore.dart';


class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<DocumentSnapshot>? _pcStatusStream;

  OverlayEntry? _overlayEntry;
  Timer? _popupTimer;

  @override
  void initState() {
    super.initState();
    _setupPcStatusListener();
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _popupTimer?.cancel();
    super.dispose();
  }

  void _showCustomPopup(String message) {
    // Remove any existing popup
    _overlayEntry?.remove();
    _popupTimer?.cancel();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        final Color backgroundColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05); // 95% transparent
        final Color textColor = isDarkMode ? Colors.white : Colors.black; // Text color based on theme

        return Positioned(
          bottom: MediaQuery.of(context).size.height * 0.10, // Near 90% from top (10% from bottom)
          left: (MediaQuery.of(context).size.width - 300.w) / 2, // Center horizontally with new width
          child: SizedBox( // Added SizedBox to control exact dimensions
            width: 300.w, // Width from shutdown_control.dart
            height: 60.h, // Height from shutdown_control.dart
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12.0.r),
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h), // Adjusted padding for new size
                child: Center( // Center the text within the new fixed size
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold, // Bold from shutdown_control.dart
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);

    _popupTimer = Timer(const Duration(seconds: 2), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _setupPcStatusListener() {
    final user = _auth.currentUser;
    if (user == null) {
      // Handle not logged in state, maybe show a message or redirect
      if (mounted) {
        _showCustomPopup('User not logged in.'); // Use custom popup
      }
      return;
    }

    // Collection path: users/{FirebaseAuth.instance.currentUser!.uid}/pc
    final pcDocRef = _firestore.collection('users').doc(user.uid).collection('pc').doc('pc_status'); // Assuming pc_status is a document within 'pc' subcollection

    _pcStatusStream = pcDocRef.snapshots();
  }

  void _deletePcStatusNotification() async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        _showCustomPopup('User not logged in. Cannot remove notification.');
      }
      return;
    }

    // Since isDismissed feature is being removed from this page,
    // this function will now just show a message indicating removal from display.
    // It will not modify Firestore's isDismissed field.
    if (mounted) {
      _showCustomPopup('PC status notification removed from display.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainColor = theme.colorScheme.onSurface;
    final cardColor = theme.cardColor;
    final shadowColor = Colors.black.withOpacity(0.08);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: mainColor),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Notifications',
          style: TextStyle(color: mainColor),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor ?? theme.colorScheme.surface,
        elevation: theme.appBarTheme.elevation ?? 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _pcStatusStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: mainColor)));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No PC status data available.', style: TextStyle(color: mainColor)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final bool isPcOn = data != null && data.containsKey('pc_on') && data['pc_on'] is bool
              ? data['pc_on']
              : false;

          final String statusText = isPcOn ? "Sir, the PC is ON" : "Sir, the PC is OFF";

          return ListView(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Dismissible(
                  key: const Key('pc_status_notification'), // Unique key for Dismissible
                  direction: DismissDirection.endToStart,
                  background: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0.r),
                      color: theme.brightness == Brightness.light ? Colors.black : Colors.white, // Inverted color
                    ),
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(left: 20.w),
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: theme.brightness == Brightness.light ? Colors.white : Colors.black, size: 30.r), // Inverted icon color
                        SizedBox(width: 10.w),
                        Text('Delete', style: TextStyle(color: theme.brightness == Brightness.light ? Colors.white : Colors.black, fontSize: 18.sp)), // Inverted text color
                      ],
                    ),
                  ),
                  secondaryBackground: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0.r),
                      color: theme.brightness == Brightness.light ? Colors.black : Colors.white, // Inverted color
                    ),
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('Delete', style: TextStyle(color: theme.brightness == Brightness.light ? Colors.white : Colors.black, fontSize: 18.sp)), // Inverted text color
                        SizedBox(width: 10.w),
                        Icon(Icons.delete, color: theme.brightness == Brightness.light ? Colors.white : Colors.black, size: 30.r), // Inverted icon color
                      ],
                    ),
                  ),
                  onDismissed: (direction) {
                    _deletePcStatusNotification();
                  },
                  child: Material(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12.0.r),
                    elevation: 0, // Memo items have elevation 0 on Material, but boxShadow
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.0.r),
                      splashColor: mainColor.withOpacity(0.1),
                      highlightColor: mainColor.withOpacity(0.05),
                      onTap: () {
                        // Optional: Add any action for tapping the status card
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12.0.r),
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              blurRadius: 8.0.r,
                              offset: Offset(0, 4.r),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(isPcOn ? Icons.computer : Icons.desktop_access_disabled, color: mainColor, size: 24.r),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: mainColor,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold, // Changed to bold
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            
            ],
          );
        },
      ),
    );
  }
}