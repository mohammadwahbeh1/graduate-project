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
  List<dynamic> filteredTerminals = [];
  List<dynamic> admins = [];
  String ip = '192.168.1.8';
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchTerminals();
    fetchAdmins();
    searchController.addListener(_filterTerminals);
  }

  // Fetch Terminals
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
          filteredTerminals = data;
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

  // Filter Terminals based on search input
  void _filterTerminals() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredTerminals = terminals
          .where((terminal) =>
          terminal['terminal_name'].toLowerCase().contains(query))
          .toList();
    });
  }

  // Fetch Admins
  Future<void> fetchAdmins() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorDialog('Token is missing or invalid');
        return;
      }

      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/admin/admin'),
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

  // Show error dialog
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

  // Create new terminal
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

      fetchTerminals(); // Reload terminals after creating
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }

  // Show Add Terminal Dialog
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
              value: selectedAdmin != null ? selectedAdmin.toString() : null, // تأكد من أنها String
              items: admins.map((admin) {
                return DropdownMenuItem(
                  value: admin['user_id'].toString(), // تحويل القيمة إلى String
                  child: Text(admin['username']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAdmin = value.toString(); // تحويل إلى String هنا أيضًا
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
                  '', // Set location_center as needed
                  totalVehiclesController.text,
                  selectedAdmin, // تحويل إلى String
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
  Future<void> deleteTerminal(String id) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorDialog('Token is missing or invalid');
        return;
      }

      final response = await http.delete(
        Uri.parse('http://$ip:3000/api/v1/terminals/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        fetchTerminals(); // Reload terminals after deleting
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Unknown error occurred';
        _showErrorDialog('Failed to delete terminal: $errorMessage');
      }
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _confirmDeleteTerminal(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete this terminal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              deleteTerminal(id);
              Navigator.of(context).pop();
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terminals'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Terminals',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Expanded(
            child: ListView.builder(
              itemCount: filteredTerminals.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Text(filteredTerminals[index]['terminal_name']),
                    subtitle: Text('Total Vehicles: ${filteredTerminals[index]['total_vehicles']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _showEditTerminalDialog(filteredTerminals[index]),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteTerminal(filteredTerminals[index]['terminal_id'].toString()),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTerminalDialog,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

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

  // Edit Terminal Dialog
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
              value: selectedAdmin != null ? selectedAdmin.toString() : null, // تأكد من أنها String
              items: admins.map((admin) {
                return DropdownMenuItem(
                  value: admin['user_id'].toString(), // تحويل القيمة إلى String
                  child: Text(admin['username']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAdmin = value.toString(); // تحويل إلى String هنا أيضًا
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
                  terminal['terminal_id'].toString(), // تحويل إلى String
                  terminalNameController.text,
                  '', // Set location_center as needed
                  totalVehiclesController.text,
                  selectedAdmin.toString(), // تحويل إلى String
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
}

