import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For making HTTP requests
import 'dart:convert'; // For encoding/decoding JSON
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'loginPage.dart';

// Create a secure storage instance
final storage = FlutterSecureStorage();

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String email = "", password = "", confirmPassword = "", name = "";
  TextEditingController namecontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  // Email regex validation
  final RegExp emailRegExp = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");

  // Signup function
  Future<void> registration() async {
    if (_formkey.currentState!.validate()) {
      setState(() {
        email = mailcontroller.text;
        name = namecontroller.text;
        password = passwordcontroller.text;
      });

      var url = Uri.parse('http://192.168.1.3:3000/api/v1/register'); // Adjust API URL

      var body = json.encode({
        'username': name,
        'email': email,
        'password': password,
        "phone_number":"0568243138",
        "role":"user",

      });

      try {
        var response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
          },
          body: body,
        );

        if (response.statusCode == 201) {
          var jsonResponse = jsonDecode(response.body);


          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signup successful!')),
          );

          // Navigate to login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        } else {
          var errorResponse = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${errorResponse['message']}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Network error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 70.0),
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Form(
                key: _formkey,
                child: Column(
                  children: [
                    // Name input field
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 30.0),
                      decoration: BoxDecoration(
                          color: const Color(0xFFedf0f8),
                          borderRadius: BorderRadius.circular(30)),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter Name';
                          }
                          return null;
                        },
                        controller: namecontroller,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Name",
                            hintStyle: TextStyle(
                                color: Color(0xFFb2b7bf), fontSize: 18.0)),
                      ),
                    ),
                    const SizedBox(height: 30.0),

                    // Email input field with validation
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 30.0),
                      decoration: BoxDecoration(
                          color: const Color(0xFFedf0f8),
                          borderRadius: BorderRadius.circular(30)),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter Email';
                          } else if (!emailRegExp.hasMatch(value)) {
                            return 'Please Enter a Valid Email';
                          }
                          return null;
                        },
                        controller: mailcontroller,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Email",
                            hintStyle: TextStyle(
                                color: Color(0xFFb2b7bf), fontSize: 18.0)),
                      ),
                    ),
                    const SizedBox(height: 30.0),

                    // Password input field with validation
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 30.0),
                      decoration: BoxDecoration(
                          color: const Color(0xFFedf0f8),
                          borderRadius: BorderRadius.circular(30)),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Enter Password';
                          } else if (value.length < 6) {
                            return 'Password must be at least 6 characters long';
                          }
                          return null;
                        },
                        controller: passwordcontroller,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Password",
                            hintStyle: TextStyle(
                                color: Color(0xFFb2b7bf), fontSize: 18.0)),
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 30.0),

                    // Confirm Password input field with validation
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 2.0, horizontal: 30.0),
                      decoration: BoxDecoration(
                          color: const Color(0xFFedf0f8),
                          borderRadius: BorderRadius.circular(30)),
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please Confirm Password';
                          } else if (value != passwordcontroller.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        controller: confirmPasswordController,
                        decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Confirm Password",
                            hintStyle: TextStyle(
                                color: Color(0xFFb2b7bf), fontSize: 18.0)),
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 30.0),

                    // Sign Up button
                    GestureDetector(
                      onTap: registration,
                      child: Container(
                          width: MediaQuery.of(context).size.width,
                          padding: const EdgeInsets.symmetric(
                              vertical: 13.0, horizontal: 30.0),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(30)),
                          child: const Center(
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.w800),
                              ))),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }
}
