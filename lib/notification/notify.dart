
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timezone/data/latest.dart' as tzdata;
import 'package:permission_handler/permission_handler.dart';
import 'package:chiper/Models/app_notification.dart'; // Import AppNotification
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FirebaseMessaging
import 'package:flutter/foundation.dart';

// Define a global navigator key to allow navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  // If you're using other Firebase services in the background, such as Firestore,
  // make sure to call `initializeApp` before using them.
  // await Firebase.initializeApp(); // This is handled in main.dart
  // You can perform background tasks here, e.g., fetch data from Firestore
  // and then show a local notification.
  // For this app, the Firestore listener is already set up to run in the background
  // via flutter_background, so we primarily use FCM to wake up the app or
  // deliver direct notifications.
  if (message.notification != null) {
    NotificationService().showBasicNotification(
      message.hashCode, // Unique ID for notification
      message.notification!.title ?? 'FCM Notification',
      message.notification!.body ?? 'You have a new message.',
      NotificationService._pcStatusChannelId, // Use a default channel or derive from message
    );
  }
}

/// A service class to manage local notifications based on PC status changes from Firestore.
///
/// To use this service, ensure you call `NotificationService().init()` early in your app's startup,
/// for example, in your `main.dart` file.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance; // Add FirebaseMessaging instance

  StreamSubscription<DocumentSnapshot>? _pcStatusSubscription;
  bool? _lastPcOnStatus;

  static const String _pcStatusChannelId = 'pc_status_channel';
  static const String _pcStatusChannelName = 'PC Status Notifications';
  static const String _pcStatusChannelDescription = 'Notifications for PC power status changes';

  static const String _pcOnStatusKey = 'pc_on_status'; // Key for SharedPreferences

  /// Initializes the notification plugin, sets up channels, and starts listening for auth changes.
  Future<void> init() async {
    print('NotificationService: Initializing...');

    // Initialize timezone data
    tzdata.initializeTimeZones();

    // Request permissions for Android 13+ and iOS
    await requestNotificationsPermission();
    await requestExactAlarmPermission(); // For Android

    // Request FCM permissions and get token
    await _requestFCMAndGetToken();
    _setupFCMForegroundMessages();

    // Android initialization settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    // Android initialization settings
    // iOS initialization settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@drawable/ic_notification'), // Use the existing Android initialization
      iOS: initializationSettingsIOS,
    );

    // Create Android notification channels
    await _createNotificationChannels();

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        print('NotificationService: Notification tapped with payload: ${notificationResponse.payload}');
        // No alarm payload handling anymore
      },
    );

    // Listen for authentication state changes to start/stop the Firestore listener
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        print('NotificationService: User is logged out. Stopping listener.');
        dispose();
      } else {
        print('NotificationService: User is logged in. Starting listener.');
        _listenToPcStatus(user.uid);
      }
    });

    print('NotificationService: Initialization complete.');
  }

  /// Requests notification permissions for Android 13+ (API 33+).
  Future<void> requestNotificationsPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print('NotificationService: Notification permission granted.');
    } else if (status.isDenied) {
      print('NotificationService: Notification permission denied.');
    } else if (status.isPermanentlyDenied) {
      print('NotificationService: Notification permission permanently denied. Open app settings.');
      openAppSettings(); // Opens app settings for the user to manually enable
    }
  }

  /// Requests SCHEDULE_EXACT_ALARM permission for Android 13+ (API 33+).
  Future<void> requestExactAlarmPermission() async {
    if (!kIsWeb) { // Only request on non-web platforms
      final status = await Permission.scheduleExactAlarm.request();
      if (status.isGranted) {
        print('NotificationService: SCHEDULE_EXACT_ALARM permission granted.');
      } else if (status.isDenied) {
        print('NotificationService: SCHEDULE_EXACT_ALARM permission denied.');
      } else if (status.isPermanentlyDenied) {
        print('NotificationService: SCHEDULE_EXACT_ALARM permission permanently denied. Open app settings.');
        openAppSettings(); // Opens app settings for the user to manually enable
      }
    } else {
      print('NotificationService: SCHEDULE_EXACT_ALARM permission not applicable on web.');
    }
  }

  /// Requests FCM permissions and retrieves the FCM token.
  Future<void> _requestFCMAndGetToken() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('NotificationService: User granted permission for FCM.');
        String? token = await _firebaseMessaging.getToken();
        print('NotificationService: FCM Token: $token');
        // You might want to send this token to your backend server
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('NotificationService: User granted provisional permission for FCM.');
      } else {
        print('NotificationService: User declined or has not accepted permission for FCM.');
      }
    } catch (e) {
      print('NotificationService: Failed to request FCM token: $e');
    }
  }

  /// Sets up listeners for FCM messages received while the app is in the foreground.
  void _setupFCMForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('NotificationService: Got a message whilst in the foreground!');
      print('NotificationService: Message data: ${message.data}');

      if (message.notification != null) {
        print('NotificationService: Message also contained a notification: ${message.notification}');
        showBasicNotification(
          message.hashCode, // Unique ID for notification
          message.notification!.title ?? 'FCM Foreground Notification',
          message.notification!.body ?? 'You have a new message.',
          _pcStatusChannelId, // Use a default channel or derive from message
        );
      }
    });
  }

  /// Creates notification channels for Android 8.0+
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel pcStatusChannel = AndroidNotificationChannel(
      _pcStatusChannelId,
      _pcStatusChannelName,
      description: _pcStatusChannelDescription,
      importance: Importance.max,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(pcStatusChannel);
      print('NotificationService: Android notification channels created.');
    }
  }

  /// Listens to Firestore for PC status changes for the given user.
  Future<void> _listenToPcStatus(String userId) async {
    await _loadLastPcStatus();

    final pcStatusDocRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('pc')
        .doc('pc_status');

    _pcStatusSubscription?.cancel();
    _pcStatusSubscription =
        pcStatusDocRef.snapshots().listen((snapshot) async {
      try {
        Map<String, dynamic> data = {};
        bool currentPcOn = false;

        if (snapshot.exists && snapshot.data() != null) {
          data = snapshot.data()! as Map<String, dynamic>;
          currentPcOn = data.containsKey('pc_on') && data['pc_on'] == true;
        } else {
          // If document doesn't exist, create it with default values
          await pcStatusDocRef.set({
            'pc_on': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
          print('NotificationService: pc_status document created with default values.');
          // After creating, we should re-evaluate currentPcOn based on the newly created document
          // For simplicity, we'll assume it's false as per default, or you can fetch it again.
          currentPcOn = false; // Set to default after creation
        }

        print('NotificationService: PC status received. Current: $currentPcOn, Last: $_lastPcOnStatus');

        // Only send notification if PC status has changed
        if (_lastPcOnStatus == null || _lastPcOnStatus != currentPcOn) {
          String title;
          String body;
          if (currentPcOn) {
            print('NotificationService: PC is ON. Sending notification.');
            title = 'PC Status';
            body = 'Sir, the PC is ON';
          } else {
            print('NotificationService: PC is OFF. Sending notification.');
            title = 'PC Status';
            body = 'Sir, the PC is OFF';
          }

          await showBasicNotification(Random().nextInt(100000), title, body, _pcStatusChannelId);

          // Save notification to Firestore
          if (_auth.currentUser != null) {
            final newNotification = AppNotification(
              id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique ID
              title: title,
              body: body,
              timestamp: Timestamp.now(),
            );
            await _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .collection('notifications')
                .doc(newNotification.id)
                .set(newNotification.toFirestore());
            print('NotificationService: Saved notification to Firestore.');
          }

          // Update last known PC status
          await _saveLastPcStatus(currentPcOn);
        } else {
          print('NotificationService: PC status unchanged. No notification action needed.');
        }
      } catch (e) {
        print('NotificationService: Error processing PC status snapshot: $e');
      }
    }, onError: (error) {
      print('NotificationService: Error listening to PC status: $error');
    });
  }

  /// Deletes an app notification from Firestore.
  Future<void> deleteAppNotification(String notificationId) async {
    if (_auth.currentUser == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();
      print('NotificationService: Notification $notificationId deleted from Firestore.');
    } catch (e) {
      print('NotificationService: Error deleting notification $notificationId: $e');
    }
  }

  /// Shows a basic local notification.
  Future<void> showBasicNotification(int notificationId, String title, String body, String channelId, {String? payload}) async {
    print('NotificationService: Sending notification $notificationId: "$title" - "$body" on channel $channelId with payload $payload');

    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      channelId,
      channelId == _pcStatusChannelId ? _pcStatusChannelName : '', // Use PC status channel name
      channelDescription: channelId == _pcStatusChannelId ? _pcStatusChannelDescription : '',
      importance: Importance.max,
      showWhen: false,
      sound: null, // No alarm sound
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails();

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await flutterLocalNotificationsPlugin.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      print('NotificationService: Notification sent successfully.');
    } catch (e) {
      print('NotificationService: Error showing notification: $e');
    }
  }

  /// Public method to send a test notification for debugging.
  Future<void> sendTestNotification() async {
    print('NotificationService: Sending test notification.');
    await showBasicNotification(Random().nextInt(100000), 'Test Notification', 'This is a test notification from Ciper.', _pcStatusChannelId);
  }

  /// Loads the last known PC status from SharedPreferences.
  Future<void> _loadLastPcStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastPcOnStatus = prefs.getBool(NotificationService._pcOnStatusKey);
      print('NotificationService: Loaded last PC status: $_lastPcOnStatus');
    } catch (e) {
      print('NotificationService: Error loading last PC status from SharedPreferences: $e');
    }
  }

  /// Saves the current PC status to SharedPreferences.
  Future<void> _saveLastPcStatus(bool status) async {
    try {
      _lastPcOnStatus = status;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(NotificationService._pcOnStatusKey, status);
      print('NotificationService: Saved last PC status: $status');
    } catch (e) {
      print('NotificationService: Error saving last PC status to SharedPreferences: $e');
    }
  }

  /// Disposes the Firestore subscription.
  void dispose() {
    _pcStatusSubscription?.cancel();
    _pcStatusSubscription = null;
    print('NotificationService: Firestore subscription disposed.');
  }
}
