import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:untitled/Pages/loginPage.dart';
import 'package:untitled/Pages/homePage.dart'; // Import your home page

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
    _checkLoginStatus(); // Check login status when the screen initializes
  }

  Future<void> _checkLoginStatus() async {
    // Wait for 4 seconds before checking
    await Future.delayed(const Duration(seconds: 4));

    final token = await storage.read(key: 'jwt_token');
    final expirationString = await storage.read(key: 'token_expiration');



    if (token != null && expirationString != null) {
      DateTime expirationTime = DateTime.parse(expirationString);
      if (DateTime.now().isBefore(expirationTime)) {
        // Token is valid
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) =>  homePage()), // Navigate to home page
              (route) => false,
        );
      } else {
        // Token is expired or not valid
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()), // Navigate to login page
              (route) => false,
        );
      }
    } else {
      // Token doesn't exist
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()), // Navigate to login page
            (route) => false,
      );
    }
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
