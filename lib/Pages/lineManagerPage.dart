import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:untitled/Pages/profilePage.dart';
import 'DriverCall.dart';
import 'package:http/http.dart' as http;

import 'loginPage.dart';


class LineManagerPage extends StatefulWidget {
  const LineManagerPage({super.key});

  @override
  State<LineManagerPage> createState() => _LineManagerPageState();
}

class _LineManagerPageState extends State<LineManagerPage> {
  String username='';

  Future<void> fetchUserProfile() async {
    String? token = await storage.read(key: 'jwt_token');

    if (token == null) {
      setState(() {
        username = "No Token Found";
      });
      return;
    }

    final url = Uri.parse("http://192.168.1.8:3000/api/v1/users/Profile");

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          username = data['data']['username'];
        });
      } else {
        setState(() {
          username = "Failed to load";
        });
      }
    } catch (e) {
      setState(() {
        username = "Error";
      });
      print("Error fetching user profile: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Line Manager Dashboard",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person,
              size: 30,
              color: Colors.white,
            ),
            onPressed: () {
              _showProfileOptions(context);
            },
          ),
        ],
      ),
      drawer: buildDrawer(context),
      body: const Center(
        child: Text(
          "Welcome to the Line Manager's Page",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Header Section with Profile Info
          Container(
            height: MediaQuery.of(context).size.height * 0.30,
            decoration: const BoxDecoration(
              color: Colors.yellow,
            ),
            child:  Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/profile.jpg'), // Replace with your image path
                ),
                SizedBox(height: 23),
                // User Information
                Text(
                  username,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,

                  ),
                ),


                // Stats Row

              ],
            ),
          ),
          SizedBox(height: 20),
          // Drawer List Items (your existing logic)
          ListTile(
            leading:  const Icon(Icons.directions_bus, size: 28),
            title: const Text('Manage Lines', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);

            },
          ),
          SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.supervised_user_circle,size: 28,),
            title: const Text('View Drivers', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
            },
          ),


          SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.call, size: 28),
            title: const Text('Call Driver', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CallDriverPage()),
              );
            },
          ),
          SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout,size: 28,),
            title: const Text('Log out'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showProfileOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile Options'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('View Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
