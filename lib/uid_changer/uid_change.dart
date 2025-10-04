import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UidChangePage extends StatefulWidget {
  const UidChangePage({super.key});

  @override
  State<UidChangePage> createState() => _UidChangePageState();
}

class _UidChangePageState extends State<UidChangePage> with WidgetsBindingObserver {
  bool _isUidChangeEnabled = false; // State for the toggle button
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _uidController = TextEditingController();
  bool _isObscure = true; // For password visibility toggle

  OverlayEntry? _overlayEntry;
  Timer? _popupTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add observer
    _loadInitialToggleState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    _updateUidPermissionStatus(false); // Set to false when widget is disposed
    _uidController.dispose(); // Dispose the controller
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // App is going to background or being terminated
      _updateUidPermissionStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      // App has come to the foreground
      // If the toggle was previously true, set uid_permition back to true
      if (_isUidChangeEnabled) {
        _updateUidPermissionStatus(true);
      }
    }
  }

  Future<void> _loadInitialToggleState() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('users').doc(user.uid).collection('pc').doc('pc_status');
    final snapshot = await docRef.get();

    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data() as Map<String, dynamic>;
      if (data.containsKey('uid_permition')) {
        if (mounted) {
          setState(() {
            _isUidChangeEnabled = data['uid_permition'];
          });
        }
      }
    }
  }

  Future<void> _updateUidPermissionStatus(bool status) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        _showCustomPopup('User not logged in.');
      }
      return;
    }

    final docRef = _firestore.collection('users').doc(user.uid).collection('pc').doc('pc_status');

    try {
      await docRef.set({'uid_permition': status}, SetOptions(merge: true));
      if (mounted) {
        _showCustomPopup('UID permission status updated.');
      }
    } catch (e) {
      if (mounted) {
        _showCustomPopup('Failed to update status: ${e.toString()}');
      }
    }
  }

  void _showCustomPopup(String message) {
    // Ensure any existing popup is removed and its timer cancelled
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null; // Explicitly set to null after removal
    }
    _popupTimer?.cancel(); // Cancel any pending timer

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        final Color backgroundColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05); // 95% transparent
        final Color textColor = isDarkMode ? Colors.white : Colors.black; // Text color based on theme

        return Positioned(
          bottom: MediaQuery.of(context).size.height * 0.10, // Near 90% from top (10% from bottom)
          left: (MediaQuery.of(context).size.width - 250.w) / 2, // Center horizontally with new width
          child: SizedBox( // Added SizedBox to control exact dimensions
            width: 250.w, // Increased width
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12.0.r),
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h), // Adjusted padding for new size
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
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
      _overlayEntry = null; // Set to null when the popup disappears
    });
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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context), // Go back to previous page
        ),
        title: const Text('UID Changer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Enable UID Change Feature', style: theme.textTheme.titleMedium),
                Switch(
                  value: _isUidChangeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isUidChangeEnabled = value;
                    });
                    _updateUidPermissionStatus(value); // Call the new method
                  },
                ),
              ],
            ),
          ),
          // You can add more widgets here, similar to HidePage, using mainColor, cardColor, shadowColor
          // For example, a section for inputing new UID or displaying current UID
          Expanded(
            child: AbsorbPointer(
              absorbing: !_isUidChangeEnabled,
              child: Opacity(
                opacity: _isUidChangeEnabled ? 1.0 : 0.5,
                child: ListView(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: TextField(
                        controller: _uidController,
                        obscureText: _isObscure,
                        decoration: InputDecoration(
                          labelText: 'Enter New UID',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0.r),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isObscure ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isObscure = !_isObscure;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: ElevatedButton(
                        onPressed: () async {
                          final user = _auth.currentUser;
                          if (user == null) {
                            _showCustomPopup('User not logged in.');
                            return;
                          }
                          if (_uidController.text.isEmpty) {
                            _showCustomPopup('UID cannot be empty.');
                            return;
                          }
                          try {
                            await _firestore.collection('users').doc(user.uid).update({
                              'uid': _uidController.text,
                            });
                            _showCustomPopup('UID updated successfully!');
                          } catch (e) {
                            _showCustomPopup('Failed to update UID: ${e.toString()}');
                          }
                        },
                        child: const Text('Change UID'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}