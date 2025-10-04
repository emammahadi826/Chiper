// File: sign_up.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'log.dart'; // Import helper widgets

class SignUpPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final ValueChanged<bool> onObscurePasswordToggle;
  final ValueChanged<bool> onObscureConfirmPasswordToggle;
  final VoidCallback onSignUpPressed;
  final VoidCallback onToggleLogin;
  final String? error;
  final bool isLoading;
  final FocusNode nameFocusNode;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final FocusNode confirmPasswordFocusNode;

  const SignUpPage({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onObscurePasswordToggle,
    required this.onObscureConfirmPasswordToggle,
    required this.onSignUpPressed,
    required this.onToggleLogin,
    required this.error,
    required this.isLoading,
    required this.nameFocusNode,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.confirmPasswordFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color primaryButtonBgColor = theme.colorScheme.surface;
    final Color primaryButtonTextColor = theme.colorScheme.onSurface;
    final Color shadowColor = Colors.black.withOpacity(0.2);

    return Container(
      color: Colors.white, // Fixed to white background
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Vertical center
              crossAxisAlignment: CrossAxisAlignment.center, // Horizontal center
              children: [
                // Error message
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

                // Name field
                buildCustomTextField(
                  label: 'Name',
                  controller: nameController,
                  focusNode: nameFocusNode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                  onObscureTextToggle: (value) {},
                  theme: theme,
                ),

                // Email field
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
                  theme: theme,
                ),

                // Password field
                buildCustomTextField(
                  label: 'Password',
                  controller: passwordController,
                  obscureText: obscurePassword,
                  keyboardType: TextInputType.text,
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
                  theme: theme,
                ),

                // Confirm password field
                buildCustomTextField(
                  label: 'Confirm Password',
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  keyboardType: TextInputType.text,
                  isPasswordField: true,
                  focusNode: confirmPasswordFocusNode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm password is required';
                    }
                    if (value != passwordController.text) {
                      return 'Passwords don\'t match';
                    }
                    return null;
                  },
                  onObscureTextToggle: onObscureConfirmPasswordToggle,
                  theme: theme,
                ),

                SizedBox(height: 32.h),

                // Sign Up button
                buildCustomActionButton(
                  text: 'Sign Up',
                  bgColor: Colors.white, // Fixed to white
                  shadowColor: Colors.black.withOpacity(0.2), // Fixed shadow
                  textColor: Colors.black, // Fixed to black
                  onPressed: onSignUpPressed,
                  isLoading: isLoading,
                ),

                SizedBox(height: 18.h),

                // Toggle Login
                GestureDetector(
                  onTap: onToggleLogin,
                  child: Text(
                    'Already have an account? Login',
                    style: TextStyle(
                      fontSize: 16.0.sp,
                      color: Colors.black,
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