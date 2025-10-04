import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// Import LogSingUp

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // Button with 3D effect
  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    required ThemeData theme, // Add theme parameter
  }) {
    final buttonColor = Colors.white;
    final onButtonColor = Colors.black;
    final shadowColor = Colors.black; // Use black for shadow to ensure visibility on white button

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 15.0.h),
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(30.0.r),
          boxShadow: [
            // Dark shadow for depth (bottom-right)
            BoxShadow(
              color: shadowColor.withOpacity(0.2),
              offset: Offset(4, 4), // Slight offset for shadow
              blurRadius: 6.r,
              spreadRadius: 1.r,
            ),
            // Light highlight (top-left)
            BoxShadow(
              color: Colors.white.withOpacity(0.8), // Keep white for highlight
              offset: Offset(-2, -2), // Slight offset for highlight
              blurRadius: 4.r,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18.0.sp,
              fontWeight: FontWeight.bold,
              color: onButtonColor,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white, // Fixed to white background
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/Welcome-page.jpg"),
            fit: BoxFit.cover,
          ),
          color: Colors.white, // Fixed to white background
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24.0.w, 24.0.h, 24.0.w, 20.0.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: Container()),
                _buildPrimaryButton(
                  text: 'Get Started',
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  theme: theme, // Pass the theme here
                ),
                SizedBox(height: 25.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
