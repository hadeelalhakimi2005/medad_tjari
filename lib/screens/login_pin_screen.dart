import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../constants/app_colors.dart';
import 'main_navigation_screen.dart';

class LoginPinScreen extends StatefulWidget {
  const LoginPinScreen({super.key});

  @override
  State<LoginPinScreen> createState() => _LoginPinScreenState();
}

class _LoginPinScreenState extends State<LoginPinScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  String _enteredPin = '';
  final String _correctPin = '1234'; // الرمز السري الافتراضي
  String _errorMessage = '';
  bool _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricsSupport();
  }

  Future<void> _checkBiometricsSupport() async {
    try {
      final canCheck = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      setState(() {
        _canCheckBiometrics = canCheck;
      });
      // تجربة البصمة تلقائياً عند فتح الشاشة
      if (canCheck) {
        _authenticateWithBiometrics();
      }
    } catch (e) {
      debugPrint('Biometrics check error: $e');
    }
  }

  // 1. تسجيل الدخول بالبصمة (Biometrics) باستخدام local_auth
  Future<void> _authenticateWithBiometrics() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'يرجى مسح البصمة للدخول السريع إلى نظام المحل',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (authenticated && mounted) {
        _onLoginSuccess();
      }
    } on PlatformException catch (e) {
      debugPrint('خطأ البصمة: $e');
    }
  }

  // 2. تسجيل الدخول بالرمز السري (PIN Code)
  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _errorMessage = '';
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePress() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = '';
      });
    }
  }

  void _verifyPin() {
    if (_enteredPin == _correctPin) {
      _onLoginSuccess();
    } else {
      setState(() {
        _errorMessage = 'الرمز السري غير صحيح، حاول مرة أخرى';
        _enteredPin = '';
      });
      HapticFeedback.vibrate();
    }
  }

  void _onLoginSuccess() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // اللوجو الرسمي للتطبيق
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // اسم التطبيق الرسمي بالعربي والإنجليزي
            const Text(
              'مِداد تجاري',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'MEDAD TJARI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.success,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'نظام إدارة الديون والمخزون والمبيعات',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),

            const SizedBox(height: 24),

            // دوائر إدخال الرمز السري (PIN Dots)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isFilled ? AppColors.success : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFilled ? AppColors.success : Colors.white60,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            // رسالة الخطأ إن وجدت
            const SizedBox(height: 12),
            SizedBox(
              height: 24,
              child: Text(
                _errorMessage,
                style: const TextStyle(
                  color: Color(0xFFFCA5A5),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const Spacer(flex: 1),

            // لوحة الأرقام (PIN Pad)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKeypadButton('1'),
                      _buildKeypadButton('2'),
                      _buildKeypadButton('3'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKeypadButton('4'),
                      _buildKeypadButton('5'),
                      _buildKeypadButton('6'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKeypadButton('7'),
                      _buildKeypadButton('8'),
                      _buildKeypadButton('9'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // زر بصمة الإصبع (Biometrics)
                      InkWell(
                        onTap: _canCheckBiometrics ? _authenticateWithBiometrics : null,
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fingerprint_rounded,
                            color: _canCheckBiometrics ? AppColors.success : Colors.white30,
                            size: 32,
                          ),
                        ),
                      ),

                      _buildKeypadButton('0'),

                      // زر الحذف
                      InkWell(
                        onTap: _onDeletePress,
                        borderRadius: BorderRadius.circular(40),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.backspace_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // تلميح الرمز الافتراضي
            const Text(
              'الرمز السري الافتراضي للمحل: 1234',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return InkWell(
      onTap: () => _onKeyPress(digit),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
