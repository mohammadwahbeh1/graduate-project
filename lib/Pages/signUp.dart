import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For making HTTP requests
import 'dart:convert'; // For encoding/decoding JSON
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'loginPage.dart'; // Navigate to login page after successful sign-up
import 'package:flutter/foundation.dart';


const String ip ="192.168.1.4";


// Create a secure storage instance
final storage = FlutterSecureStorage();

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String email = "", password = "", confirmPassword = "", name = "", address = "", gender = "", dateOfBirth = "";
  TextEditingController namecontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController dateOfBirthController = TextEditingController();
  TextEditingController genderController = TextEditingController();

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
        address = addressController.text;
        gender = genderController.text;
        dateOfBirth = dateOfBirthController.text;
      });

      var url = Uri.parse('http://$ip:3000/api/v1/register'); // Adjust API URL

      var body = json.encode({
        'username': name,
        'email': email,
        'password': password,
        'phone_number': "0568243138",
        'role': "user",
        'address': address,
        'gender': gender,
        'date_of_birth': dateOfBirth,
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
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = isWeb ? (screenWidth > 600 ? 500 : screenWidth * 0.9) : screenWidth;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 70.0),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isWeb ? 0 : 20.0),
                child: Form(
                  key: _formkey,
                  child: Container(
                    width: containerWidth.toDouble(),
                    child: Column(
                      children: [
                        // Name input field
                        _buildInputField(
                          controller: namecontroller,
                          hint: "Name",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter Name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30.0),

                        // Email input field with validation
                        _buildInputField(
                          controller: mailcontroller,
                          hint: "Email",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter Email';
                            } else if (!emailRegExp.hasMatch(value)) {
                              return 'Please Enter a Valid Email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30.0),

                        // Password input field with validation
                        _buildInputField(
                          controller: passwordcontroller,
                          hint: "Password",
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter Password';
                            } else if (value.length < 6) {
                              return 'Password must be at least 6 characters long';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30.0),

                        // Confirm Password input field with validation
                        _buildInputField(
                          controller: confirmPasswordController,
                          hint: "Confirm Password",
                          isPassword: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Confirm Password';
                            } else if (value != passwordcontroller.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30.0),

                        // Address input field with validation
                        _buildInputField(
                          controller: addressController,
                          hint: "Address",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter Address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30.0),

                        // Gender input field with validation
                        _buildInputField(
                          controller: genderController,
                          hint: "Gender",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter Gender';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30.0),

                        // Date of Birth input field with validation
                        _buildInputField(
                          controller: dateOfBirthController,
                          hint: "Date of Birth (YYYY-MM-DD)",
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter Date of Birth';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 30.0),

                        // Sign Up button
                        GestureDetector(
                          onTap: registration,
                          child: Container(
                            width: containerWidth.toDouble(),
                            padding: const EdgeInsets.symmetric(
                                vertical: 13.0, horizontal: 30.0),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Center(
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40.0),
            ],
          ),
        ),
      ),
    );
  }

// Helper method to build input fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 30.0),
      decoration: BoxDecoration(
        color: const Color(0xFFedf0f8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFb2b7bf),
            fontSize: 18.0,
          ),
        ),
        validator: validator,
        obscureText: isPassword,
      ),
    );
  }


}
