import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chiper/pc_setting/secret_code_change/secret_code_change_page.dart';

class PcSettingPage extends StatefulWidget {
  const PcSettingPage({super.key});

  @override
  State<PcSettingPage> createState() => _PcSettingPageState();
}

class _PcSettingPageState extends State<PcSettingPage> {
  

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), // Back button
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'PC Settings',
          style: theme.appBarTheme.titleTextStyle,
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Material(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12.0.r),
              elevation: 0,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecretCodeChangePage(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12.0.r),
                splashColor: theme.colorScheme.onSurface.withOpacity(0.1),
                highlightColor: theme.colorScheme.onSurface.withOpacity(0.05),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12.0.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8.0.r,
                        offset: Offset(0, 4.r),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_reset, color: theme.colorScheme.onSurface, size: 24.r),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Text(
                          'Change Secret Code',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
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
          ),
        ],
      ),
    );
  }
}