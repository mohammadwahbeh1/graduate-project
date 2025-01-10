import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:untitled/Pages/Splash_screen.dart';
import 'package:provider/provider.dart';

import 'Pages/Forgot_password.dart';
import 'Pages/location_provider.dart';
import 'Pages/loginPage.dart';
import 'Pages/serviceDashboardPage.dart';


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
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (BuildContext context, Orientation orientation, DeviceType deviceType) {
        return ChangeNotifierProvider(
          create: (context) => LocationProvider(), // Provide LocationProvider to the app
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Login Page",
            theme: ThemeData(
              primaryColor: Colors.blue,
            ),
            home: const SplashScreen(), // Splash screen as the entry point
            routes: {
              '/login': (context) => const LoginPage(),
              '/forgot-password': (context) => const ForgotPassword(),
              '/service-dashboard': (context) => const ServiceDashboardPage(),
              // Add more routes as needed
            },
          ),
        );
      },
    );
  }
}