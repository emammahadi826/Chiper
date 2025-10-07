import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chiper/services/secret_code_service.dart';

class SecretCodeChangePage extends StatefulWidget {
  const SecretCodeChangePage({super.key});

  @override
  State<SecretCodeChangePage> createState() => _SecretCodeChangePageState();
}

class _SecretCodeChangePageState extends State<SecretCodeChangePage> {
  final TextEditingController _currentCodeController = TextEditingController();
  final TextEditingController _newCodeController = TextEditingController();
  bool _isCurrentCodeCorrect = false;
  final SecretCodeService _secretCodeService = SecretCodeService();

  OverlayEntry? _overlayEntry;
  Timer? _popupTimer;

  @override
  void dispose() {
    _currentCodeController.dispose();
    _newCodeController.dispose();
    _overlayEntry?.remove(); // Ensure overlay is removed on dispose
    _popupTimer?.cancel(); // Cancel timer on dispose
    super.dispose();
  }

  Future<void> _verifyCurrentCode() async {
    final storedCode = await _secretCodeService.getSecretCode();
    if (_currentCodeController.text == storedCode) {
      setState(() {
        _isCurrentCodeCorrect = true;
      });
    } else {
      if (mounted) {
        _showCustomPopup('Incorrect current secret code.');
      }
    }
  }

  Future<void> _setNewSecretCode() async {
    final newCode = _newCodeController.text;
    if (newCode.length > 6 || !RegExp(r'^[0-9]+$').hasMatch(newCode)) {
      if (mounted) {
        _showCustomPopup('New code must be up to 6 digits and contain only numbers.');
      }
      return;
    }

    await _secretCodeService.setSecretCode(newCode);
    if (mounted) {
      _showCustomPopup('Secret code updated successfully!');
      Navigator.pop(context); // Go back after successful update
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
    final cardColor = theme.cardColor;
    final shadowColor = Colors.black.withOpacity(0.08);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Change Secret Code',
          style: GoogleFonts.righteous(
            textStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(fontSize: 24.sp),
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: mainColor, size: 24.r),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isCurrentCodeCorrect) ...[
              _buildInputField(
                controller: _currentCodeController,
                labelText: 'Current Secret Code',
                isObscure: true,
                theme: theme,
              ),
              SizedBox(height: 20.h),
              _buildButton(
                onPressed: _verifyCurrentCode,
                text: 'Verify Code',
                theme: theme,
              ),
            ] else ...[
              _buildInputField(
                controller: _newCodeController,
                labelText: 'New Secret Code (up to 6 digits)',
                isObscure: true,
                maxLength: 6,
                theme: theme,
              ),
              SizedBox(height: 20.h),
              _buildButton(
                onPressed: _setNewSecretCode,
                text: 'Set New Code',
                theme: theme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    bool isObscure = false,
    int? maxLength,
    required ThemeData theme,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: isObscure,
      maxLength: maxLength,
      style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16.sp),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 16.sp),
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5), width: 1.5),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.5), width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: theme.brightness == Brightness.light ? Colors.black : Colors.white, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 12.0.h, horizontal: 0),
        counterText: "", // Hide the counter text for maxLength
      ),
    );
  }

  Widget _buildButton({
    required VoidCallback onPressed,
    required String text,
    required ThemeData theme,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.cardColor,
          foregroundColor: theme.colorScheme.onSurface,
          padding: EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 12.h,
          ),
          fixedSize: Size(350.w, 50.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          elevation: 3,
          shadowColor: theme.primaryColor.withOpacity(0.2),
        ),
        child: Text(
          text,
          style: GoogleFonts.montserrat(
            textStyle: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),      ),
    );
  }
}
