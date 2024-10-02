import 'dart:async';

import 'package:flutter/material.dart';
import 'package:untitled/Pages/loginPage.dart';
class SplashScreen extends StatefulWidget {


  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    Timer(const Duration(seconds: 4),(){
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=>const LoginPage()), (route) => false);
    });
    // TODO: implement initState
    super.initState();
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
