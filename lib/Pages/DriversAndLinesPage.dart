import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'Splash_screen.dart';

const String ip = "192.168.1.3";

class DriversAndLinesPage extends StatefulWidget {
  const DriversAndLinesPage({super.key});

  @override
  State<DriversAndLinesPage> createState() => _DriversAndLinesPageState();
}

class _DriversAndLinesPageState extends State<DriversAndLinesPage> {
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> driversAndLines = [];
  List<Map<String, dynamic>> filteredDrivers = [];
  bool isLoading = true;

  String? selectedRole; // إذا كان هناك دور لتصفية السائقين بناءً عليه

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDriversAndLines();
    searchController.addListener(_filterDrivers);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchDriversAndLines() async {
    setState(() {
      isLoading = true;
    });
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Authentication token is missing or invalid.');
        return;
      }

      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/admin/ine/driver'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        setState(() {
          driversAndLines = data.cast<Map<String, dynamic>>();
          filteredDrivers = driversAndLines;
          isLoading = false;
        });
      } else {
        _showErrorSnackbar('Failed to fetch drivers: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching drivers: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterDrivers() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredDrivers = driversAndLines.where((driver) {
        bool matchesQuery = driver['driver_name']
            .toString()
            .toLowerCase()
            .contains(query) ||
            driver['line_name']
                .toString()
                .toLowerCase()
                .contains(query);
        // إذا كان هناك دور للتصفية، يمكن إضافة شرط هنا
        // bool matchesRole = selectedRole == null || driver['role'] == selectedRole;
        return matchesQuery; // && matchesRole;
      }).toList();
    });
  }

  void _filterByRole(String? role) {
    setState(() {
      selectedRole = role;
      _filterDrivers();
    });
  }

  // Show error snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Show success snackbar
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // إذا كنت تحتاج إلى تحديث دور السائقين، يمكنك إضافة دوال هنا

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // استخدام AppBar بتصميم متناسق
      appBar: AppBar(
        title: const Text('Drivers and Lines'),
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
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWeb = constraints.maxWidth > 800; // Determines if the screen size is for web

          return isLoading
              ? Center(
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B4DB)),
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
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by driver name or line',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF0083B0)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Color(0xFF0083B0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // إذا كنت تحتاج إلى فلتر إضافي بناءً على الدور، يمكنك إلغاء التعليق على الكود التالي
                      /*
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: const Color(0xFF0083B0)),
                              ),
                              child: DropdownButton<String>(
                                value: selectedRole,
                                hint: const Text('Filter by Role',
                                    style: TextStyle(color: Color(0xFF0083B0))),
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
                            */
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Displaying drivers and lines in a responsive layout
                Expanded(
                  child: filteredDrivers.isEmpty
                      ? Center(
                    child: Text(
                      'No drivers or lines found.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  )
                      : isWeb
                      ? GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 3,
                    ),
                    itemCount: filteredDrivers.length,
                    itemBuilder: (context, index) {
                      final driver = filteredDrivers[index];
                      return _buildDriverCard(driver);
                    },
                  )
                      : ListView.builder(
                    itemCount: filteredDrivers.length,
                    itemBuilder: (context, index) {
                      final driver = filteredDrivers[index];
                      return _buildDriverCard(driver);
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

  // Widget to build individual driver cards with improved styling
  Widget _buildDriverCard(Map<String, dynamic> driver) {
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
            // أيقونة السائق أو الخط
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF00B4DB),
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            // معلومات السائق أو الخط
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver['driver_name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF0083B0),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Line: ${driver['line_name']}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Phone: ${driver['driver_phone']}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

}
