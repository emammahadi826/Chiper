import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chiper/services/theme_notifier.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:async'; // Import for Timer
import 'package:permission_handler/permission_handler.dart'; // Import permission_handler

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _notificationStatus = 'Checking...'; // Keep for internal status tracking
  OverlayEntry? _overlayEntry;
  Timer? _popupTimer;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermissionStatus();
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
            width: 300.w, // Increased width
            height: 60.h, // Increased height
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12.0.r),
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h), // Adjusted padding for new size
                child: Center( // Center the text within the new fixed size
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

  Future<void> _checkNotificationPermissionStatus() async {
    final status = await Permission.notification.status;
    setState(() {
      if (status.isGranted) {
        _notificationStatus = 'Granted';
      } else if (status.isDenied) {
        _notificationStatus = 'Denied';
      } else if (status.isPermanentlyDenied) {
        _notificationStatus = 'Permanently Denied';
      } else {
        _notificationStatus = 'Unknown';
      }
    });
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    setState(() {
      if (status.isGranted) {
        _notificationStatus = 'Granted';
        _showCustomPopup('Notification permission granted.');
      } else if (status.isDenied) {
        _notificationStatus = 'Denied';
        _showCustomPopup('Notification permission denied.');
      } else if (status.isPermanentlyDenied) {
        _notificationStatus = 'Permanently Denied';
        _showCustomPopup('Notification permission permanently denied. Please enable from settings.');
        openAppSettings();
      } else {
        _notificationStatus = 'Unknown';
      }
    });
  }

  // Removed _showSnackBar function

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20.sp),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface, size: 24.r),
      ),
      body: ListView(
        children: [
          SizedBox(height: 10.h), // Reduced gap below the header
          SwitchListTile(
            title: Text('Dark Mode', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16.sp)),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.setTheme(value ? ThemeMode.dark : ThemeMode.light);
            },
            secondary: Icon(Icons.dark_mode, color: Theme.of(context).colorScheme.onSurface, size: 24.r),
          ),
          SwitchListTile(
            title: Text('Notifications', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16.sp)),
            value: _notificationStatus == 'Granted', // Set switch based on status
            onChanged: (value) async {
              if (value) {
                // If turning on, request permission
                await _requestNotificationPermission();
              } else {
                // If turning off, open app settings to revoke
                openAppSettings();
                _showCustomPopup('Please disable notification permission from app settings.');
              }
            },
            secondary: Icon(Icons.notifications, color: Theme.of(context).colorScheme.onSurface, size: 24.r),
          ),
          ListTile(
            title: Text('Language', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16.sp)),
            leading: Icon(Icons.language, color: Theme.of(context).colorScheme.onSurface, size: 24.r),
            onTap: () {
              // TODO: Implement navigation to language settings page
            },
          ),
        ],
      ),
    );
  }
}
