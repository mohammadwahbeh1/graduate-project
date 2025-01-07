import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For making HTTP requests
import 'dart:convert'; // For encoding/decoding JSON
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // For secure storage
import 'loginPage.dart'; // Navigate to login page after successful sign-up
import 'package:flutter/foundation.dart';

const String ip = "192.168.1.12";

// Create a secure storage instance
final storage = FlutterSecureStorage();

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> with SingleTickerProviderStateMixin {
  // Toggle for Dark Mode
  bool _isDarkMode = false;

  // We'll animate between two icons (sun & moon)
  late AnimationController _iconAnimController;

  String email = "";
  String password = "";
  String confirmPassword = "";
  String name = "";
  String address = "";
  String gender = "";
  String dateOfBirth = "";
  String role = "user";
  String licenseNumber = "";
  String lineId = "";

  // Controllers
  TextEditingController namecontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController dateOfBirthController = TextEditingController();
  TextEditingController genderController = TextEditingController();
  TextEditingController licenseNumberController = TextEditingController();
  TextEditingController lineIdController = TextEditingController();

  final _formkey = GlobalKey<FormState>();

  // We'll use a small list for gender
  final List<String> _genderList = ['Male', 'Female'];
  String? _selectedGender;

  // Email regex validation
  final RegExp emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$",
  );
  // Dropdown lists

  final List<String> _roleList = ['User', 'Line Manager', 'Driver'];

  String? _selectedRole;
  // Validation flags
  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _isAddressValid = false;
  bool _isDOBValid = false;
  bool _isLicenseValid = false;
  bool _isLineIdValid = false;

  @override
  void initState() {
    super.initState();
    // AnimationController to manage any future transitions if needed
    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _iconAnimController.dispose();
    super.dispose();
  }





  Future<void> registration() async {
    if (_formkey.currentState!.validate()) {
      setState(() {
        email = mailcontroller.text;
        name = namecontroller.text;
        password = passwordcontroller.text;
        address = addressController.text;
        gender = genderController.text;
        dateOfBirth = dateOfBirthController.text;
        role = _selectedRole?.toLowerCase() ?? 'user';
      });

      var body = {
        'username': name,
        'email': email,
        'password': password,
        'phone_number': "0568243138",
        'role': role,
        'address': address,
        'gender': gender,
        'date_of_birth': dateOfBirth,
      };

      if (role == 'driver') {
        body['license_number'] = licenseNumberController.text;
      } else if (role == 'line manager') {
        body['line_id'] = lineIdController.text;
      }

      var url = Uri.parse('http://$ip:3000/api/v1/register');

      try {
        var response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Signup successful!')),
          );
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
    const isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = isWeb ? (screenWidth > 600 ? 500 : screenWidth * 0.9) : screenWidth;

    final Color backgroundColor = _isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final Color cardColor = _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : Colors.grey[800]!;
    final Color labelColor = _isDarkMode ? Colors.yellow.shade200 : Colors.grey[800]!;
    final Color hintColor = _isDarkMode ? Colors.grey[400]! : const Color(0xFFb2b7bf);
    final Color fieldBgColor = _isDarkMode ? const Color(0xFF3A3A3A) : const Color(0xFFedf0f8);

    return Scaffold(
      appBar: AppBar(
        
        backgroundColor: _isDarkMode ? const Color(0xFF000000) : const Color(0xFFFFD700),
        title:  Center(
          child: Text(
              "Sign Up",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Colors.white,
            ),

          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
            icon: AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              firstChild: const Icon(Icons.brightness_7, color: Colors.white),
              secondChild: const Icon(Icons.brightness_2, color: Colors.white),
              crossFadeState: _isDarkMode ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            ),
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add_alt,
                    size: 36,
                    color: _isDarkMode ? Colors.yellow.shade200 : const Color(0xFFFFD700),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Create an Account",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),


              const SizedBox(height: 10),




                       Text(
                      "Welcome! Please fill out the form to continue.",
                         textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: _isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                                     ),


              const SizedBox(height: 30.0),

              Container(
                width: containerWidth.toDouble(),
                margin: EdgeInsets.symmetric(horizontal: isWeb ? 0 : 20.0),
                child: Card(
                  color: cardColor,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 25),
                        child: Form(
                          key: _formkey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLabel("Name", labelColor),
                              const SizedBox(height: 8.0),
                              _buildInputField(
                                controller: namecontroller,
                                hint: "Enter your full name",
                                isFieldValid: _isNameValid,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Name';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _isNameValid = value.trim().isNotEmpty;
                                  });
                                },
                                invalidMessage: "Name can't be empty",
                                fieldBgColor: fieldBgColor,
                                textColor: textColor,
                                hintColor: hintColor,
                              ),
                              const SizedBox(height: 25.0),

                              _buildLabel("Email", labelColor),
                              const SizedBox(height: 8.0),
                              _buildInputField(
                                controller: mailcontroller,
                                hint: "example@domain.com",
                                isFieldValid: _isEmailValid,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Email';
                                  } else if (!emailRegExp.hasMatch(value)) {
                                    return 'Please Enter a Valid Email';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _isEmailValid = emailRegExp.hasMatch(value.trim());
                                  });
                                },
                                invalidMessage: "Please provide a valid email",
                                fieldBgColor: fieldBgColor,
                                textColor: textColor,
                                hintColor: hintColor,
                              ),
                              const SizedBox(height: 25.0),

                              _buildLabel("Address", labelColor),
                              const SizedBox(height: 8.0),
                              _buildInputField(
                                controller: addressController,
                                hint: "Enter your address",
                                isFieldValid: _isAddressValid,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Address';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _isAddressValid = value.trim().isNotEmpty;
                                  });
                                },
                                invalidMessage: "Address is required",
                                fieldBgColor: fieldBgColor,
                                textColor: textColor,
                                hintColor: hintColor,
                              ),
                              const SizedBox(height: 25.0),

                              _buildLabel("Gender", labelColor),
                              const SizedBox(height: 8.0),
                              _buildDropdownField(
                                hint: "Select Gender",
                                items: _genderList,
                                value: _selectedGender,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedGender = value;
                                    genderController.text = value ?? "";
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Select Gender';
                                  }
                                  return null;
                                },
                                fieldBgColor: fieldBgColor,
                                textColor: textColor,
                                hintColor: hintColor,
                                dropdownColor: fieldBgColor,
                              ),
                              const SizedBox(height: 25.0),

                              _buildLabel("Date of Birth", labelColor),
                              const SizedBox(height: 8.0),
                              _buildInputField(
                                controller: dateOfBirthController,
                                hint: "YYYY-MM-DD",
                                isFieldValid: _isDOBValid,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Date of Birth';
                                  }
                                  final RegExp dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                                  if (!dateRegex.hasMatch(value)) {
                                    return 'Use format YYYY-MM-DD';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    final dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
                                    _isDOBValid = dateRegex.hasMatch(value.trim());
                                  });
                                },
                                invalidMessage: "Use format YYYY-MM-DD",
                                fieldBgColor: fieldBgColor,
                                textColor: textColor,
                                hintColor: hintColor,
                              ),
                              const SizedBox(height: 25.0),

                              _buildLabel("Password", labelColor),
                              const SizedBox(height: 8.0),
                              _buildInputField(
                                controller: passwordcontroller,
                                hint: "At least 6 characters",
                                isPassword: true,
                                isFieldValid: _isPasswordValid,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Password';
                                  } else if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _isPasswordValid = value.length >= 6;
                                  });
                                },
                                invalidMessage: "Password must be at least 6 characters",
                                fieldBgColor: fieldBgColor,
                                textColor: textColor,
                                hintColor: hintColor,
                              ),
                              const SizedBox(height: 25.0),

                              _buildLabel("Confirm Password", labelColor),
                              const SizedBox(height: 8.0),
                              _buildInputField(
                                controller: confirmPasswordController,
                                hint: "Re-enter your password",
                                isPassword: true,
                                isFieldValid: _isConfirmPasswordValid,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Confirm Password';
                                  } else if (value != passwordcontroller.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _isConfirmPasswordValid = value == passwordcontroller.text;
                                  });
                                },
                                invalidMessage: "Passwords must match",
                                fieldBgColor: fieldBgColor,
                                textColor: textColor,
                                hintColor: hintColor,
                              ),
                              const SizedBox(height: 25.0),

                              _buildLabel("Role", labelColor),
                              const SizedBox(height: 8.0),
                              _buildDropdownField(
                                hint: "Select Role",
                                items: _roleList,
                                value: _selectedRole,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value;
                                    licenseNumberController.clear();
                                    lineIdController.clear();
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Select Role';
                                  }
                                  return null;
                                },
                                fieldBgColor: fieldBgColor,
                                textColor: textColor,
                                hintColor: hintColor,
                                dropdownColor: fieldBgColor,
                              ),
                              const SizedBox(height: 25.0),

                              if (_selectedRole == 'Driver') ...[
                                _buildLabel("License Number", labelColor),
                                const SizedBox(height: 8.0),
                                _buildInputField(
                                  controller: licenseNumberController,
                                  hint: "Enter your license number",
                                  isFieldValid: _isLicenseValid,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter license number';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _isLicenseValid = value.trim().isNotEmpty;
                                    });
                                  },
                                  invalidMessage: "License number required",
                                  fieldBgColor: fieldBgColor,
                                  textColor: textColor,
                                  hintColor: hintColor,
                                ),
                                const SizedBox(height: 25.0),
                              ],

                              if (_selectedRole == 'Line Manager') ...[
                                _buildLabel("Line ID", labelColor),
                                const SizedBox(height: 8.0),
                                _buildInputField(
                                  controller: lineIdController,
                                  hint: "Enter your line ID",
                                  isFieldValid: _isLineIdValid,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter line ID';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    setState(() {
                                      _isLineIdValid = value.trim().isNotEmpty;
                                    });
                                  },
                                  invalidMessage: "Line ID required",
                                  fieldBgColor: fieldBgColor,
                                  textColor: textColor,
                                  hintColor: hintColor,
                                ),
                                const SizedBox(height: 25.0),
                              ],

                              Container(
                                height: 55,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD700), Color(0xFFFFC000)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: registration,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: const Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )


            ],
          ),
        ),
      ),
    );
  }



  /// Simple helper to build a label above each field
  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // Helper method to build text input fields (with real-time validation icon)
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    required bool isFieldValid, // For deciding check vs cross
    required String invalidMessage, // Explains the error when tapped
    required Color fieldBgColor,
    required Color textColor,
    required Color hintColor,
    bool isPassword = false,
    void Function(String)? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        onChanged: onChanged,
        obscureText: isPassword,
        style: TextStyle(
          fontSize: 16,
          color: textColor,
        ),
        decoration: InputDecoration(
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 14.0,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : (isFieldValid
              ? const Icon(Icons.check, color: Colors.green)
              : InkWell(
            onTap: () {
              // Show a small explanation if invalid
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(invalidMessage)),
              );
            },
            child: const Icon(Icons.close, color: Colors.red),
          )),
        ),
      ),
    );
  }

  // Helper for creating the gender dropdown with the *same* look
  Widget _buildDropdownField({
    required String hint,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
    required Color fieldBgColor,
    required Color textColor,
    required Color hintColor,
    // Additional param for the dropdown color in dark mode
    Color? dropdownColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        dropdownColor: dropdownColor, // ensures the dropdown menu is also dark
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 14.0,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          color: textColor,
        ),
        value: value,
        onChanged: onChanged,
        validator: validator,
        hint: Text(hint),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
      ),
    );
  }
}
