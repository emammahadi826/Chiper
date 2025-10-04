import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalculatorHistoryPage extends StatefulWidget {
  const CalculatorHistoryPage({super.key});

  @override
  State<CalculatorHistoryPage> createState() => _CalculatorHistoryPageState();
}

class _CalculatorHistoryPageState extends State<CalculatorHistoryPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  OverlayEntry? _overlayEntry;
  Timer? _popupTimer;

  User? get currentUser => _auth.currentUser;

  final Set<String> _locallyDeletedDocIds = {};

  final bool _isClearing = false;
  final bool _hasClearedOnce = false; // New flag to track if clear has been initiated
  String? _slidingHistoryId;

  Future<void> _togglePinStatus(String docId, bool currentPinnedStatus) async {
    if (currentUser == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('calculator_history')
          .doc(docId)
          .update({'isPinned': !currentPinnedStatus});
    } catch (e) {
      print('Error updating pin status: $e');
      if (mounted) {
        _showCustomPopup('Failed to update pin status.');
      }
    }
  }

  void _toggleSlidingMenu(String docId) {
    setState(() {
      if (_slidingHistoryId == docId) {
        _slidingHistoryId = null;
      } else {
        _slidingHistoryId = docId;
      }
    });
  }

  Future<void> _deleteSingleHistoryItem(String docId) async {
    if (currentUser == null) return;

    setState(() {
      _locallyDeletedDocIds.add(docId);
      _slidingHistoryId = null;
    });

    _showCustomPopup('History deleted');

    Future.delayed(const Duration(seconds: 5), () async {
      if (_locallyDeletedDocIds.contains(docId)) {
        try {
          await _firestore
              .collection('users')
              .doc(currentUser!.uid)
              .collection('calculator_history')
              .doc(docId)
              .delete();
        } catch (e) {
          print('Error deleting history item: $e');
          if (mounted) {
            _showCustomPopup('Failed to delete history item.');
          }
        }
      }
    });
  }

  Future<void> _clearHistory() async {
    if (currentUser == null || _isClearing) return;

    // Fetch all documents to identify pinned vs unpinned
    final allDocs = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('calculator_history')
        .get();

    // Filter out pinned items; only unpinned items will be marked for local deletion
    final unpinnedDocs = allDocs.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return !(data['isPinned'] ?? false); // If 'isPinned' is null, treat as unpinned
    }).toList();

    setState(() {
      _locallyDeletedDocIds.clear(); // Clear previous local deletions
      for (var doc in unpinnedDocs) {
        _locallyDeletedDocIds.add(doc.id);
      }
    });

    _showCustomPopup('Unpinned history cleared!');

    Future.delayed(const Duration(seconds: 5), () async {
      if (_locallyDeletedDocIds.isNotEmpty) {
        final batch = _firestore.batch();
        final historyRef = _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .collection('calculator_history');

        // Only delete documents that were marked for local deletion (i.e., unpinned)
        for (String docId in _locallyDeletedDocIds) {
          batch.delete(historyRef.doc(docId));
        }
        await batch.commit();
        setState(() {
          _locallyDeletedDocIds.clear(); // Clear after successful commit
        });
      }
    });
  }

  void _showCustomPopup(String message) {
    // Ensure any existing popup is removed and its timer cancelled
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null; // Explicitly set to null after removal
    }
    _popupTimer?.cancel(); // Cancel any pending timer

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        final Color backgroundColor = isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05); // 95% transparent
        final Color textColor = isDarkMode ? Colors.white : Colors.black; // Text color based on theme

        return Positioned(
          bottom: MediaQuery.of(context).size.height * 0.10, // Near 90% from top (10% from bottom)
          left: (MediaQuery.of(context).size.width - 250.w) / 2, // Center horizontally with new width
          child: SizedBox( // Added SizedBox to control exact dimensions
            width: 250.w, // Consistent width
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12.0.r),
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h), // Adjusted padding for new size
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
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
      _overlayEntry = null; // Set to null when the popup disappears
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainColor = theme.textTheme.bodyLarge!.color;
    final subColor = theme.textTheme.bodyMedium!.color;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calculation History',
          style: theme.appBarTheme.titleTextStyle,
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: theme.appBarTheme.elevation,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.foregroundColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          _buildClearHistoryButton(theme),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(currentUser!.uid)
                  .collection('calculator_history')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No calculation history yet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  );
                }

                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) => !_locallyDeletedDocIds.contains(doc.id)).toList();

                // Separate pinned and unpinned items based on Firestore data
                final pinnedItems = filteredDocs.where((doc) => (doc.data() as Map<String, dynamic>)['isPinned'] == true).toList();
                final unpinnedItems = filteredDocs.where((doc) => (doc.data() as Map<String, dynamic>)['isPinned'] != true).toList();

                // Sort pinned items by timestamp (descending) and unpinned items by timestamp (descending)
                pinnedItems.sort((a, b) => (b.data() as Map<String, dynamic>)['timestamp'].compareTo((a.data() as Map<String, dynamic>)['timestamp']));
                unpinnedItems.sort((a, b) => (b.data() as Map<String, dynamic>)['timestamp'].compareTo((a.data() as Map<String, dynamic>)['timestamp']));

                // Display pinned items first, then unpinned
                final displayItems = [...pinnedItems, ...unpinnedItems];


                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  itemCount: displayItems.length,
                  itemBuilder: (context, index) {
                    final doc = displayItems[index];
                    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                    String expression = data['expression'] ?? 'N/A';
                    String result = data['result'] ?? 'N/A';
                    final docId = doc.id;
                    final isPinned = data['isPinned'] ?? false;

                    final isSliding = _slidingHistoryId == docId;

                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: SizedBox(
                        height: 90.h, // Increased item height
                        child: GestureDetector(
                          onTap: () {
                            if (_slidingHistoryId != null) {
                              setState(() {
                                _slidingHistoryId = null;
                              });
                            } else {
                              Navigator.pop(context, {
                                'expression': expression,
                                'result': result,
                              });
                            }
                          },
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              if (isSliding)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: InkWell(
                                          onTap: () => _togglePinStatus(docId, isPinned),
                                          borderRadius: BorderRadius.circular(12.0), // Match container border radius
                                          child: Container(
                                            width: 60.w,
                                            decoration: BoxDecoration(
                                              color: theme.cardColor,
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                isPinned ? Icons.bookmark : Icons.bookmark_border_outlined,
                                                color: theme.textTheme.bodyLarge!.color,
                                                size: 24.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ), // Closing parenthesis and comma for the first Expanded
                                      Expanded(
                                        child: InkWell(
                                          onTap: isPinned
                                              ? () {
                                                  _showCustomPopup('Unpin item to delete.');
                                                }
                                              : () => _deleteSingleHistoryItem(docId),
                                          borderRadius: BorderRadius.circular(12.0), // Match container border radius
                                          child: Container(
                                            width: 60.w,
                                            decoration: BoxDecoration(
                                              color: theme.cardColor,
                                              borderRadius: BorderRadius.circular(12.0),
                                            ),
                                            child: Center(
                                              child: Icon(
                                                Icons.delete,
                                                color: isPinned ? theme.textTheme.bodyLarge!.color!.withOpacity(0.4) : theme.textTheme.bodyLarge!.color,
                                                size: 24.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
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
                                      height: 90.h,
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(12.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 4.0,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  expression,
                                                  style: TextStyle(
                                                    fontSize: 16.sp, // Adjusted font size
                                                    color: subColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 8.h), // Adjusted spacing
                                                Text(
                                                  '= $result',
                                                  style: TextStyle(
                                                    fontSize: 22.sp, // Adjusted font size
                                                    fontWeight: FontWeight.bold,
                                                    color: mainColor,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.more_vert, color: subColor),
                                            iconSize: 20.sp,
                                            onPressed: () => _toggleSlidingMenu(docId),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
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
          ),
        ],
      ),
    );
  }

  Widget _buildClearHistoryButton(ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('calculator_history')
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        final bool hasHistory = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        if (!hasHistory) {
          return const SizedBox.shrink(); 
        }

        return TextButton(
          onPressed: _clearHistory,
          child: Text(
            'Clear All',
            style: TextStyle(
              color: theme.textTheme.bodyLarge!.color,
              fontSize: 16.sp,
            ),
          ),
        );
      },
    );
  }
}