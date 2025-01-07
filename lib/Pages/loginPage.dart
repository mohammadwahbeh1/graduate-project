import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:untitled/Pages/homePage.dart';
import 'package:untitled/Pages/serviceDashboardPage.dart';
import 'package:untitled/Pages/signUp.dart';
import 'Forgot_password.dart';
import 'adminPage.dart';
import 'driverPage.dart';
import 'lineManagerPage.dart';
import 'package:untitled/Pages/Location Service.dart';
import 'package:flutter/foundation.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


const String ip = "192.168.1.12";


// Create a secure storage instance

const storage = FlutterSecureStorage();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String email = "", password = "";
  var EmailController = TextEditingController();
  var PasswordController = TextEditingController();
  final _formkey = GlobalKey<FormState>();
  bool isLoading = false;

  final RegExp emailRegExp = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");

  userLogin() async {
    if (_formkey.currentState!.validate()) {
      setState(() {
        email = EmailController.text;
        password = PasswordController.text;
        isLoading = true;
      });

      var url = Uri.parse('http://$ip:3000/api/v1/login');

      var body = json.encode({
        'email': email,
        'password': password,
      });

      try {
        var response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          var token = jsonResponse['data']['token'];
          var userId = jsonResponse['data']['user']['user_id'];

          DateTime expirationTime = DateTime.now().add(const Duration(minutes: 2));
          await storage.write(key: 'jwt_token', value: token);
          await storage.write(key: 'user_id', value: userId.toString());
          await storage.write(
              key: 'token_expiration', value: expirationTime.toIso8601String());

          Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
          String role = decodedToken['role']?.trim() ?? '';

          // Check for support email after successful authentication
          if (email == "support@gmail.com") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ServiceDashboardPage()),
            );
          } else {
            _navigateBasedOnRole(role);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid email or password')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }

  @override
  void dispose() {
    EmailController.dispose();
    PasswordController.dispose();
    super.dispose();
  }

  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: Container(
          width: isWeb ? 500 : MediaQuery.of(context).size.width,
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 30.0 : 20.0,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Container(
                  width: isWeb
                      ? 200
                      : MediaQuery.of(context).size.width * 0.7,
                  child: Image.asset('assets/logo.jpg'),
                ),
                const SizedBox(height: 30),
                Form(
                  key: _formkey,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2.0, horizontal: 30.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFedf0f8),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextFormField(
                          controller: EmailController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Email",
                            hintStyle: TextStyle(
                              color: Color(0xFFb2b7bf),
                              fontSize: 18.0,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            } else if (!emailRegExp.hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2.0, horizontal: 30.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFedf0f8),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: TextFormField(
                          controller: PasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Password",
                            hintStyle: TextStyle(
                              color: Color(0xFFb2b7bf),
                              fontSize: 18.0,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            } else if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: userLogin,
                        child: Container(
                          width: double.infinity,
                          padding:
                          const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Center(
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ForgotPassword()),
                          );
                        },
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(
                              color: Color(0xFF8c8e98),
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(
                                fontSize: 16.0, color: Colors.black),
                          ),
                          const SizedBox(width: 5.0),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignUp()),
                              );
                            },
                            child: const Text(
                              "Create",
                              style: TextStyle(
                                  color: Color(0xFFFFD700),
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Implement Google login
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: FaIcon(
                                  FontAwesomeIcons.google,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15.0),
                          GestureDetector(
                            onTap: () {
                              // Implement Facebook login
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: FaIcon(
                                  FontAwesomeIcons.facebookF,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 15.0),
                          GestureDetector(
                            onTap: () {
                              // Implement Twitter login
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: FaIcon(
                                  FontAwesomeIcons.twitter,
                                  color: Colors.lightBlue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
