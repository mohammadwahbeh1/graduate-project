import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:untitled/Pages/Splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return  Sizer(
      builder: (BuildContext context, Orientation orientation, DeviceType deviceType)
    {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Login Page",
        theme: ThemeData(
          primaryColor: Colors.blue,
        ),
        home:const SplashScreen(),
      );
    }


    );

  }
}
