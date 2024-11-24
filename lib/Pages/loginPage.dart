import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert'; // For encoding/decoding JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:untitled/Pages/homePage.dart';
import 'package:untitled/Pages/signUp.dart';
import 'Forgot_password.dart';
import 'adminPage.dart';
import 'driverPage.dart';
import 'lineManagerPage.dart';

const String ip = "192.168.1.2";

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

  // Email validation regex
  final RegExp emailRegExp = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");

  // Function to handle user login
  userLogin() async {
    if (_formkey.currentState!.validate()) {
      setState(() {
        email = EmailController.text;
        password = PasswordController.text;
        isLoading = true;
      });

      // Backend URL for login
      var url = Uri.parse('http://$ip:3000/api/v1/login'); // Replace with your actual API URL

      // Prepare the body of the POST request
      var body = json.encode({
        'email': email,
        'password': password, // Match this with backend field name
      });

      try {
        // Make the POST request
        var response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: body,
        );


        if (response.statusCode == 200) {
          // Successful login (200 status)
          var jsonResponse = jsonDecode(response.body);
          print('Login response: $jsonResponse');
          var token = jsonResponse['data']['token'];
          var userId = jsonResponse['data']['user']['user_id'];

          DateTime expirationTime = DateTime.now().add(Duration(minutes: 2));
          await storage.write(key: 'jwt_token', value: token);
          await storage.write(key: 'user_id', value: userId.toString());
          await storage.write(key: 'token_expiration', value: expirationTime.toIso8601String());

          // Decode the token to get the role
          Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
          String role = decodedToken['role']?.trim() ?? '';

          // Navigate based on the role
          _navigateBasedOnRole(role);
        } else {
          print('Token is null');
          // Invalid login (e.g., wrong email/password)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid email or password')),
          );
        }
      } catch (e) {
        // Handle error (e.g., network issues)
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
        targetPage = homePage();
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

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetPage),
    );
  }


  // Retrieve the token (you might need this in future for authenticated requests)
  Future<String?> getToken() async {
    return await storage.read(key: 'jwt_token');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body:  (isLoading)? Center(child: CircularProgressIndicator()):
      Container(
        child: SingleChildScrollView(
          child: Column(
            children: [

              const SizedBox(height: 30),
              Container(
                width: MediaQuery.of(context).size.width,
                child: Image.asset('assets/logo.jpg'),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20),
                child: Form(
                  key: _formkey,
                  child: Column(
                    children: [
                      // Email input field
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
                      const SizedBox(height: 40.0),

                      // Password input field
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
                      const SizedBox(height: 30),

                      // Sign In button
                      GestureDetector(
                        onTap: userLogin,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.symmetric(
                              vertical: 11.0, horizontal: 25.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Center(
                            child: Text(
                              "Sign In",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 19.0,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      // Forgot Password link
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
                              fontSize: 18.0,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 40.0),

                      // Sign Up link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account?",
                            style: TextStyle(
                                fontSize: 18.0, color: Colors.black),
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
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.w500),
                            ),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
