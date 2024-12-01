import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Splash_screen.dart';

const String ip = "192.168.1.8";

class UsersManagementPage extends StatefulWidget {
  const UsersManagementPage({super.key});

  @override
  State<UsersManagementPage> createState() => _UsersManagementPageState();
}

class _UsersManagementPageState extends State<UsersManagementPage> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = true;

  String? selectedRole;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> updateUserRole(int userId, String newRole) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorDialog('Token is missing or invalid');
        return;
      }

      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/users/update-role'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'userId': userId, 'newRole': newRole}),
      );

      if (response.statusCode == 200) {
        _showSuccessDialog('User role updated successfully!');
        fetchUsers();
      } else {
        _showErrorDialog('Failed to update role: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error updating role: $e');
    }
  }

  Future<void> fetchUsers() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorDialog('Token is missing or invalid');
        return;
      }

      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/users'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          final data = responseData['data'];
          if (data is List) {
            setState(() {
              users = data.cast<Map<String, dynamic>>();
              filteredUsers = users;
              isLoading = false;
            });
          } else {
            _showErrorDialog('Unexpected data format: "data" is not a list.');
          }
        } else {
          _showErrorDialog('Invalid response structure: "data" key missing.');
        }
      } else {
        _showErrorDialog('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error fetching users: $e');
    }
  }

  void _filterUsers(String query) {
    setState(() {
      filteredUsers = users
          .where((user) =>
      (user['username']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()) ||
          user['email']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase())) &&
          (selectedRole == null || user['role'] == selectedRole))
          .toList();
    });
  }

  void _filterByRole(String? role) {
    setState(() {
      selectedRole = role;
      filteredUsers = users.where((user) {
        final matchesRole = selectedRole == null || user['role'] == selectedRole;
        return matchesRole;
      }).toList();
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Search by name or email',
                      labelStyle: const TextStyle(color: Colors.teal),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.teal),
                      ),
                      suffixIcon:
                      const Icon(Icons.search, color: Colors.teal),
                    ),
                    onChanged: _filterUsers,
                  ),
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedRole,
                  hint: const Text('Filter by Role'),
                  items: const [
                    DropdownMenuItem(
                      value: null,
                      child: Text('All Roles'),
                    ),
                    DropdownMenuItem(
                      value: 'user',
                      child: Text('User'),
                    ),
                    DropdownMenuItem(
                      value: 'driver',
                      child: Text('Driver'),
                    ),
                    DropdownMenuItem(
                      value: 'line_manager',
                      child: Text('Line Manager'),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin'),
                    ),
                  ],
                  onChanged: _filterByRole,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                String currentRole = user['role'];

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.teal.shade500,
                            Colors.teal.shade200
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          user['username'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email: ${user['email']}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'Role: $currentRole',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        trailing: DropdownButton<String>(
                          dropdownColor: Colors.teal,
                          value: currentRole,
                          items: const [
                            DropdownMenuItem(
                              value: 'user',
                              child: Text('User',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            DropdownMenuItem(
                              value: 'driver',
                              child: Text('Driver',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            DropdownMenuItem(
                              value: 'line_manager',
                              child: Text('Line Manager',
                                  style: TextStyle(color: Colors.white)),
                            ),
                            DropdownMenuItem(
                              value: 'admin',
                              child: Text('Admin',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                          onChanged: (newRole) {
                            if (newRole != null &&
                                newRole != currentRole) {
                              updateUserRole(user['user_id'], newRole);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
