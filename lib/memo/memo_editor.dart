import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chiper/Models/memo.dart';
import 'package:chiper/Services/memo_service.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart'; // Import for TapGestureRecognizer

class MemoEditorPage extends StatefulWidget {
  final Memo? memo;

  const MemoEditorPage({super.key, this.memo});

  @override
  State<MemoEditorPage> createState() => _MemoEditorPageState();
}

class _MemoEditorPageState extends State<MemoEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final MemoService _memoService = MemoService();
  bool _isSaving = false;

  OverlayEntry? _overlayEntry;
  Timer? _popupTimer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memo?.title ?? '');
    _contentController = TextEditingController(text: widget.memo?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveMemo() async {
    if (_isSaving) return; // Prevent multiple saves

    if (mounted) {
      setState(() {
        _isSaving = true;
      });
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      if (widget.memo != null && widget.memo!.id != null) {
        await _memoService.deleteMemo(widget.memo!.id!);
      }
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
      return;
    }

    final memo = Memo(
      id: widget.memo?.id,
      title: title.isEmpty ? 'Untitled' : title,
      content: content,
      timestamp: widget.memo?.timestamp ?? DateTime.now(),
      isPinned: widget.memo?.isPinned ?? false,
    );

    try {
      await _memoService.saveMemo(memo);
      if (mounted) {
        _showCustomPopup('Memo saved!');
      }
    } catch (e) {
      if (mounted) {
        _showCustomPopup('Error saving memo: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
          left: (MediaQuery.of(context).size.width - 200.w) / 2, // Center horizontally with new width
          child: SizedBox( // Added SizedBox to control exact dimensions
            width: 200.w, // Increased width
            height: 40.h, // Decreased height
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

  // Function to detect and style URLs
  TextSpan _buildTextSpanWithLinks(String text, Color textColor, Color linkColor, TextStyle textStyle) {
    final List<TextSpan> spans = [];
    final RegExp urlRegex = RegExp(r'https?://[\S]+');

    text.splitMapJoin(
      urlRegex,
      onMatch: (Match match) {
        final String url = match.group(0)!;
        spans.add(
          TextSpan(
            text: url,
            style: TextStyle(color: linkColor, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  if (mounted) {
                    _showCustomPopup('Could not launch $url');
                  }
                }
              },
          ),
        );
        return '';
      },
      onNonMatch: (String nonMatch) {
        spans.add(TextSpan(text: nonMatch, style: textStyle.copyWith(color: textColor)));
        return '';
      },
    );
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainColor = theme.colorScheme.onSurface;
    final subColor = theme.colorScheme.onSurface.withOpacity(0.6);
    final linkColor = Colors.blue; // Use a distinct blue color for links

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Use scaffoldBackgroundColor for consistency
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close, color: mainColor),
          onPressed: () async { // Made onPressed async
            await _saveMemo(); // Call _saveMemo before popping
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _saveMemo();
              // Ensure the UI updates to show "Save" before popping
              if (mounted) {
                await Future.delayed(Duration.zero); // Allow setState to rebuild
                Navigator.pop(context);
              }
            },
            child: _isSaving
                ? SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: CircularProgressIndicator(strokeWidth: 2.r, color: mainColor),
                  )
                : Text('Save', style: TextStyle(color: mainColor, fontSize: 20.sp)),
          ),
        ],
        title: null, // No title in AppBar
        backgroundColor: theme.appBarTheme.backgroundColor, // Use theme's surface color for AppBar background
        elevation: 0.0, // No shadow for AppBar
        scrolledUnderElevation: 0.0, // Ensure no elevation when scrolled under
        surfaceTintColor: Colors.transparent, // Set surface tint color to transparent
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: theme.textTheme.headlineSmall?.copyWith(color: mainColor), // Use theme text style
              decoration: InputDecoration(
                hintText: 'Title...',
                hintStyle: theme.textTheme.headlineSmall?.copyWith(color: subColor), // Use theme text style for hint
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: subColor.withOpacity(0.5), width: 1.r),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: mainColor, width: 2.r),
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
              ),
              maxLines: null, // Allow title to expand if needed
              keyboardType: TextInputType.multiline,
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: _contentController,
              style: theme.textTheme.bodyLarge?.copyWith(color: mainColor), // Use theme text style
              decoration: InputDecoration(
                hintText: 'Content...',
                hintStyle: theme.textTheme.bodyLarge?.copyWith(color: subColor), // Use theme text style for hint
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null, // Allows multiple lines
              keyboardType: TextInputType.multiline,
              expands: false, // Set to false as it's inside SingleChildScrollView
            ),
          ],
        ),
      ),
    );
  }
}

