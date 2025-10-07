import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ShutdownControlPage extends StatefulWidget {
  const ShutdownControlPage({super.key});

  @override
  State<ShutdownControlPage> createState() => _ShutdownControlPageState();
}

class _ShutdownControlPageState extends State<ShutdownControlPage> with SingleTickerProviderStateMixin {
  bool _isPcOn = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  OverlayEntry? _overlayEntry;
  Timer? _popupTimer;

  Stream<DocumentSnapshot>? _pcStatusStream;
  late AnimationController _powerIconController;
  late Animation<double> _powerIconRotation;
  late Animation<double> _powerIconFade;

  @override
  void initState() {
    super.initState();
    _powerIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _powerIconRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _powerIconController, curve: Curves.easeOut),
    );
    _powerIconFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _powerIconController, curve: Curves.easeOut),
    );

    _setupPcStatusListener();
  }

  @override
  void dispose() {
    _powerIconController.dispose();
    super.dispose();
  }

  void _setupPcStatusListener() {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _isPcOn = false;
      });
      return;
    }

    final pcStatusDocRef = _firestore.collection('users').doc(user.uid).collection('pc').doc('pc_status');

    _pcStatusStream = pcStatusDocRef.snapshots();

    _pcStatusStream?.listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()! as Map<String, dynamic>;
        final bool currentPcOn = data.containsKey('pc_on') && data['pc_on'] is bool ? data['pc_on'] : false;

        if (mounted) {
          setState(() {
            _isPcOn = currentPcOn;
            if (_isPcOn) {
              _powerIconController.forward(from: 0.0); // Animate to ON state
            } else {
              _powerIconController.reverse(from: 1.0); // Animate to OFF state
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isPcOn = false;
            _powerIconController.reverse(from: 1.0);
          });
        }
      }
    }, onError: (error) {
      print("Error listening to PC status: $error");
      if (mounted) {
        _showCustomPopup('Error loading PC status: ${error.toString()}');
      }
      if (mounted) {
        setState(() {
          _isPcOn = false;
          _powerIconController.reverse(from: 1.0);
        });
      }
    });
  }

  Future<void> _togglePcState(bool newValue) async {
    HapticFeedback.lightImpact(); // Haptic feedback on tap

    if (newValue == true && _isPcOn == false) {
      if (mounted) {
        _showCustomPopup('ℹ️ Turn on your PC physically. Button will auto-update.');
      }
      return;
    }

    if (newValue == false && _isPcOn == true) {
      final user = _auth.currentUser;
      if (user == null) {
        if (mounted) {
          _showCustomPopup('User not logged in.');
        }
        return;
      }

      final pcStatusDocRef = _firestore.collection('users').doc(user.uid).collection('pc').doc('pc_status');

      try {
        await pcStatusDocRef.set({'pc_on': newValue}, SetOptions(merge: true));
        if (mounted) {
          _showCustomPopup('⚠ PC will shut down in a few seconds...');
        }
      } catch (e) {
        print("Error updating PC state: $e");
        if (mounted) {
          _showCustomPopup('Error updating PC status: ${e.toString()}');
        }
      }
    }
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
            width: 300.w, // Width remains the same
            height: 60.h, // Increased height
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
                      fontWeight: FontWeight.bold, // Changed to bold
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainColor = theme.colorScheme.onSurface;
    final isDarkMode = theme.brightness == Brightness.dark;

    

    final Color powerIconColor = _isPcOn ? Colors.green : Colors.red;
    final Color powerIconGlowColor = _isPcOn ? Colors.green.shade300 : Colors.red.shade300;

    final Color toggleStartColor = _isPcOn
        ? (isDarkMode ? Colors.green.shade700 : Colors.green.shade400)
        : (isDarkMode ? Colors.red.shade700 : Colors.red.shade400);
    final Color toggleEndColor = _isPcOn
        ? (isDarkMode ? Colors.green.shade500 : Colors.green.shade200)
        : (isDarkMode ? Colors.orange.shade500 : Colors.orange.shade200);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Shutdown Control",
          style: GoogleFonts.righteous(
            textStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(fontSize: 24.sp),
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: mainColor),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Power Icon
            AnimatedBuilder(
              animation: _powerIconController,
              builder: (context, child) {
                return RotationTransition(
                  turns: _powerIconRotation,
                  child: Opacity(
                    opacity: _powerIconFade.value,
                    child: Icon(
                      Icons.power_settings_new,
                      size: 100.r,
                      color: powerIconColor,
                      shadows: [
                        BoxShadow(
                          color: powerIconGlowColor.withOpacity(_isPcOn ? 0.8 : 0.0),
                          blurRadius: _isPcOn ? 20.r : 0.r,
                          spreadRadius: _isPcOn ? 5.r : 0.r,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20.h),
            // Status Label
            Text(
              _isPcOn ? "PC is ON" : "PC is OFF",
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: _isPcOn ? Colors.green.shade600 : Colors.red.shade600,
              ),
            ),
            SizedBox(height: 40.h),
            // Toggle Button
            GestureDetector(
              onTap: () {
                _togglePcState(!_isPcOn);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 150.r, // Large circular button
                height: 150.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [toggleStartColor, toggleEndColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      spreadRadius: 3.r,
                      blurRadius: 10.r,
                      offset: Offset(0, 5.h),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.power_settings_new,
                    size: 80.r,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}