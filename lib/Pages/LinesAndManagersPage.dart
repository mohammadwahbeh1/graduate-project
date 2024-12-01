import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Splash_screen.dart';

const String ip = "192.168.1.8";

class LinesAndManagersPage extends StatefulWidget {
  const LinesAndManagersPage({super.key});

  @override
  State<LinesAndManagersPage> createState() => _LinesAndManagersPageState();
}

class _LinesAndManagersPageState extends State<LinesAndManagersPage> {
  List<Map<String, dynamic>> linesAndManagers = [];
  List<Map<String, dynamic>> filteredLines = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLinesAndManagers();
  }

  Future<void> fetchLinesAndManagers() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorDialog('Token is missing or invalid');
        return;
      }

      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/admin/line/manger'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'] as List;
        setState(() {
          linesAndManagers = data.cast<Map<String, dynamic>>();
          filteredLines = linesAndManagers;
          isLoading = false;
        });
      } else {
        _showErrorDialog('Failed to fetch lines: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Error fetching lines: $e');
    }
  }

  void _filterLines(String query) {
    setState(() {
      filteredLines = linesAndManagers
          .where((line) =>
      line['lineName']
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()) ||
          line['managerName']
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
        title: const Text('Lines and Managers'),
        backgroundColor: Colors.blueAccent,  // Changed to blue for a fresh look
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
                labelText: 'Search Lines or Managers',
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
              onChanged: _filterLines,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredLines.length,
              itemBuilder: (context, index) {
                final line = filteredLines[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: GestureDetector(
                    onTap: () {
                      // You can add any action on tap if needed
                    },
                    child: Card(
                      elevation: 10, // Slightly higher elevation for a more modern look
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      shadowColor: Colors.black.withOpacity(0.3),  // Darker shadow for more contrast
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,  // Gradient with shades of blue
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
                            backgroundImage: AssetImage('assets/commenter-1.jpg'), // Example image
                          ),
                          title: Text(
                            line['lineName'],
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),  // White text for contrast
                          ),
                          subtitle: Text(
                            'Manager: ${line['managerName']}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,  // Slightly lighter subtitle text
                            ),
                          ),
                          trailing: const Icon(
                            Icons.directions_bus,
                            color: Colors.white,
                            size: 28,
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
