import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/admin_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  bool _showSplash = true;
  bool _authorized = false;

  void _onSplashFinished() {
    setState(() => _showSplash = false);
  }

  void _onAuthorized() {
    setState(() => _authorized = true);
  }

  void _onLogout() {
    setState(() => _authorized = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Khushrang Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.dark,
      home: _showSplash
          ? AdminSplashScreen(onFinished: _onSplashFinished)
          : _authorized
              ? ShellScreen(onLogout: _onLogout)
              : LoginScreen(onSuccess: _onAuthorized),
    );
  }
}
