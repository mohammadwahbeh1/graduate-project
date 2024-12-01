import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TerminalPage extends StatefulWidget {
  @override
  _TerminalPageState createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final storage = FlutterSecureStorage();
  List<dynamic> terminals = [];
  List<dynamic> admins = [];
  String ip = '192.168.1.8';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTerminals();
    fetchAdmins();
  }

  Future<void> fetchTerminals() async {
    setState(() {
      isLoading = true;
    });
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorDialog('Token is missing or invalid');
        return;
      }

      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/terminals'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          terminals = data;
        });
      } else {
        _showErrorDialog('Failed to fetch terminals');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAdmins() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorDialog('Token is missing or invalid');
        return;
      }

      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/terminals/manager'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          admins = data;
        });
      } else {
        _showErrorDialog('Failed to fetch managers');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }

  // عرض نافذة الخطأ
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // عرض نافذة إضافة المحطة
  void _showAddTerminalDialog() {
    final terminalNameController = TextEditingController();
    final totalVehiclesController = TextEditingController();
    dynamic selectedAdmin;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Terminal', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: terminalNameController,
              decoration: const InputDecoration(
                labelText: 'Terminal Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: totalVehiclesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Vehicles',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField(
              value: selectedAdmin,
              items: admins
                  .map((admin) => DropdownMenuItem(
                value: admin['user_id'],
                child: Text(admin['username']),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedAdmin = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Select Admin'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (terminalNameController.text.isNotEmpty &&
                  totalVehiclesController.text.isNotEmpty &&
                  selectedAdmin != null) {
                createTerminal(
                  terminalNameController.text,
                  '', // Set the location_center as needed
                  totalVehiclesController.text,
                  selectedAdmin,
                );
                Navigator.of(context).pop();
              } else {
                _showErrorDialog('Please fill in all fields');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // إرسال طلب إضافة المحطة
  Future<void> createTerminal(String terminalName, String locationCenter, String totalVehicles, String userId) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorDialog('Token is missing or invalid');
        return;
      }

      final response = await http.post(
        Uri.parse('http://$ip:3000/api/v1/terminals'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'terminal_name': terminalName,
          'location_center': locationCenter,
          'total_vehicles': totalVehicles,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        fetchTerminals(); // Reload terminals after creating
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Unknown error occurred';
        _showErrorDialog('Failed to create terminal: $errorMessage');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }

  // عرض المحطات
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terminals'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: terminals.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(terminals[index]['terminal_name']),
            subtitle: Text('Total Vehicles: ${terminals[index]['total_vehicles']}'),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => _showEditTerminalDialog(terminals[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTerminalDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  // عرض نافذة تحديث المحطة
  void _showEditTerminalDialog(dynamic terminal) {
    final terminalNameController = TextEditingController(text: terminal['terminal_name']);
    final totalVehiclesController = TextEditingController(text: terminal['total_vehicles'].toString());
    dynamic selectedAdmin = terminal['user_id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Terminal', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: terminalNameController,
              decoration: const InputDecoration(
                labelText: 'Terminal Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: totalVehiclesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Total Vehicles',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField(
              value: selectedAdmin,
              items: admins
                  .map((admin) => DropdownMenuItem(
                value: admin['user_id'],
                child: Text(admin['username']),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedAdmin = value;
                });
              },
              decoration: const InputDecoration(labelText: 'Select Admin'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (terminalNameController.text.isNotEmpty &&
                  totalVehiclesController.text.isNotEmpty &&
                  selectedAdmin != null) {
                updateTerminal(
                  terminal['terminal_id'], // ID for the terminal to be updated
                  terminalNameController.text,
                  '', // Set location_center as needed
                  totalVehiclesController.text,
                  selectedAdmin,
                );
                Navigator.of(context).pop();
              } else {
                _showErrorDialog('Please fill in all fields');
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // إرسال طلب تحديث المحطة
  Future<void> updateTerminal(String id, String terminalName, String locationCenter, String totalVehicles, String userId) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorDialog('Token is missing or invalid');
        return;
      }

      final response = await http.put(
        Uri.parse('http://$ip:3000/api/v1/terminals/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'terminal_name': terminalName,
          'location_center': locationCenter,
          'total_vehicles': totalVehicles,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        fetchTerminals(); // Reload terminals after updating
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Unknown error occurred';
        _showErrorDialog('Failed to update terminal: $errorMessage');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }
}
