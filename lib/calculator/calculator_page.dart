import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chiper/calculator/calculator_history_page.dart';
import 'package:chiper/services/secret_code_service.dart';
import 'package:google_fonts/google_fonts.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _output = "0"; // Formatted for display
  String _currentNumber = "0"; // Unformatted for calculations
  String _expression = ""; // Unformatted expression
  bool _isOperatorJustPressed = false;
  final int _maxLength = 25; // Max digits limit

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SecretCodeService _secretCodeService = SecretCodeService();
  String? _cachedSecretCode; // New variable to cache secret code

  User? get currentUser => _auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadSecretCode();
  }

  Future<void> _loadSecretCode() async {
    _cachedSecretCode = await _secretCodeService.getSecretCode();
  }

  String _formatNumber(String numberString) {
    if (numberString.isEmpty || numberString == '0') return '0';

    // Handle negative sign
    bool isNegative = numberString.startsWith('-');
    if (isNegative) {
      numberString = numberString.substring(1);
    }

    // Remove existing commas for re-formatting
    numberString = numberString.replaceAll(',', '');

    // Split into integer and decimal parts
    List<String> parts = numberString.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';

    // Format integer part with commas
    final formatter = NumberFormat('#,##0');
    String formattedIntegerPart = formatter.format(int.parse(integerPart));

    return (isNegative ? '-' : '') + formattedIntegerPart + decimalPart;
  }

  Future<void> _saveCalculation(String expression, String result) async {
    if (currentUser == null) {
      // Optionally show a popup if user is not logged in and cannot save history
      // _showCustomPopup('Please log in to save history.');
      return;
    }

    try {
      final historyRef = _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .collection('calculator_history');

      await historyRef.add({
        'expression': expression,
        'result': result,
        'timestamp': FieldValue.serverTimestamp(), // Use server timestamp for ordering
        'isPinned': false, // Initialize as not pinned
      });
      // No popup needed here, as saving is a background operation.
      // If a success message is desired, it should be a subtle one.
    } catch (e) {
      print('Error saving calculation: $e');
      // Optionally show a popup for error
      // _showCustomPopup('Failed to save calculation: ${e.toString()}');
    }
  }

  void _buttonPressed(String buttonText) async { // Made async to await getSecretCode
    setState(() {
      if (buttonText == "AC") {
        _output = "0";
        _currentNumber = "0";
        _expression = "";
        _isOperatorJustPressed = false;
        return;
      } else if (buttonText == "⌫") {
        if (_currentNumber.length > 1) {
          _currentNumber = _currentNumber.substring(0, _currentNumber.length - 1);
        } else {
          _currentNumber = "0";
        }
        _output = _formatNumber(_currentNumber);
        return;
      } else if (buttonText == "=") {
        if (_expression.isNotEmpty) {
          String finalExpression = _expression + _currentNumber;
          try {
            String result = _evaluateExpression(finalExpression);
            _saveCalculation(finalExpression, result);
            _expression = "";
            _currentNumber = result;
            _output = _formatNumber(result);
          } catch (e) {
            _output = "Error";
            _currentNumber = "Error";
          }
        }
        _isOperatorJustPressed = false;
        return;
      }

      if (["%", "÷", "×", "-", "+"].contains(buttonText)) {
        if (_isOperatorJustPressed) {
          _expression = _expression.substring(0, _expression.length - 1) + buttonText;
        } else {
          _expression += _currentNumber + buttonText;
          _currentNumber = "0";
          _output = "0";
          _isOperatorJustPressed = true;
        }
      } else if (buttonText == ".") {
        if (_isOperatorJustPressed) {
          _currentNumber = "0.";
          _output = "0.";
          _isOperatorJustPressed = false;
        } else if (!_currentNumber.contains(".")) {
          _currentNumber += ".";
          _output += ".";
        }
      } else {
        if (_isOperatorJustPressed) {
          _currentNumber = buttonText;
          _isOperatorJustPressed = false;
        } else if (_currentNumber == "0") {
          _currentNumber = buttonText;
        } else {
          _currentNumber += buttonText;
        }
        _output = _formatNumber(_currentNumber);
      }
    });

    if (_currentNumber == _cachedSecretCode) {
      // Check if HidePage is already in the navigation stack
      bool hidePageAlreadyInStack = false;
      Navigator.popUntil(context, (route) {
        if (route.settings.name == '/hidePage') {
          hidePageAlreadyInStack = true;
          return true; // Found HidePage, stop popping here. HidePage is now at the top.
        }
        return false; // Keep popping
      });

      if (!hidePageAlreadyInStack) {
        // If HidePage was not found, push it.
        Navigator.pushNamed(context, '/hidePage');
      }
    }
  }

  // --- Expression Evaluation Logic ---

  String _evaluateExpression(String expression) {
    try {
      // The shunting-yard algorithm implementation
      List<dynamic> tokens = _tokenize(expression);
      List<double> values = [];
      List<String> ops = [];

      for (int i = 0; i < tokens.length; i++) {
        var token = tokens[i];
        if (token is double) {
          values.add(token);
        } else if (token == '(') {
          ops.add(token);
        } else if (token == ')') {
          while (ops.last != '(') {
            values.add(_applyOp(ops.removeLast(), values.removeLast(), values.removeLast()));
          }
          ops.removeLast(); // Pop '('
        } else if ("%÷×+-".contains(token)) {
          while (ops.isNotEmpty && ops.last != '(' && _hasPrecedence(ops.last, token)) {
            values.add(_applyOp(ops.removeLast(), values.removeLast(), values.removeLast()));
          }
          ops.add(token);
        }
      }

      while (ops.isNotEmpty) {
        values.add(_applyOp(ops.removeLast(), values.removeLast(), values.removeLast()));
      }
      
      String result = values.single.toString();
      if (result.endsWith(".0")) {
        return result.substring(0, result.length - 2);
      }
      return result;

    } catch (e) {
      return "Error";
    }
  }

  List<dynamic> _tokenize(String expression) {
    List<dynamic> tokens = [];
    RegExp exp = RegExp(r'(\d+\.?\d*)|([%÷×+\-])');
    Iterable<Match> matches = exp.allMatches(expression);

    for (var match in matches) {
      String value = match.group(0)!;
      if ("%÷×+-".contains(value)) {
        tokens.add(value);
      } else {
        tokens.add(double.parse(value.replaceAll(',', '')));
      }
    }
    return tokens;
  }

  bool _hasPrecedence(String op1, String op2) {
    int op1Prec = _getPrecedence(op1);
    int op2Prec = _getPrecedence(op2);
    return op1Prec >= op2Prec;
  }

  int _getPrecedence(String op) {
    switch (op) {
      case '+':
      case '-':
        return 1;
      case '×':
      case '÷':
      case '%':
        return 2;
      default:
        return 0;
    }
  }

  double _applyOp(String op, double b, double a) {
    switch (op) {
      case '+': return a + b;
      case '-': return a - b;
      case '×': return a * b;
      case '÷':
        if (b == 0) throw Exception("Division by zero");
        return a / b;
      case '%':
        return a * (b / 100);
      default:
        throw Exception("Unknown operator");
    }
  }

  String _formatExpressionForDisplay(String expression) {
    if (expression.isEmpty) return "";

    // Regular expression to find numbers (integers or decimals)
    RegExp numberRegExp = RegExp(r'\d+\.?\d*');

    return expression.replaceAllMapped(numberRegExp, (match) {
      String numberString = match.group(0)!;
      return _formatNumber(numberString);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Calculator',
          style: GoogleFonts.righteous(
            textStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(fontSize: 24.sp),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalculatorHistoryPage()),
              );
            },
          ),
        ],
      ),
      body: _buildCalculatorView(),
    );
  }

  Widget _buildCalculatorView() {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      return Column(
        children: <Widget>[
          // Display Area
          Expanded(
            child: Container(
              padding: EdgeInsets.all(20.0.r),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Expression display
                  Text(
                    _formatExpressionForDisplay(_expression), // Formatted for display
                    style: GoogleFonts.orbitron(
                      textStyle: theme.textTheme.displayMedium,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  // Result display
                  FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      _output, // Already formatted
                      style: GoogleFonts.orbitron(
                        textStyle: theme.textTheme.displayLarge!.copyWith(
                          fontSize: 50.sp,
                        ),
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Divider
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Divider(
              height: 1,
              color: theme.dividerColor,
            ),
          ),
          SizedBox(height: 10.h),
          // Buttons Grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildCalculatorButton("AC"),
                    _buildCalculatorButton("⌫"),
                    _buildCalculatorButton("%"),
                    _buildCalculatorButton("÷"),
                  ],
                ),
                Row(
                  children: [
                    _buildCalculatorButton("7"),
                    _buildCalculatorButton("8"),
                    _buildCalculatorButton("9"),
                    _buildCalculatorButton("×"),
                  ],
                ),
                Row(
                  children: [
                    _buildCalculatorButton("4"),
                    _buildCalculatorButton("5"),
                    _buildCalculatorButton("6"),
                    _buildCalculatorButton("-"),
                  ],
                ),
                Row(
                  children: [
                    _buildCalculatorButton("1"),
                    _buildCalculatorButton("2"),
                    _buildCalculatorButton("3"),
                    _buildCalculatorButton("+"),
                  ],
                ),
                Row(
                  children: [
                    _buildCalculatorButton("0", flex: 2),
                    _buildCalculatorButton("."),
                    _buildCalculatorButton("="),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h), // Add some bottom padding
        ],
      );
    });
  }

  // Helper method to create a _CalculatorButton widget
  Widget _buildCalculatorButton(String buttonText, {int flex = 1}) {
    final theme = Theme.of(context);
    final screenUtil = ScreenUtil();

    // Responsive button size
    double buttonSize = screenUtil.setWidth(60); // Decreased button size for better aesthetics

    Color buttonColor;
    Color textColor;

    if (buttonText == "AC" || buttonText == "⌫" || buttonText == "%" || buttonText == "±") {
      // Function keys
      buttonColor = theme.colorScheme.secondary;
      textColor = theme.colorScheme.onSecondary;
    } else if (buttonText == "÷" || buttonText == "×" || buttonText == "-" || buttonText == "+") {
      // Operator keys
      buttonColor = theme.colorScheme.secondary; // Changed to secondary color
      textColor = theme.colorScheme.onSecondary;
    } else {
      // Number keys and decimal
      buttonColor = theme.colorScheme.surface;
      textColor = theme.colorScheme.onSurface;
    }

    return Expanded(
      flex: flex,
      child: Padding(
        padding: EdgeInsets.all(screenUtil.setWidth(3)), // Reduced padding
        child: SizedBox(
          width: flex == 2 ? buttonSize * 2 + screenUtil.setWidth(8) : buttonSize,
          height: buttonSize,
          child: _CalculatorButton(
            text: buttonText,
            buttonColor: buttonColor,
            textColor: textColor,
            onTap: () => _buttonPressed(buttonText),
          ),
        ),
      ),
    );
  }
}

// New StatefulWidget for individual calculator buttons to handle their own animations
class _CalculatorButton extends StatefulWidget {
  final String text;
  final Color buttonColor;
  final Color textColor;
  final VoidCallback onTap;

  const _CalculatorButton({
    required this.text,
    required this.buttonColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_CalculatorButton> createState() => _CalculatorButtonState();
}

class _CalculatorButtonState extends State<_CalculatorButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap(); // Call the original onTap callback
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Material(
        color: Colors.transparent, // Make Material transparent to show Container's color
        borderRadius: BorderRadius.circular(8.0.r), // Square with small border radius
        elevation: 0,
        child: InkWell(
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(8.0.r), // Match InkWell borderRadius
          splashColor: widget.textColor.withOpacity(0.3),
          highlightColor: widget.textColor.withOpacity(0.2),
          child: Container(
            decoration: BoxDecoration(
              color: widget.buttonColor, // Apply button color here
              borderRadius: BorderRadius.circular(8.0.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08), // Shadow like MemoHomePage
                  blurRadius: 8.0.r,
                  offset: Offset(0, 4.r),
                ),
              ],
            ),
            child: Center(
              child: Text(
                widget.text,
                style: GoogleFonts.orbitron(
                  textStyle: theme.textTheme.bodyLarge!.copyWith(
                    color: widget.textColor,
                    fontSize: 20.0.sp, // Adjusted font size for smaller buttons
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}