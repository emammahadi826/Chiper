import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chiper/tasks/task_edit_page.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chiper/Models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chiper/tasks/task_updater.dart'; // New import

class TaskHomePage extends StatefulWidget {
  const TaskHomePage({super.key});

  @override
  State<TaskHomePage> createState() => _TaskHomePageState();
}

class _TaskHomePageState extends State<TaskHomePage> with SingleTickerProviderStateMixin {
  late Box<Task> _taskBox; // Keep this for ValueListenableBuilder
  late TaskUpdaterService _taskUpdaterService;
  Offset _fabOffset = Offset(0, 0); // Default position
  static const String _fabPositionKey = 'fab_position';
  bool _isInitializing = true; // New flag
  late TabController _tabController;
  final Map<String, bool> _isFadingOut = {}; // Track tasks that are fading out

  @override
  void initState() {
    super.initState();
    _loadFabPosition();
    _initServices();
    _tabController = TabController(length: 2, vsync: this); // Initialize TabController
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose TabController
    super.dispose();
  }

  Future<void> _loadFabPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final double? dx = prefs.getDouble('${_fabPositionKey}_dx');
    final double? dy = prefs.getDouble('${_fabPositionKey}_dy');
    if (dx != null && dy != null) {
      setState(() {
        _fabOffset = Offset(dx, dy);
      });
    }
  }

  Future<void> _saveFabPosition(Offset offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_fabPositionKey}_dx', offset.dx);
    await prefs.setDouble('${_fabPositionKey}_dy', offset.dy);
  }

  Future<void> _initServices() async {
    _taskBox = await Hive.openBox<Task>('tasks');
    _taskUpdaterService = TaskUpdaterService(_taskBox);
    if (mounted) {
      setState(() {
        _isInitializing = false;
      });
    }
    await _taskUpdaterService.syncTasks();
  }

  void _addTask(String taskContent) async {
    final newTask = Task.createNew(content: taskContent);
    await _taskUpdaterService.addTask(newTask);
    setState(() {}); // Update UI immediately
  }

  void _toggleTaskCompletion(Task task) async {
    task.isCompleted = !task.isCompleted;
    await _taskUpdaterService.updateTask(task);
    setState(() {});
  }

  Future<void> _deleteTask(Task task) async {
    await _taskUpdaterService.deleteTask(task.id);
    setState(() {}); // Update UI immediately
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0, // Remove app bar height
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: _isInitializing
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onSurface, // Theme-aware color
                ),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(false), // Current Tasks
                _buildTaskList(true), // Completed Tasks
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskEditPage(),
            ),
          );
          if (newTask != null) {
            _addTask(newTask);
          }
        },
        backgroundColor: theme.cardColor,
        child: Icon(Icons.add, color: theme.colorScheme.onSurface),
      ),
    );
  }

  Widget _buildTaskList(bool isCompletedTab) {
    final theme = Theme.of(context);
    final mainColor = theme.colorScheme.onSurface;

    return ValueListenableBuilder<Box<Task>>(
      valueListenable: _taskBox.listenable(),
      builder: (context, box, _) {
        final allTasks = box.values.toList().cast<Task>();
        final filteredTasks = allTasks.where((task) => task.isCompleted == isCompletedTab).toList();
        filteredTasks.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // Sort by timestamp

        if (filteredTasks.isEmpty) {
          return Center(
            child: Text(
              isCompletedTab
                  ? 'No completed tasks yet. Keep up the good work!'
                  : 'No incomplete tasks. Add one using the + button!',
              style: GoogleFonts.roboto(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _taskUpdaterService.syncTasks(),
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              final isDarkMode = theme.brightness == Brightness.dark;

              return Dismissible(
                key: Key(task.id),
                direction: isCompletedTab ? DismissDirection.endToStart : DismissDirection.startToEnd, // Conditional swipe direction
                onDismissed: (direction) {
                  _deleteTask(task);
                },
                background: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: theme.brightness == Brightness.light ? Colors.black : Colors.white, // Inverted color
                  ),
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(left: 20.w),
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: theme.brightness == Brightness.light ? Colors.white : Colors.black, size: 30.r), // Inverted icon color
                      SizedBox(width: 10.w),
                      Text('Delete', style: TextStyle(color: theme.brightness == Brightness.light ? Colors.white : Colors.black, fontSize: 18.sp)), // Inverted text color
                    ],
                  ),
                ),
                secondaryBackground: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: theme.brightness == Brightness.light ? Colors.black : Colors.white, // Inverted color
                  ),
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Delete', style: TextStyle(color: theme.brightness == Brightness.light ? Colors.white : Colors.black, fontSize: 18.sp)), // Inverted text color
                      SizedBox(width: 10.w),
                      Icon(Icons.delete, color: theme.brightness == Brightness.light ? Colors.white : Colors.black, size: 30.r), // Inverted icon color
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 8.h), // Reduced vertical padding
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.0),
                      onTap: () {
                        // No specific action on tap for the whole item, checkbox handles completion
                      },
                      child: Container(
                        height: 55.h,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8.0.r,
                              offset: Offset(0, 4.r),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                        child: Row(
                          children: [
                            Checkbox(
                              value: task.isCompleted,
                              onChanged: (bool? newValue) {
                                _toggleTaskCompletion(task);
                              },
                              activeColor: isDarkMode ? Colors.white : Colors.black,
                              checkColor: isDarkMode ? Colors.black : Colors.white,
                              side: BorderSide(
                                color: isDarkMode ? Colors.white : Colors.black,
                                width: 2.0,
                              ),
                            ),
                            SizedBox(width: 16.w), // Spacing between checkbox and text
                            Expanded(
                              child: Text(
                                task.content,
                                style: GoogleFonts.righteous(
                                  textStyle: TextStyle(
                                    fontSize: 18.sp, // Adjusted font size for tasks
                                    fontWeight: FontWeight.w500, // Adjusted font weight
                                    color: task.isCompleted
                                        ? theme.hintColor // Use hintColor for completed tasks
                                        : mainColor, // Use mainColor for incomplete tasks
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                maxLines: 1, // Allow up to 1 line for task content
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isCompletedTab) // Only show complete button for current tasks
                              IconButton(
                                icon: Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                                onPressed: () {
                                  _toggleTaskCompletion(task);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}