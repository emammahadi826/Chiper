import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

// A custom track shape for the slider that mimics the gradient-like effect.
class GradientSliderTrackShape extends RoundedRectSliderTrackShape {
  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 2,
  }) {
    final Rect trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    // Colors from the theme
    final Color activeTrackColor = sliderTheme.activeTrackColor!;
    final Color inactiveTrackColor = sliderTheme.inactiveTrackColor!;

    // Paint the inactive part
    final Paint inactivePaint = Paint()..color = inactiveTrackColor;
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, Radius.circular(trackRect.height / 2)),
      inactivePaint,
    );

    // Paint the active part
    final Paint activePaint = Paint()..color = activeTrackColor;
    final Rect activeTrackRect = Rect.fromLTRB(
      trackRect.left,
      trackRect.top,
      thumbCenter.dx,
      trackRect.bottom,
    );
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(activeTrackRect, Radius.circular(trackRect.height / 2)),
      activePaint,
    );
  }
}

// A custom thumb shape that adds a glowing animation when active.
class GlowingSliderThumbShape extends RoundSliderThumbShape {
  final Animation<double> glowAnimation;

  const GlowingSliderThumbShape({
    required this.glowAnimation,
    super.enabledThumbRadius,
  });

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    final Color thumbColor = sliderTheme.thumbColor!;
    final Color glowColor = sliderTheme.overlayColor!;

    // Draw the glow effect
    final double glowRadius = enabledThumbRadius * (1 + glowAnimation.value * 0.5);
    final Paint glowPaint = Paint()
      ..color = glowColor.withOpacity(0.3 * (1 - glowAnimation.value))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 0.5);
    canvas.drawCircle(center, glowRadius, glowPaint);

    // Draw the thumb itself
    final Paint thumbPaint = Paint()..color = thumbColor;
    canvas.drawCircle(center, enabledThumbRadius, thumbPaint);
  }
}

// A modern volume control panel widget with a slider, icons, and a tooltip.
class VolumeControlPanel extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const VolumeControlPanel({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<VolumeControlPanel> createState() => _VolumeControlPanelState();
}

class _VolumeControlPanelState extends State<VolumeControlPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _glowAnimationController;
  late final Animation<double> _glowAnimation;
  
  bool _isTooltipVisible = false;
  double _sliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.value;

    _glowAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowAnimationController, curve: Curves.easeOut),
    );

    _glowAnimation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _glowAnimationController.reverse();
      }
    });
  }

  @override
  void didUpdateWidget(covariant VolumeControlPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _sliderValue) {
      setState(() {
        _sliderValue = widget.value;
      });
    }
  }

  @override
  void dispose() {
    _glowAnimationController.dispose();
    super.dispose();
  }

  void _showTooltip() {
    setState(() {
      _isTooltipVisible = true;
    });
  }

  void _hideTooltip() {
    setState(() {
      _isTooltipVisible = false;
    });
  }

  void _triggerGlow() {
    _glowAnimationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Define colors based on the current theme
    final panelBgColor = theme.cardColor;
    final iconColor = colorScheme.onSurface.withOpacity(0.7);
    final shadowColor = theme.shadowColor.withOpacity(0.1);
    final sliderActiveColor = colorScheme.onSurface;
    final sliderInactiveColor = colorScheme.onSurface.withOpacity(0.3);
    final tooltipBgColor = colorScheme.secondary;
    final tooltipTextColor = colorScheme.onSecondary;

    // Calculate tooltip position
    double tooltipLeft = (MediaQuery.of(context).size.width - 40.w) * (_sliderValue / 100) - 25; // 40.w for horizontal padding, 25 for half tooltip width

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
      decoration: BoxDecoration(
        color: panelBgColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 15.r,
            offset: Offset(0, 4.r),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Row(
            children: [
              Icon(Icons.volume_down, color: iconColor, size: 24.r),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: sliderActiveColor,
                    inactiveTrackColor: sliderInactiveColor,
                    trackHeight: 6.h,
                    thumbColor: sliderActiveColor,
                    overlayColor: sliderActiveColor, // Used for glow color
                    trackShape: GradientSliderTrackShape(),
                    thumbShape: GlowingSliderThumbShape(
                      enabledThumbRadius: 9.r,
                      glowAnimation: _glowAnimation,
                    ),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                  ),
                  child: Slider(
                    value: _sliderValue,
                    min: 0.0,
                    max: 100.0, // Changed max to 100.0
                    label: _sliderValue.round().toString(), // Display raw value
                    onChanged: (newValue) {
                      setState(() {
                        _sliderValue = newValue;
                      });
                      widget.onChanged(newValue);
                      _triggerGlow();
                    },
                    onChangeStart: (_) => _showTooltip(),
                    onChangeEnd: (_) => _hideTooltip(),
                  ),
                ),
              ),
              Icon(Icons.volume_up, color: iconColor, size: 24.r),
            ],
          ),
          if (_isTooltipVisible)
            Positioned(
              left: tooltipLeft,
              top: -40.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: tooltipBgColor,
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  _sliderValue.round().toString(), // Display raw value
                  style: TextStyle(
                    color: tooltipTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


class PCToolsPage extends StatefulWidget {
  const PCToolsPage({super.key});

  @override
  State<PCToolsPage> createState() => _PCToolsPageState();
}

class _PCToolsPageState extends State<PCToolsPage> {
  double _volumeValue = 50.0; // Initial value for the single volume slider (0-100)

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Map<String, bool> _arrowStatus = {
    'up': false,
    'down': false,
    'left': false,
    'right': false,
    'middle': false,
    'hide': false,
    'lock': false,
    'tab': false,
    'mouse': false,
    'close': false, // New
    'full': false, // New
    'full_widget': false, // New
  };
  StreamSubscription? _arrowStatusSubscription;

  @override
  void initState() {
    super.initState();
    _loadPcVolume();
    _listenToArrowStatus(); // New method to listen to Firestore
  }

  @override
  void dispose() {
    _arrowStatusSubscription?.cancel(); // Cancel subscription
    super.dispose();
  }

  Future<void> _loadPcVolume() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final pcStatusDocRef = _firestore.collection('users').doc(user.uid).collection('pc').doc('pc_status');
    final snapshot = await pcStatusDocRef.get();

    if (snapshot.exists && snapshot.data() != null) {
      final data = snapshot.data()! as Map<String, dynamic>;
      if (data.containsKey('pc_volume') && data['pc_volume'] is num) {
        setState(() {
          _volumeValue = data['pc_volume'].toDouble(); // Directly use Firebase value (0-100)
        });
      }
    }
  }

  Future<void> _updatePcVolume(double volume) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final pcStatusDocRef = _firestore.collection('users').doc(user.uid).collection('pc').doc('pc_status');

    try {
      await pcStatusDocRef.set({'pc_volume': volume.round()}, SetOptions(merge: true)); // Save rounded value (0-100)
      print("PC volume updated to ${volume.round()}");
    } catch (e) {
      print("Error updating PC volume: $e");
    }
  }

  void _listenToArrowStatus() {
    final user = _auth.currentUser;
    if (user == null) return;

    final arrowDocRef = _firestore.collection('users').doc(user.uid).collection('pc').doc('pc_status');

    _arrowStatusSubscription = arrowDocRef.snapshots().listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()! as Map<String, dynamic>;
        setState(() {
          _arrowStatus['up'] = data['up'] ?? false;
          _arrowStatus['down'] = data['down'] ?? false;
          _arrowStatus['left'] = data['left'] ?? false;
          _arrowStatus['right'] = data['right'] ?? false;
          _arrowStatus['middle'] = data['middle'] ?? false;
          _arrowStatus['hide'] = data['hide'] ?? false;
          _arrowStatus['lock'] = data['lock'] ?? false;
          _arrowStatus['tab'] = data['tab'] ?? false;
          _arrowStatus['mouse'] = data['mouse'] ?? false;
          _arrowStatus['close'] = data['close'] ?? false; // New
          _arrowStatus['full'] = data['full'] ?? false; // New
          _arrowStatus['full_widget'] = data['full_widget'] ?? false; // New
        });
      }
    });
  }

  Future<void> _updateArrowStatus(String arrow, bool status) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final arrowDocRef = _firestore.collection('users').doc(user.uid).collection('pc').doc('pc_status');

    try {
      await arrowDocRef.set({arrow: status}, SetOptions(merge: true));
      print('Arrow $arrow status updated to $status');

      if (status) {
        // If setting to true, schedule setting back to false
        Future.delayed(const Duration(seconds: 2), () async {
          await arrowDocRef.set({arrow: false}, SetOptions(merge: true));
          print('Arrow $arrow status reset to false');
        });
      }
    } catch (e) {
      print('Error updating arrow $arrow status: $e');
    }
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
          'PC Tools',
          style: theme.appBarTheme.titleTextStyle,
        ),
        elevation: 0, // Consistent with CalculatorPage
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 30.0.h), // Increased vertical padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VolumeControlPanel(
              value: _volumeValue,
              onChanged: (newValue) {
                setState(() {
                  _volumeValue = newValue;
                });
                _updatePcVolume(newValue);
              },
            ),
            SizedBox(height: 40.h), // Increased padding
            Container(
              padding: EdgeInsets.all(16.r),
              margin: EdgeInsets.symmetric(horizontal: 0.w), // Adjust margin as needed
              decoration: BoxDecoration(
                color: theme.cardColor, // Use theme card color for unified background
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2), width: 1.r), // Visible border
              ),
              child: Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_upward, size: 24.r),
                    onPressed: () => _updateArrowStatus('up', true),
                    color: _arrowStatus['up']! ? theme.colorScheme.primary : theme.iconTheme.color,
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, size: 24.r),
                        onPressed: () => _updateArrowStatus('left', true),
                        color: _arrowStatus['left']! ? theme.colorScheme.primary : theme.iconTheme.color,
                      ),
                      SizedBox(width: 10.w),
                      IconButton(
                        icon: Icon(Icons.radio_button_checked, size: 24.r),
                        onPressed: () => _updateArrowStatus('middle', true),
                        color: _arrowStatus['middle']! ? theme.colorScheme.primary : theme.iconTheme.color,
                      ),
                      SizedBox(width: 10.w),
                      IconButton(
                        icon: Icon(Icons.arrow_forward, size: 24.r),
                        onPressed: () => _updateArrowStatus('right', true),
                        color: _arrowStatus['right']! ? theme.colorScheme.primary : theme.iconTheme.color,
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  IconButton(
                    icon: Icon(Icons.arrow_downward, size: 24.r),
                    onPressed: () => _updateArrowStatus('down', true),
                    color: _arrowStatus['down']! ? theme.colorScheme.primary : theme.iconTheme.color,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.r),
              margin: EdgeInsets.symmetric(horizontal: 0.w),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2), width: 1.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: IconButton(
                      icon: Text('H', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                      onPressed: () => _updateArrowStatus('hide', true),
                      color: _arrowStatus['hide']! ? theme.colorScheme.primary : theme.iconTheme.color,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Text('L', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                      onPressed: () => _updateArrowStatus('lock', true),
                      color: _arrowStatus['lock']! ? theme.colorScheme.primary : theme.iconTheme.color,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Text('T', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                      onPressed: () => _updateArrowStatus('tab', true),
                      color: _arrowStatus['tab']! ? theme.colorScheme.primary : theme.iconTheme.color,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Text('M', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                      onPressed: () => _updateArrowStatus('mouse', true),
                      color: _arrowStatus['mouse']! ? theme.colorScheme.primary : theme.iconTheme.color,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h), // Add some bottom padding consistent with CalculatorPage
            // New horizontal line for C, F, FF buttons
            Container(
              padding: EdgeInsets.all(16.r),
              margin: EdgeInsets.symmetric(horizontal: 0.w),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.2), width: 1.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: IconButton(
                      icon: Text('C', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                      onPressed: () => _updateArrowStatus('close', true),
                      color: _arrowStatus['close']! ? theme.colorScheme.primary : theme.iconTheme.color,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Text('F', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                      onPressed: () => _updateArrowStatus('full', true),
                      color: _arrowStatus['full']! ? theme.colorScheme.primary : theme.iconTheme.color,
                    ),
                  ),
                  Expanded(
                    child: IconButton(
                      icon: Text('FF', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold)),
                      onPressed: () => _updateArrowStatus('full_widget', true),
                      color: _arrowStatus['full_widget']! ? theme.colorScheme.primary : theme.iconTheme.color,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h), // Add some bottom padding
            // Add more PC tools UI elements here as needed
          ],
        ),
      ),
    );
  }
}
