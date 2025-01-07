//SplashScreen
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:untitled/Pages/loginPage.dart';
import 'package:untitled/Pages/homePage.dart';
import 'package:untitled/Pages/driverPage.dart';
import 'package:untitled/Pages/lineManagerPage.dart';
import 'package:untitled/Pages/adminPage.dart';

final storage = FlutterSecureStorage();

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // التحقق من حالة تسجيل الدخول عند بدء الشاشة
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    try {
      final token = await storage.read(key: 'jwt_token');
      final expirationString = await storage.read(key: 'token_expiration');

      if (token != null && expirationString != null) {
        DateTime expirationTime = DateTime.parse(expirationString);

        if (DateTime.now().isBefore(expirationTime)) {
          Map<String, dynamic> decodedToken = Jwt.parseJwt(token);

          String role = decodedToken['role']?.trim() ?? '';
          _navigateBasedOnRole(role);
        } else {
          _navigateToLogin();
        }
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      _navigateToLogin();
    }
  }

  void _navigateBasedOnRole(String role) {
    Widget targetPage;

    switch (role) {
      case 'user':
        targetPage = HomePage();
        break;
      case 'driver':
        targetPage = DriverPage();
        break;
      case 'line_manager':
        targetPage = LineManagerPage();
        break;
      case 'admin':
        targetPage = ManagerPage();
        break;
      default:
        targetPage = const LoginPage();
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
          (route) => false,
    );
  }


  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Hero(
          tag: "logo",
          child: Image.asset('assets/logo.jpg'),
        ),
      ),
    );
  }
}
