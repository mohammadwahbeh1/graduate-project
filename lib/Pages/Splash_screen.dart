import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:untitled/Pages/loginPage.dart';
import 'package:untitled/Pages/homePage.dart';
import 'package:untitled/Pages/driverPage.dart';
import 'package:untitled/Pages/lineManagerPage.dart';
import 'package:untitled/Pages/adminPage.dart';
import 'package:untitled/Pages/serviceDashboardPage.dart'; // For support dashboard

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
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3)); // Simulate splash delay

    try {
      final token = await storage.read(key: 'jwt_token');
      final expirationString = await storage.read(key: 'token_expiration');

      print('Token: $token');
      print('Expiration: $expirationString');

      if (token != null && expirationString != null) {
        DateTime expirationTime = DateTime.parse(expirationString);

        if (DateTime.now().isBefore(expirationTime)) {
          Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
          String role = decodedToken['role']?.trim() ?? '';
          final email = await storage.read(key: 'user_email');


          // Check if the user is support
          if (email == "support@gmail.com") {
            _navigateTo(const ServiceDashboardPage());
          } else {
            _navigateBasedOnRole(role);
          }
        } else {
          print('Token expired');
          _navigateToLogin();
        }
      } else {
        print('Token is null or missing');
        _navigateToLogin();
      }
    } catch (e) {
      print('Error checking login status: $e');
      _navigateToLogin();
    }
  }

  void _navigateBasedOnRole(String role) {
    Widget targetPage;

    switch (role) {
      case 'user':
        targetPage = const homePage();
        break;
      case 'driver':
        targetPage = const DriverPage();
        break;
      case 'line_manager':
        targetPage = const LineManagerPage();
        break;
      case 'admin':
        targetPage = const ManagerPage();
        break;
      default:
        targetPage = const LoginPage();
        break;
    }

    _navigateTo(targetPage);
  }

  void _navigateToLogin() {
    _navigateTo(const LoginPage());
  }

  void _navigateTo(Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => page),
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
