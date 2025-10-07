import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chiper/pc_tools/shutdown_control.dart';
import 'package:chiper/pc_setting/pc_setting_page.dart';
import 'package:chiper/pc_tools/pc_tools.dart'; // Import the new PC Tools page


import 'package:chiper/profile/profile_page.dart';
import 'package:chiper/Screens/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HidePage extends StatefulWidget {
  const HidePage({super.key});

  @override
  State<HidePage> createState() => _HidePageState();
}

class _HidePageState extends State<HidePage> with WidgetsBindingObserver {
  bool _isToggled = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    _updateSecretPageStatus(false); // Keep this for when the widget is explicitly disposed
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // App is going to background or being terminated
      _updateSecretPageStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      // App has come to the foreground
      // If the toggle was previously true, set secret_page back to true
      if (_isToggled) {
        _updateSecretPageStatus(true);
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
      if (data.containsKey('secret_page')) {
        if (mounted) {
          setState(() {
            _isToggled = data['secret_page'];
          });
        }
      }
    }
  }

  Future<void> _updateSecretPageStatus(bool status) async {
    final user = _auth.currentUser;
    if (user == null) {
      if (mounted) {
        _showCustomPopup('User not logged in.');
      }
      return;
    }

    final docRef = _firestore.collection('users').doc(user.uid).collection('pc').doc('pc_status');

    try {
      await docRef.set({'secret_page': status}, SetOptions(merge: true));
      if (mounted) {
        _showCustomPopup('Secret page status updated.');
      }
    } catch (e) {
      if (mounted) {
        _showCustomPopup('Failed to update status: ${e.toString()}');
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
          left: (MediaQuery.of(context).size.width - 250.w) / 2, // Center horizontally with new width
          child: SizedBox( // Added SizedBox to control exact dimensions
            width: 250.w, // Increased width
            height: 50.h, // Increased height
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12.0.r),
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h), // Adjusted padding for new size
                child: Center( // Center the text within the new fixed size
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
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
    final cardColor = theme.cardColor;
    final shadowColor = Colors.black.withOpacity(0.08);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserHomePage()),
          ),
        ),
        title: Text(
          'Hidden Page',
          style: GoogleFonts.righteous(
            textStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(fontSize: 24.sp),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Enable Hidden Features', style: theme.textTheme.titleMedium),
                Switch(
                  value: _isToggled,
                  onChanged: (value) {
                    setState(() {
                      _isToggled = value;
                    });
                    _updateSecretPageStatus(value);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: AbsorbPointer(
              absorbing: !_isToggled,
              child: Opacity(
                opacity: _isToggled ? 1.0 : 0.5,
                child: ListView(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Material(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12.0.r),
                        elevation: 0,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const ShutdownControlPage(),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeOutCubic;

                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));

                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12.0.r),
                          splashColor: mainColor.withOpacity(0.1),
                          highlightColor: mainColor.withOpacity(0.05),
                          child: Container(
                            padding:
                                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                                Icon(Icons.desktop_windows_outlined,
                                    color: mainColor, size: 24.r),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Text(
                                    'PC',
                                    style: GoogleFonts.montserrat(
                                      textStyle: TextStyle(
                                        color: mainColor,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Material(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12.0.r),
                        elevation: 0,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const PcSettingPage(),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeOutCubic;

                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));

                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12.0.r),
                          splashColor: mainColor.withOpacity(0.1),
                          highlightColor: mainColor.withOpacity(0.05),
                          child: Container(
                            padding:
                                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                                Icon(Icons.settings_outlined, color: mainColor, size: 24.r),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Text(
                                    'PC Settings',
                                    style: GoogleFonts.montserrat(
                                      textStyle: TextStyle(
                                        color: mainColor,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Material(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12.0.r),
                        elevation: 0,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const PCToolsPage(),
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeOutCubic;

                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));

                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12.0.r),
                          splashColor: mainColor.withOpacity(0.1),
                          highlightColor: mainColor.withOpacity(0.05),
                          child: Container(
                            padding:
                                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                                Icon(Icons.handyman_outlined,
                                    color: mainColor, size: 24.r),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Text(
                                    'PC Tools',
                                    style: GoogleFonts.montserrat(
                                      textStyle: TextStyle(
                                        color: mainColor,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      child: Material(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12.0.r),
                        elevation: 0,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) =>
                                    const ProfilePage(), // Navigate to ProfilePage
                                transitionsBuilder:
                                    (context, animation, secondaryAnimation, child) {
                                  const begin = Offset(1.0, 0.0);
                                  const end = Offset.zero;
                                  const curve = Curves.easeOutCubic;

                                  var tween = Tween(begin: begin, end: end)
                                      .chain(CurveTween(curve: curve));

                                  return SlideTransition(
                                    position: animation.drive(tween),
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12.0.r),
                          splashColor: mainColor.withOpacity(0.1),
                          highlightColor: mainColor.withOpacity(0.05),
                          child: Container(
                            padding:
                                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                                Icon(Icons.person_outline,
                                    color: mainColor, size: 24.r),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Text(
                                    'Profile',
                                    style: GoogleFonts.montserrat(
                                      textStyle: TextStyle(
                                        color: mainColor,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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