import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // لتحديد الميديا تايب للصورة
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'loginPage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

const String ip = "192.168.1.12";
const storage = FlutterSecureStorage();

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp>
    with SingleTickerProviderStateMixin {
  bool _isDarkMode = false;
  late AnimationController _iconAnimController;

  String email = "";
  String password = "";
  String confirmPassword = "";
  String name = "";
  String address = "";
  String gender = "";
  String dateOfBirth = "";
  String role = "user";

  TextEditingController namecontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController dateOfBirthController = TextEditingController();
  TextEditingController genderController = TextEditingController();

  final _formkey = GlobalKey<FormState>();
  final List<String> _genderList = ['Male', 'Female'];
  String? _selectedGender;

  final RegExp emailRegExp = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$",
  );

  final List<String> _roleList = ['User', 'Driver'];
  String? _selectedRole;

  // Flags for validation
  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordValid = false;
  bool _isConfirmPasswordValid = false;
  bool _isAddressValid = false;
  bool _isDOBValid = false;

  File? _licenseImage;

  @override
  void initState() {
    super.initState();
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

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _licenseImage = File(image.path);
      });
    }
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

      if (role == 'driver' && _licenseImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a photo of your driving license.')),
        );
        return;
      }

      if (role == 'driver') {
        var url = Uri.parse('http://$ip:3000/api/driversQue/drivers');

        try {
          var request = http.MultipartRequest('POST', url);

          request.fields['username'] = name;
          request.fields['email'] = email;
          request.fields['password'] = password;
          request.fields['phone_number'] = "0568243138";
          request.fields['date_of_birth'] = dateOfBirth;
          request.fields['gender'] = gender;
          request.fields['address'] = address;

          if (_licenseImage != null) {
            var stream = http.ByteStream(_licenseImage!.openRead());
            var length = await _licenseImage!.length();
            var multipartFile = http.MultipartFile(
              'license_image',
              stream,
              length,
              filename: _licenseImage!.path.split('/').last,
              contentType: MediaType('image', 'jpeg'),
            );
            request.files.add(multipartFile);
          }

          var response = await request.send();

          if (response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم التسجيل بنجاح!')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          } else {
            final respStr = await response.stream.bytesToString();
            var errorResponse = json.decode(respStr);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ: ${errorResponse['message']}')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الشبكة: $e')),
          );
        }
      } else {
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

        var url = Uri.parse('http://$ip:3000/api/v1/register');

        try {
          var response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          );

          if (response.statusCode == 201) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم التسجيل بنجاح!')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          } else {
            var errorResponse = json.decode(response.body);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('خطأ: ${errorResponse['message']}')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الشبكة: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth =
    isWeb ? (screenWidth > 600 ? 500 : screenWidth * 0.9) : screenWidth;

    final Color backgroundColor =
    _isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    final Color cardColor =
    _isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : Colors.grey[800]!;
    final Color labelColor =
    _isDarkMode ? Colors.white: Colors.grey[800]!;
    final Color hintColor = _isDarkMode
        ? Colors.grey[400]!
        : const Color(0xFFb2b7bf);
    final Color fieldBgColor = _isDarkMode
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFedf0f8);

    return Scaffold(
      appBar: AppBar(
        backgroundColor:
        _isDarkMode ? const Color(0xFF000000) : const Color(0xFFFFD700),
        title: const Center(
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
              firstChild:
              const Icon(Icons.brightness_7, color: Colors.white),
              secondChild:
              const Icon(Icons.brightness_2, color: Colors.white),
              crossFadeState: _isDarkMode
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
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
                    color: _isDarkMode
                        ? Colors.white
                        : const Color(0xFFFFD700),
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
                margin: const EdgeInsets.symmetric(
                    horizontal: isWeb ? 0 : 20.0),
                child: Card(
                  color: cardColor,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: SingleChildScrollView(
                      physics:
                      const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 35, horizontal: 25),
                        child: Form(
                          key: _formkey,
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.stretch,
                            children: [
                              _buildLabel("Name", labelColor),
                              const SizedBox(height: 8.0),
                              _buildInputField(
                                controller: namecontroller,
                                hint: "Enter your full name",
                                isFieldValid: _isNameValid,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty) {
                                    return 'Please Enter Name';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _isNameValid =
                                        value.trim().isNotEmpty;
                                  });
                                },
                                invalidMessage:
                                "Name can't be empty",
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
                                  if (value == null ||
                                      value.isEmpty) {
                                    return 'Please Enter Email';
                                  } else if (!emailRegExp
                                      .hasMatch(value)) {
                                    return 'Please Enter a Valid Email';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _isEmailValid =
                                        emailRegExp.hasMatch(
                                            value.trim());
                                  });
                                },
                                invalidMessage:
                                "Please provide a valid email",
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
                                  if (value == null ||
                                      value.isEmpty) {
                                    return 'Please Enter Address';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _isAddressValid =
                                        value.trim().isNotEmpty;
                                  });
                                },
                                invalidMessage:
                                "Address is required",
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
                                    genderController.text =
                                        value ?? "";
                                  });
                                },
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty) {
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
                              _buildLabel(
                                  "Date of Birth", labelColor),
                              const SizedBox(height: 8.0),
                              _buildInputField(
                                controller:
                                dateOfBirthController,
                                hint: "YYYY-MM-DD",
                                isFieldValid: _isDOBValid,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty) {
                                    return 'Please Enter Date of Birth';
                                  }
                                  final RegExp dateRegex =
                                  RegExp(
                                      r'^\d{4}-\d{2}-\d{2}$');
                                  if (!dateRegex.hasMatch(
                                      value)) {
                                    return 'Use format YYYY-MM-DD';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    final dateRegex =
                                    RegExp(
                                        r'^\d{4}-\d{2}-\d{2}$');
                                    _isDOBValid = dateRegex.hasMatch(
                                        value.trim());
                                  });
                                },
                                invalidMessage:
                                "Use format YYYY-MM-DD",
                                fieldBgColor: fieldBgColor,
                                textColor: textColor,
                                hintColor: hintColor,
                              ),
                              const SizedBox(height: 25.0),
                              _buildLabel("Password", labelColor),
                              const SizedBox(height: 8.0),
                              _buildInputField(
                                controller:
                                passwordcontroller,
                                hint: "At least 6 characters",
                                isPassword: true,
                                isFieldValid: _isPasswordValid,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty) {
                                    return 'Please Enter Password';
                                  } else if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _isPasswordValid =
                                        value.length >= 6;
                                  });
                                },
                                invalidMessage:
                                "Password must be at least 6 characters",
                                fieldBgColor: fieldBgColor,
                                textColor: textColor,
                                hintColor: hintColor,
                              ),
                              const SizedBox(height: 25.0),
                              _buildLabel(
                                  "Confirm Password", labelColor),
                              const SizedBox(height: 8.0),
                              _buildInputField(
                                controller:
                                confirmPasswordController,
                                hint:
                                "Re-enter your password",
                                isPassword: true,
                                isFieldValid:
                                _isConfirmPasswordValid,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty) {
                                    return 'Please Confirm Password';
                                  } else if (value !=
                                      passwordcontroller.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                                onChanged: (value) {
                                  setState(() {
                                    _isConfirmPasswordValid =
                                        value ==
                                            passwordcontroller
                                                .text;
                                  });
                                },
                                invalidMessage:
                                "Passwords must match",
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
                                  });
                                },
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty) {
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
                              if (_selectedRole?.toLowerCase() ==
                                  'driver')
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    _buildLabel(
                                        "Upload a picture of your driving license",
                                        labelColor),
                                    const SizedBox(height: 8.0),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _pickImage(
                                                ImageSource.camera);
                                          },
                                          icon: const Icon(
                                              Icons.camera_alt),
                                          label:
                                          const Text("camera"),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            _pickImage(
                                                ImageSource.gallery);
                                          },
                                          icon: const Icon(
                                              Icons.image),
                                          label:
                                          const Text("file"),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10.0),
                                    // عرض معاينة للصورة اذا تم اختيارها
                                    if (_licenseImage != null)
                                      Container(
                                        height: 150,
                                        width: 150,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey),
                                        ),
                                        child: Image.file(
                                          _licenseImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    const SizedBox(height: 25.0),
                                  ],
                                ),
                              Container(
                                height: 55,
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(30),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFFD700),
                                      Color(0xFFFFC000)
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFFD700)
                                          .withAlpha(3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: registration,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(30),
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

  /// Helper to build a label
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

  /// Helper to build input fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required String? Function(String?) validator,
    required bool isFieldValid,
    required String invalidMessage,
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
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: hintColor,
            fontSize: 14.0,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : (isFieldValid
              ? const Icon(Icons.check,
              color: Colors.green)
              : InkWell(
            onTap: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(
                  content:
                  Text(invalidMessage)));
            },
            child: const Icon(Icons.close,
                color: Colors.red),
          )),
        ),
      ),
    );
  }

  /// Helper to build dropdown fields
  Widget _buildDropdownField({
    required String hint,
    required List<String> items,
    required String? value,
    required void Function(String?) onChanged,
    required String? Function(String?) validator,
    required Color fieldBgColor,
    required Color textColor,
    required Color hintColor,
    Color? dropdownColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: fieldBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        dropdownColor: dropdownColor,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 4),
          hintStyle: TextStyle(
            color: textColor,
            fontSize: 14.0,
          ),
        ),
        style: TextStyle(
          fontSize: 14,
          color: hintColor,
        ),
        value: value,
        onChanged: onChanged,
        validator: validator,
        hint: Text(hint,
          style: TextStyle(color: hintColor),
        ),


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
