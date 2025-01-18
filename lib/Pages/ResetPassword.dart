import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPassword extends StatefulWidget {
  final String token;

  const ResetPassword({Key? key, required this.token}) : super(key: key);

  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isLoading = false;
  static const String ip = "192.168.1.8";

  Future<void> resetPassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://$ip:3000/api/v1/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': widget.token,
          'newPassword': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password successfully reset'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reset password. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 70.0),
          Container(
            alignment: Alignment.topCenter,
            child: const Text(
              "Reset Password",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 30.0,
                  fontWeight: FontWeight.bold
              ),
            ),
          ),
          const SizedBox(height: 10.0),
          const Text(
            "Enter your new password",
            style: TextStyle(
                color: Colors.black,
                fontSize: 20.0,
                fontWeight: FontWeight.bold
            ),
          ),
          Expanded(
              child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: ListView(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFb2b7bf), width: 2.0),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter new password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                                hintText: "New Password",
                                hintStyle: TextStyle(fontSize: 18.0, color: Colors.black),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Colors.black,
                                  size: 30.0,
                                ),
                                border: InputBorder.none
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFb2b7bf), width: 2.0),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                            style: const TextStyle(color: Colors.black),
                            decoration: const InputDecoration(
                                hintText: "Confirm Password",
                                hintStyle: TextStyle(fontSize: 18.0, color: Colors.black),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: Colors.black,
                                  size: 30.0,
                                ),
                                border: InputBorder.none
                            ),
                          ),
                        ),
                        const SizedBox(height: 40.0),
                        GestureDetector(
                          onTap: () {
                            if (_formKey.currentState!.validate()) {
                              resetPassword();
                            }
                          },
                          child: Container(
                            width: 140,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(10)
                            ),
                            child: Center(
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.black)
                                  : const Text(
                                "Reset Password",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
              )
          ),
        ],
      ),
    );
  }

}
