import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  String email = "";
  String verificationCode = "";
  String newPassword = "";
  String confirmPassword = "";
  bool codeSent = false;
  bool codeVerified = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  static const String ip = "192.168.1.8";
  final _formKey = GlobalKey<FormState>();

  // Color constants
  final Color primaryColor = const Color(0xFFFFD700);
  final Color backgroundColor = const Color(0xFF121212);
  final Color cardColor = const Color(0xFF1E1E1E);
  final Color textColor = Colors.white;

  Future<void> requestCode() async {
    const url = 'http://$ip:3000/api/v1/users/forgot-password';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (response.statusCode == 200) {
        setState(() {
          codeSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Verification code sent to your email"),
            backgroundColor: primaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: ${json.decode(response.body)['message']}",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "An error occurred: $error",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> verifyCode() async {
    const url = 'http://$ip:3000/api/v1/users/verify-reset-code';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'code': verificationCode,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          codeVerified = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Code verified successfully"),
            backgroundColor: primaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: ${json.decode(response.body)['message']}",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "An error occurred: $error",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> resetPassword() async {
    const url = 'http://$ip:3000/api/v1/users/reset-password';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Password reset successfully"),
            backgroundColor: primaryColor,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error: ${json.decode(response.body)['message']}",
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "An error occurred: $error",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 80.0),


                Center(
                  child: Text(
                        "Reset Password",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 32.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                                         ),
                ),


                 Center(
                   child: Text(
                      "We'll help you recover your password",
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16.0,
                      ),
                    ),
                 ),

                const SizedBox(height: 40.0),

                if (!codeSent) ...[
                  _buildTextField(
                    controller: emailController,
                    label: "Email Address",
                    icon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                    onChanged: (value) => email = value,
                  ),
                  const SizedBox(height: 24.0),
                  _buildButton(
                    text: "Send Verification Code",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        requestCode();
                      }
                    },
                  ),
                ],

                if (codeSent && !codeVerified) ...[
                  _buildTextField(
                    controller: codeController,
                    label: "Verification Code",
                    icon: Icons.lock_clock_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the verification code';
                      }
                      return null;
                    },
                    onChanged: (value) => verificationCode = value,
                  ),
                  const SizedBox(height: 24.0),
                  _buildButton(
                    text: "Verify Code",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        verifyCode();
                      }
                    },
                  ),
                ],

                if (codeVerified) ...[
                  _buildTextField(
                    controller: passwordController,
                    label: "New Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter new password';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      return null;
                    },
                    onChanged: (value) => newPassword = value,
                  ),
                  const SizedBox(height: 16.0),
                  _buildTextField(
                    controller: confirmPasswordController,
                    label: "Confirm Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    onChanged: (value) => confirmPassword = value,
                  ),
                  const SizedBox(height: 24.0),
                  _buildButton(
                    text: "Reset Password",
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        resetPassword();
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    required String? Function(String?) validator,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withOpacity(0.2), width: 1),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: textColor),
        cursorColor: Colors.white,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor.withOpacity(0.2), width: 1),
          ),
        ),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
