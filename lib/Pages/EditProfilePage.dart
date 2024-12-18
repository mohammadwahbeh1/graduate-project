import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
const String ip = "192.168.1.4";

class EditProfilePage extends StatefulWidget {
  final Map<String, String> userData; // Pass user data to this page

  const EditProfilePage({Key? key, required this.userData}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController phoneNumberController;
  late TextEditingController dateOfBirthController;
  late TextEditingController genderController;
  late TextEditingController addressController;
  late TextEditingController licenseNumberController; // For license number

  final storage = const FlutterSecureStorage(); // For storing JWT token
  bool isLoading = false; // To track loading state
  String? errorMessage; // To store error messages


  @override
  void initState() {
    super.initState();

    // Initialize text controllers with the passed user data
    usernameController = TextEditingController(text: widget.userData['username']);
    emailController = TextEditingController(text: widget.userData['email']);
    phoneNumberController = TextEditingController(text: widget.userData['phone_number']);
    dateOfBirthController = TextEditingController(text: widget.userData['date_of_birth']);
    genderController = TextEditingController(text: widget.userData['gender']);
    addressController = TextEditingController(text: widget.userData['address']);

    // Initialize the license number controller only if the user is a driver
    if (widget.userData.containsKey('license_number')) {
      licenseNumberController = TextEditingController(text: widget.userData['license_number']);
    } else {
      licenseNumberController = TextEditingController(); // Set an empty controller if not a driver
    }
  }

  @override
  void dispose() {
    // Dispose controllers to free up memory
    usernameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    dateOfBirthController.dispose();
    genderController.dispose();
    addressController.dispose();
    licenseNumberController.dispose();
    super.dispose();
  }

  Future<void> updateProfile() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? token = await storage.read(key: 'jwt_token'); // Get the token

      if (token != null) {
        final response = await http.patch(
          Uri.parse('http://$ip:3000/api/v1/users/profile'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'username': usernameController.text,
            'email': emailController.text,
            'phone_number': phoneNumberController.text,
            'date_of_birth': dateOfBirthController.text,
            'gender': genderController.text,
            'address': addressController.text,
            // Only include license_number if the user is a driver
            if (widget.userData.containsKey('license_number'))
              'license_number': licenseNumberController.text,
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            isLoading = false;
          });
          showSuccessDialog(); // Show success message
        } else {
          throw Exception('Failed to update profile');
        }
      } else {
        throw Exception('Token is null');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error updating profile: $e';
      });
      showErrorDialog(); // Show error message
    }
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Profile Updated"),
        content: const Text("Your profile has been successfully updated."),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.pop(context); // Close the alert dialog
              Navigator.pop(context, {
                'username': usernameController.text,
                'email': emailController.text,
                'phone_number': phoneNumberController.text,
                'date_of_birth': dateOfBirthController.text,
                'gender': genderController.text,
                'address': addressController.text,
                // Return the license number if available
                if (widget.userData.containsKey('license_number'))
                  'license_number': licenseNumberController.text,
              });
            },
          ),
        ],
      ),
    );
  }

  void showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(errorMessage ?? "An unknown error occurred."),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.pop(context); // Close the alert dialog
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9A602),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Picture
            const SizedBox(height: 20),
            Center(
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/profile.jpg'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // Handle profile picture change
                      },
                      child: const CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.camera_alt, size: 16, color: Color(0xFFF9A602)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Input Fields
            _buildInputField('Name', usernameController, Icons.person),
            _buildInputField('Email Address', emailController, Icons.email, isReadOnly: true),
            _buildInputField('Phone Number', phoneNumberController, Icons.phone),
            _buildInputField('Date of Birth', dateOfBirthController, Icons.calendar_today),
            _buildInputField('Gender', genderController, Icons.accessibility),
            _buildInputField('Address', addressController, Icons.location_on),

            // License Number field for drivers (only visible for drivers)
            if (widget.userData.containsKey('license_number'))
              _buildInputField('License Number', licenseNumberController, Icons.badge),

            const SizedBox(height: 30),

            // Update Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF9A602), // Match the profile page color
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
              ),
              onPressed: isLoading ? null : updateProfile, // Disable button while loading
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'UPDATE PROFILE',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),

            // Error Message
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFF9A602)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFF9A602)),
          ),
        ),
      ),
    );
  }
}
