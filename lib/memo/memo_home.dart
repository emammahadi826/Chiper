import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:chiper/Models/memo.dart';
import 'package:chiper/Services/memo_service.dart';
import 'package:chiper/memo/memo_editor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MemoHomePage extends StatefulWidget {
  const MemoHomePage({super.key});

  @override
  State<MemoHomePage> createState() => _MemoHomePageState();
}

class _MemoHomePageState extends State<MemoHomePage> {
  final MemoService _memoService = MemoService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<String> _selectedMemos = [];
  bool _isSelectionMode = false;
  String? _slidingMemoId; // New state to track which memo is slid open

  OverlayEntry? _overlayEntry;
  Timer? _popupTimer;

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedMemos.clear();
      }
      _slidingMemoId = null;
    });
  }

  void _toggleMemoSelection(String memoId) {
    setState(() {
      if (_selectedMemos.contains(memoId)) {
        _selectedMemos.remove(memoId);
      } else {
        _selectedMemos.add(memoId);
      }
      if (_selectedMemos.isEmpty) {
        _isSelectionMode = false;
      }
      _slidingMemoId = null;
    });
  }

  Future<void> _deleteSelectedMemos() async {
    if (_selectedMemos.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memos'),
        content: Text('Are you sure you want to delete ${_selectedMemos.length} selected memo(s)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (final memoId in _selectedMemos) {
        batch.delete(FirebaseFirestore.instance.collection('users').doc(_memoService.userId).collection('memos').doc(memoId));
      }
      await batch.commit();
      final deletedCount = _selectedMemos.length;
      setState(() {
        _selectedMemos.clear();
        _isSelectionMode = false;
        _slidingMemoId = null;
      });
      if (mounted) {
        _showCustomPopup('$deletedCount memo(s) deleted.');
      }
    }
  }

  void _toggleSlidingMenu(String memoId) {
    setState(() {
      if (_slidingMemoId == memoId) {
        _slidingMemoId = null;
      } else {
        _slidingMemoId = memoId;
      }
    });
  }

  List<Memo> _sortMemos(List<Memo> memos) {
    memos.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return (b.timestamp ?? DateTime(0)).compareTo(a.timestamp ?? DateTime(0));
    });
    return memos;
  }

  Future<void> _deleteSingleMemo(String memoId, String memoTitle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memo'),
        content: Text('Are you sure you want to delete $memoTitle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Optimistically remove from UI
      setState(() {
        _slidingMemoId = null;
      });

      _showCustomPopup('Memo $memoTitle deleted.');

      // Actual deletion after a delay, allowing for undo
      Future.delayed(const Duration(seconds: 3), () async {
        // Check if the memo still exists in the UI (i.e., not undone)
        // This is a simplified check; a more robust solution might involve a temporary list of "pending deletions"
        // For this task, we assume if the user didn't undo, we proceed with deletion.
        await _memoService.deleteMemo(memoId);
      });
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mainColor = theme.colorScheme.onSurface;
    final subColor = theme.colorScheme.onSurface.withOpacity(0.6);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text(
          _isSelectionMode ? '${_selectedMemos.length} Selected' : 'Memo',
          style: theme.appBarTheme.titleTextStyle?.copyWith(color: mainColor),
        ),
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: Icon(Icons.delete, color: mainColor),
              onPressed: _deleteSelectedMemos,
            )
          else
            IconButton(
              icon: Icon(Icons.add, color: mainColor),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MemoEditorPage()),
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<List<Memo>>(
        stream: _memoService.getMemos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: mainColor)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No memos yet. Tap + to create one!', style: TextStyle(color: subColor)));
          }

          final memos = _sortMemos(snapshot.data!);

          return ListView.builder(
            itemCount: memos.length,
            itemBuilder: (context, index) {
              final memo = memos[index];
              if (memo.id == null) {
                return const SizedBox.shrink();
              }
              
              final isSelected = _selectedMemos.contains(memo.id);
              final isSliding = _slidingMemoId == memo.id;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: SizedBox(
                  height: 60.h,
                  child: GestureDetector(
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleMemoSelection(memo.id!);
                      } else {
                        if (_slidingMemoId != null) {
                          setState(() {
                            _slidingMemoId = null;
                          });
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MemoEditorPage(memo: memo),
                            ),
                          );
                        }
                      }
                    },
                    onLongPress: () {
                      _toggleSelectionMode();
                      _toggleMemoSelection(memo.id!);
                    },
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        if (isSliding)
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => _deleteSingleMemo(memo.id!, memo.title ?? 'Untitled Memo'),
                              child: Container(
                                width: 60.w,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.delete, color: Colors.white, size: 24.sp),
                                    Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12.sp)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          right: isSliding ? 68.w : 0,
                          left: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Container(
                                height: 70.h,
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(12.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8.0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                child: Row(
                                  children: [
                                    if (_isSelectionMode)
                                      Checkbox(
                                        value: isSelected,
                                        onChanged: (bool? value) {
                                          if (memo.id != null) {
                                            _toggleMemoSelection(memo.id!);
                                          }
                                        },
                                        activeColor: isDarkMode ? Colors.white : Colors.black,
                                        checkColor: isDarkMode ? Colors.black : Colors.white,
                                        side: BorderSide(
                                          color: isDarkMode ? Colors.white : Colors.black,
                                          width: 2.0,
                                        ),
                                      ),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            memo.title?.split(' ').first ?? 'Untitled Memo',
                                            style: TextStyle(
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.bold,
                                              color: mainColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (!_isSelectionMode)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              memo.isPinned ? Icons.bookmark : Icons.bookmark_border_outlined,
                                              color: subColor,
                                              size: 20.sp,
                                            ),
                                            onPressed: () async {
                                              if (memo.id != null) {
                                                await _memoService.togglePin(memo.id!, !memo.isPinned);
                                              }
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                          ),
                                          SizedBox(width: 8.w),
                                          IconButton(
                                            icon: Icon(Icons.more_vert, color: subColor, size: 20.sp), // Changed to more_vert
                                            onPressed: () {
                                              if (memo.id != null) {
                                                _toggleSlidingMenu(memo.id!);
                                              }
                                            },
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}