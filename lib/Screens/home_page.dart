import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chiper/screens/welcome_page.dart';
import 'package:chiper/screens/setting.dart';

import 'package:chiper/Services/auth_service.dart'; // Import AuthService
import 'package:chiper/calculator/calculator_page.dart'; // Import CalculatorPage
import 'package:chiper/tasks/task_home_page.dart';
import 'package:chiper/memo/memo_home.dart'; // Import MemoHomePage
import 'package:chiper/notification/notification_page.dart'; // Import the new Notification Page
import 'package:chiper/profile/profile_page.dart'; // Import ProfilePage
import 'package:chiper/Services/firestore_service.dart'; // Import FirestoreService


class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService(); // Initialize AuthService
  final FirestoreService _firestoreService = FirestoreService(); // Add FirestoreService
  bool _isLoading = false;
  String? _firestoreUserName; // New state variable for name from Firestore

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Call a new method to load user data
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
  void dispose() {
    super.dispose();
  }

  // The issue is here: `_pages` needs to be defined as a field, not a getter, to be used in the build method without potential rebuild issues. Also, MemoHomePage was missing from the list.
  final List<Widget> _pages = [
    const CalculatorPage(),
    TaskHomePage(),
    const MemoHomePage(), // Added MemoHomePage
  ];

  void _onItemTapped(int index) {
    if (index == 2) { // Index 2 is now the 'More' icon
      _scaffoldKey.currentState?.openEndDrawer();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainColor = theme.colorScheme.onSurface;
    final subColor = theme.colorScheme.onSurface.withOpacity(0.6);
    final bgColor = theme.scaffoldBackgroundColor;
    final buttonShadowColor = theme.colorScheme.secondary.withOpacity(0.2);

    // Get current user info
    final user = _auth.currentUser;
    // Prioritize displayName from FirebaseAuth, fallback to Firestore, then default
    final userName = user?.displayName ?? _firestoreUserName ?? 'Welcome, User!';
    final userEmail = user?.email ?? 'user@example.com';
    final userPhoto = user?.photoURL ?? 'https://picsum.photos/200';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      endDrawer: Drawer(
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Column(
          children: [
            _buildDrawerHeader(
              userName: userName,
              userEmail: userEmail,
              userPhoto: userPhoto,
              mainColor: mainColor,
              subColor: subColor,
              theme: theme,
            ),
            SizedBox(height: 15.h), // Added gap between header and first tile

            _buildDrawerTile(
              icon: Icons.settings,
              title: 'Settings',
              onTap: () {
                Navigator.pop(context); // Close drawer before navigation
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const SettingsScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeOutCubic;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                  ),
                );
              },
              theme: theme,
            ),
            _buildDrawerTile(
              icon: Icons.sticky_note_2,
              title: 'Memo',
              onTap: () {
                Navigator.pop(context); // Close drawer before navigation
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MemoHomePage()),
                );
              },
              theme: theme,
            ),
            _buildDrawerTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                Navigator.pop(context); // Close drawer before navigation
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationPage()),
                );
              },
              theme: theme,
            ),
            
            const Spacer(), // Pushes the logout button to the bottom
            _buildDrawerTile(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                if (mounted) setState(() => _isLoading = true);
                try {
                  await _authService.signOut(); // Use AuthService for logout
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const WelcomePage(),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(1.0, 0.0);
                          const end = Offset.zero;
                          const curve = Curves.easeOutCubic;

                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                      (Route<dynamic> route) => false,
                    );
                  }
                } catch (e) {
                  print("Error during logout: $e");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error logging out. Please try again.')), // Changed to const SnackBar
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              theme: theme,
            ),
            SizedBox(height: 20.h), // Increased bottom padding for the drawer content
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                  child: _pages[_currentIndex],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onSurface, // Theme-aware color
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          selectedItemColor: mainColor,
          unselectedItemColor: subColor,
          backgroundColor: theme.scaffoldBackgroundColor, // Use theme's background color
          elevation: 0.0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          enableFeedback: false,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.calculate, size: 24.r), label: 'Calculator'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment, size: 24.r), label: 'Tasks'),
            BottomNavigationBarItem(icon: Icon(Icons.more_horiz, size: 24.r), label: 'More'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader({
    required String userName,
    required String userEmail,
    required String userPhoto,
    required Color mainColor,
    required Color subColor,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.0.r, 20.0.r, 20.0.r, 10.0.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 50.h), // Increased gap at the top
            Row(
              children: [
                CircleAvatar(
                  radius: 40.r,
                  backgroundImage: NetworkImage(userPhoto),
                ),
                SizedBox(width: 16.w), // Add some space between image and text
                Expanded( // Added Expanded
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          color: mainColor,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: subColor,
                          fontSize: 16.sp,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required ThemeData theme, // Add theme parameter
  }) {
    final mainColor = theme.colorScheme.onSurface;
    final cardColor = theme.cardColor;
    final shadowColor = Colors.black.withOpacity(0.08);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.0.r),
        elevation: 0, // Remove default Material elevation
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0.r),
          splashColor: mainColor.withOpacity(0.1),
          highlightColor: mainColor.withOpacity(0.05),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12.0.r),
            ),
            child: Row(
              children: [
                Icon(icon, color: mainColor, size: 24.r),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: mainColor,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}