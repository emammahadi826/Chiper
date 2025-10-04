import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TaskEditPage extends StatefulWidget {
  final String? initialTask;

  const TaskEditPage({super.key, this.initialTask});

  @override
  State<TaskEditPage> createState() => _TaskEditPageState();
}

class _TaskEditPageState extends State<TaskEditPage> {
  late TextEditingController _taskController;

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController(text: widget.initialTask);
  }

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialTask == null ? 'New Task' : 'Edit Task',
          style: theme.appBarTheme.titleTextStyle,
        ),
        elevation: 0,
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: theme.appBarTheme.iconTheme,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0.r),
        child: Column(
          children: [
            TextFormField(
              controller: _taskController,
              autofocus: true,
              style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16.sp),
              decoration: InputDecoration(
                labelText: 'Enter your task...',
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
              ),
              maxLines: null, // Allow multiple lines
              keyboardType: TextInputType.multiline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Task cannot be empty';
                }
                return null;
              },
            ),

            SizedBox(height: 20.h),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _taskController.text.trim());
                },
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
                  'Save Task',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
