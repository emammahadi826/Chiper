// File: log.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ---------------- Helper widget for custom text form fields ----------------
Widget buildCustomTextField({
  required String label,
  required TextEditingController controller,
  bool obscureText = false,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
  bool isPasswordField = false,
  required ValueChanged<bool> onObscureTextToggle,
  required FocusNode focusNode,
  required ThemeData theme, // Re-add theme parameter
}) {
  return Padding(
    padding: EdgeInsets.symmetric(vertical: 10.0.h),
    child: TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.black, fontSize: 16.sp),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black54, fontSize: 16.sp),
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        suffixIcon: isPasswordField
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                  size: 24.r,
                ),
                onPressed: () {
                  onObscureTextToggle(!obscureText);
                },
              )
            : null,
        contentPadding: EdgeInsets.symmetric(vertical: 12.0.h, horizontal: 0),
      ),
    ),
  );
}

// ---------------- Helper widget for custom action buttons ----------------
Widget buildCustomActionButton({
  required String text,
  required Color bgColor,
  required Color shadowColor,
  required Color textColor,
  required VoidCallback onPressed,
  bool isLoading = false,
  Widget? leadingIcon, // New optional parameter for leading icon
}) {
  return GestureDetector(
    onTap: isLoading ? null : onPressed,
    child: Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 15.0.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30.0.r),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: shadowColor,
            spreadRadius: 2.r,
            blurRadius: 4.r,
            offset: Offset(0, 3.h),
          ),
        ],
      ),
      child: Center(
        child: isLoading
            ? SizedBox(
                width: 24.w,
                height: 24.h,
                child: CircularProgressIndicator(
                  color: Colors.black, // Explicitly black
                  strokeWidth: 4, // Increased strokeWidth for a bolder appearance
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min, // Use min to wrap content
                children: [
                  if (leadingIcon != null) ...[
                    leadingIcon,
                    SizedBox(width: 10.w), // Spacing between icon and text
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 18.0.sp,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

// ---------------- Login Page ----------------
class LoginPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final ValueChanged<bool> onObscurePasswordToggle;
  final VoidCallback onLoginPressed;
  final VoidCallback onToggleSignUp;
  final VoidCallback onGoogleSignInPressed;
  final String? error;
  final bool isLoginLoading; // New parameter
  final bool isGoogleSignInLoading; // New parameter
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;

  const LoginPage({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onObscurePasswordToggle,
    required this.onLoginPressed,
    required this.onToggleSignUp,
    required this.onGoogleSignInPressed,
    required this.error,
    required this.isLoginLoading, // New parameter
    required this.isGoogleSignInLoading, // New parameter
    required this.emailFocusNode,
    required this.passwordFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryButtonBgColor = theme.colorScheme.surface; // Use theme surface color
    final Color primaryButtonTextColor = theme.colorScheme.onSurface; // Use theme onSurface color
    final Color googleButtonBgColor = theme.colorScheme.surface; // Use theme surface color for Google button
    final Color googleButtonTextColor = theme.colorScheme.onSurface; // Use theme onSurface color for Google button
    final Color shadowColor = Colors.black.withOpacity(0.2); // General shadow color

    return Container(
      color: Colors.white, // Fixed to white background
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
              children: [
                // Error Message
                if (error != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Colors.red, // Error color can remain red
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Email Field
                buildCustomTextField(
                  label: 'Email',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  focusNode: emailFocusNode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                  onObscureTextToggle: (value) {},
                  theme: theme, // Pass theme
                ),

                // Password Field
                buildCustomTextField(
                  label: 'Password',
                  controller: passwordController,
                  obscureText: obscurePassword,
                  keyboardType: TextInputType.visiblePassword,
                  isPasswordField: true,
                  focusNode: passwordFocusNode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  onObscureTextToggle: onObscurePasswordToggle,
                  theme: theme, // Pass theme
                ),

                SizedBox(height: 32.h),

                // Login Button
                buildCustomActionButton(
                  text: 'Login',
                  bgColor: Colors.white, // Fixed to white
                  shadowColor: Colors.black.withOpacity(0.2), // Fixed shadow
                  textColor: Colors.black, // Fixed to black
                  onPressed: onLoginPressed,
                  isLoading: isLoginLoading,
                ),

                SizedBox(height: 18.h),

                // Google Sign-In Button
                buildCustomActionButton(
                  text: 'Sign in with Google',
                  bgColor: Colors.white, // Fixed to white
                  shadowColor: Colors.black.withOpacity(0.2), // Fixed shadow
                  textColor: Colors.black, // Fixed to black
                  onPressed: onGoogleSignInPressed,
                  isLoading: isGoogleSignInLoading,
                  leadingIcon: Image.asset(
                    'Assets/google.png',
                    height: 24.h,
                    width: 24.w,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: 18.h),

                // Toggle Sign Up
                GestureDetector(
                  onTap: onToggleSignUp,
                  child: Text(
                    'Don’t have an account? Sign Up',
                    style: TextStyle(
                      fontSize: 16.0.sp,
                      color: Colors.black, // Fixed to black
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



