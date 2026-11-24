import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/app_theme.dart';
import 'screens/login_pin_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MedadTjariApp());
}

class MedadTjariApp extends StatelessWidget {
  const MedadTjariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مِداد تجاري',
      debugShowCheckedModeBanner: false,

      // الهوية البصرية والثيم العام
      theme: AppTheme.lightTheme,

      // إعداد اللغة العربية والاتجاه من اليمين لليسار (RTL)
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // شاشة تسجيل الدخول والأمان (PIN Code والبصمة)
      home: const LoginPinScreen(),
    );
  }
}
