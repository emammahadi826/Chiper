import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:chiper/Screens/welcome_page.dart';
import 'package:chiper/Screens/home_page.dart';
import 'package:chiper/Services/auth_service.dart'; // Import AuthService
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import cloud_firestore
import 'package:chiper/firebase_options.dart';
import 'package:chiper/services/theme_notifier.dart'; // Import ThemeNotifier
import 'package:chiper/auth_wrapper.dart'; // Import AuthWrapper
import 'package:chiper/auth/auth_screen.dart'; // Import AuthScreen
import 'package:chiper/Hide/hide_page.dart';
import 'package:hive_flutter/hive_flutter.dart'; // Import hive_flutter
import 'package:chiper/Models/task.dart'; // Import Task model
import 'package:chiper/notification/notify.dart'; // Import NotificationService
import 'package:flutter/foundation.dart'; // Import for defaultTargetPlatform
import 'package:flutter_background/flutter_background.dart'; // Import flutter_background
import 'package:firebase_messaging/firebase_messaging.dart'; // Import FirebaseMessaging

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  // Configure and enable FlutterBackground (only for non-web platforms)
  if (!kIsWeb) {
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "Ciper is running in background",
      notificationText: "Listening for PC status updates",
      notificationImportance: AndroidNotificationImportance.high,
      notificationIcon: AndroidResource(name: 'ic_notification', defType: 'drawable'), // Use ic_notification
    );
    await FlutterBackground.initialize(androidConfig: androidConfig);
    await FlutterBackground.enableBackgroundExecution();
  }
  
  final themeNotifier = ThemeNotifier(ThemeMode.system); // Create an instance with system default
  await themeNotifier.loadTheme(); // Load saved theme

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeNotifier>(
          create: (_) => themeNotifier,
        ),
      ],
      child: MyApp(), // MyApp needs context for NotificationService.initialize
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
}

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690), // Standard design size for mobile
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final themeNotifier = Provider.of<ThemeNotifier>(context); // Access ThemeNotifier

        return MaterialApp(
          title: 'Chiper',
          debugShowCheckedModeBanner: false, // Hide debug banner
          navigatorKey: navigatorKey, // Assign the global navigator key
          theme: ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF0F0F0), // Light background
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF0F0F0),
              foregroundColor: Colors.black,
              elevation: 0,
            ),
            textTheme: TextTheme(
              displayLarge: TextStyle(color: Colors.black, fontSize: 60.sp, fontWeight: FontWeight.w300),
              displayMedium: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 30.sp),
              bodyLarge: TextStyle(color: Colors.black, fontSize: 28.sp, fontWeight: FontWeight.w500),
              bodyMedium: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 18.sp),
            ),
            cardColor: Colors.white, // Light card background
            colorScheme: const ColorScheme.light(
              primary: Colors.blue, // Blue for primary actions
              onPrimary: Colors.white,
              secondary: Color(0xFFE0E0E0), // Light gray for secondary elements
              onSecondary: Colors.black,
              surface: Colors.white, // White for general surfaces
              onSurface: Colors.black,
              error: Color(0xFFDC3545), // Red for errors
              onError: Colors.white,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF212121), // Lighter dark gray background
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF212121),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            textTheme: TextTheme(
              displayLarge: TextStyle(color: Colors.white, fontSize: 60.sp, fontWeight: FontWeight.w300),
              displayMedium: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 30.sp),
              bodyLarge: TextStyle(color: Colors.white, fontSize: 28.sp, fontWeight: FontWeight.w500),
              bodyMedium: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 18.sp),
            ),
            cardColor: const Color(0xFF303030), // Lighter dark card background
            colorScheme: const ColorScheme.dark(
              primary: Colors.blue, // Blue for primary actions
              onPrimary: Colors.white,
              secondary: Color(0xFF484848), // Lighter gray for secondary elements
              onSecondary: Colors.white,
              surface: Color(0xFF424242), // Darker gray for general surfaces (unchanged)
              onSurface: Colors.white,
              error: Color(0xFFDC3545), // Red for errors (unchanged)
              onError: Colors.white,
            ),
            useMaterial3: true,
          ),
          themeMode: themeNotifier.themeMode, // Use theme from ThemeNotifier
          home: const AuthWrapper(), // Use AuthWrapper as the home screen
          routes: {
            '/login': (context) => const AuthScreen(),
            '/signup': (context) => const AuthScreen(),
            '/home': (context) => const UserHomePage(),
            '/welcome': (context) => const WelcomePage(), // Add welcome route for explicit navigation
            '/hidePage': (context) => const HidePage(),
            
            
          },
          onGenerateRoute: (settings) {
            // No alarmFullScreen route anymore
            return null;
          },
        );
      },
    );
  }
}
