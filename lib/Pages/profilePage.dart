import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import './EditProfilePage.dart';

const String ip = "192.168.1.2";


class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final storage = const FlutterSecureStorage(); // For storing JWT token
  Map<String, String> userData = {}; // To store user profile data
  bool isLoading = true; // To track loading state
  String? errorMessage; // To store error messages

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      String? token = await storage.read(key: 'jwt_token'); // Get the token

      if (token != null) {
        final response = await http.get(
          Uri.parse('http://$ip:3000/api/v1/users/profile'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body)['data'];
          setState(() {
            userData = {
              'username': data['username'] ?? '',
              'email': data['email'] ?? '',
              'phone_number': data['phone_number'] ?? '',
              'date_of_birth': data['date_of_birth'] ?? '',
              'gender': data['gender'] ?? '',
              'address': data['address'] ?? '',
            };
            isLoading = false;
          });
        } else {
          throw Exception('Failed to fetch profile');
        }
      } else {
        throw Exception('Token is null');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error fetching profile: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Text(errorMessage!))
          : SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFF9A602)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(userData: userData),
                        ),
                      ).then((updatedData) {
                        if (updatedData != null) {
                          setState(() {
                            userData = updatedData;
                          });
                        }
                      });
                    },
                  ),
                ),
                Positioned(
                  top: 60,
                  left: MediaQuery.of(context).size.width / 2 - 50,
                  child: const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/profile.jpg'),
                  ),
                ),
                Positioned(
                  top: 140,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      userData['username'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Information Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.person, "Username", userData['username'] ?? ''),
                  const Divider(),
                  _buildInfoRow(Icons.email, "Email", userData['email'] ?? ''),
                  const Divider(),
                  _buildInfoRow(Icons.phone, "Phone Number", userData['phone_number'] ?? ''),
                  const Divider(),
                  _buildInfoRow(Icons.calendar_today, "Date of Birth", userData['date_of_birth'] ?? ''),
                  const Divider(),
                  _buildInfoRow(Icons.accessibility, "Gender", userData['gender'] ?? ''),
                  const Divider(),
                  _buildInfoRow(Icons.location_on, "Address", userData['address'] ?? ''),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFFF9C4), // Yellow background
            child: Icon(icon, color: const Color(0xFFF9A602)), // Dark yellow icon
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
