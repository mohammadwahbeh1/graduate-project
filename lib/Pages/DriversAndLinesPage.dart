import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Splash_screen.dart';

const String ip = "192.168.1.8";

class DriversAndLinesPage extends StatefulWidget {
  const DriversAndLinesPage({super.key});

  @override
  State<DriversAndLinesPage> createState() => _DriversAndLinesPageState();
}

class _DriversAndLinesPageState extends State<DriversAndLinesPage> {
  List<Map<String, dynamic>> driversAndLines = [];
  List<Map<String, dynamic>> filteredDrivers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDriversAndLines();
  }

  Future<void> fetchDriversAndLines() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorDialog('Token is missing or invalid');
        return;
      }

      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/admin/ine/driver'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        setState(() {
          driversAndLines = data.cast<Map<String, dynamic>>();
          filteredDrivers = driversAndLines;
          isLoading = false;
        });
      } else {
        _showErrorDialog('Failed to fetch drivers: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error fetching drivers: $e');
    }
  }

  void _filterDrivers(String query) {
    setState(() {
      filteredDrivers = driversAndLines
          .where((driver) =>
      driver['driver_name']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()) ||
          driver['line_name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers and Lines'),
        backgroundColor: Colors.blueAccent,  // Updated color to blue for freshness
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search Drivers or Lines',
                labelStyle: const TextStyle(color: Colors.blueAccent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.blueAccent),
                ),
                suffixIcon: const Icon(Icons.search, color: Colors.blueAccent),
              ),
              onChanged: _filterDrivers,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredDrivers.length,
              itemBuilder: (context, index) {
                final driver = filteredDrivers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: GestureDetector(
                    onTap: () {
                      // Add any tap action if needed
                    },
                    child: Card(
                      elevation: 10,  // Added elevation for a more modern look
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      shadowColor: Colors.black.withOpacity(0.3),  // Darker shadow for better contrast
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,  // Gradient using blue shades
                              Colors.blue.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          leading: const CircleAvatar(
                            radius: 30,

                            // For local images, use:
                             backgroundImage: AssetImage('assets/commenter-1.jpg'),
                          ),
                          title: Text(
                            driver['driver_name'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,  // White text for better visibility
                            ),
                          ),
                          subtitle: Text(
                            'Line: ${driver['line_name']}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,  // Slightly lighter text for subtitle
                            ),
                          ),
                          trailing: Text(
                            'Phone: ${driver['driver_phone']}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,  // White color for clarity
                            ),
                          ),
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
