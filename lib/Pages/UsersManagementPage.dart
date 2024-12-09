import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// تأكد من إضافة التخزين الآمن أو تعريف `storage` بشكل مناسب
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
        backgroundColor: Colors.red[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.red)),
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
        backgroundColor: Colors.green[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // استخدام AppBar بتصميم محدث
      appBar: AppBar(
        title: const Text('Manage Users'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWeb = constraints.maxWidth > 800; // Determines if the screen size is for web

          return isLoading
              ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00B4DB)),
            ),
          )
              : Padding(
            padding: isWeb
                ? const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0) // Larger padding for web
                : const EdgeInsets.all(16.0), // Smaller padding for mobile
            child: Column(
              children: [
                // Search and filter section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search by name or email',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF0083B0)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Color(0xFF0083B0)),
                            ),
                          ),
                          onChanged: _filterUsers,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: const Color(0xFF0083B0)),
                        ),
                        child: DropdownButton<String>(
                          value: selectedRole,
                          hint: const Text('Filter by Role', style: TextStyle(color: Color(0xFF0083B0))),
                          icon: const Icon(Icons.filter_list, color: Color(0xFF0083B0)),
                          dropdownColor: Colors.white,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: null,
                              child: Text('All Roles', style: TextStyle(color: Colors.black)),
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Displaying users in a responsive layout
                Expanded(
                  child: filteredUsers.isEmpty
                      ? Center(
                    child: Text(
                      'No users found.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  )
                      : isWeb
                      ? GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 3,
                    ),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _buildUserCard(user);
                    },
                  )
                      : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _buildUserCard(user);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget to build individual user cards with improved styling
  Widget _buildUserCard(Map<String, dynamic> user) {
    String currentRole = user['role'];

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: Colors.grey.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // أيقونة المستخدم
            CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFF00B4DB),
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            // معلومات المستخدم
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['username'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF0083B0),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Email: ${user['email']}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Role: ${_capitalize(currentRole)}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // قائمة منسدلة لتغيير الدور
            DropdownButton<String>(
              value: currentRole,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0083B0)),
              dropdownColor: Colors.blue.shade50,
              underline: const SizedBox(),
              items: const [
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
              onChanged: (newRole) {
                if (newRole != null && newRole != currentRole) {
                  updateUserRole(user['user_id'], newRole);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String role) {
    return role.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
}
