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
        _showErrorSnackbar('Authentication token is missing or invalid.');
        return;
      }

      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/terminals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          terminals = data;
          filteredTerminals = data;
        });
      } else {
        _showErrorSnackbar('Failed to fetch terminal data.');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch Admins
  Future<void> fetchAdmins() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Authentication token is missing or invalid.');
        return;
      }

      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/admin/admin'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          admins = data;
        });
      } else {
        _showErrorSnackbar('Failed to fetch admin data.');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: $e');
    }
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

  // Filter Terminals based on search input
  void _filterTerminals() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredTerminals = terminals.where((terminal) {
        bool matchesQuery = terminal['terminal_name'].toLowerCase().contains(query);
        return matchesQuery;
      }).toList();
    });
  }

  // Create new terminal
  Future<void> createTerminal(String terminalName, String locationCenter,
      String totalVehicles, String userId) async {
    setState(() {
      isLoading = true;
    });
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Authentication token is missing or invalid.');
        return;
      }

      final response = await http.post(
        Uri.parse('http://$ip:3000/api/v1/terminals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'terminal_name': terminalName,
          'location_center': locationCenter,
          'total_vehicles': totalVehicles,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        _showSuccessSnackbar('Terminal created successfully.');
        fetchTerminals(); // Reload terminals after creating
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'An unknown error occurred.';
        _showErrorSnackbar('Failed to create terminal: $errorMessage');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Show Add Terminal Dialog
  void _showAddTerminalDialog() {
    final terminalNameController = TextEditingController();
    final locationCenterController = TextEditingController();
    final totalVehiclesController = TextEditingController();
    String? selectedAdminId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Terminal',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Terminal Name
              TextField(
                controller: terminalNameController,
                decoration: const InputDecoration(
                  labelText: 'Terminal Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              // Location Center
              TextField(
                controller: locationCenterController,
                decoration: const InputDecoration(
                  labelText: 'Location Center',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              // Total Vehicles
              TextField(
                controller: totalVehiclesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Vehicles',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              // Select Admin
              DropdownButtonFormField<String>(
                value: selectedAdminId,
                items: admins.map((admin) {
                  return DropdownMenuItem(
                    value: admin['user_id'].toString(),
                    child: Text(admin['username']),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedAdminId = value;
                },
                decoration:
                const InputDecoration(labelText: 'Select Admin'),
                validator: (value) =>
                value == null ? 'Please select an admin' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
            const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (terminalNameController.text.isNotEmpty &&
                  locationCenterController.text.isNotEmpty &&
                  totalVehiclesController.text.isNotEmpty &&
                  selectedAdminId != null) {
                createTerminal(
                  terminalNameController.text,
                  locationCenterController.text,
                  totalVehiclesController.text,
                  selectedAdminId!,
                );
                Navigator.of(context).pop();
              } else {
                _showErrorSnackbar('Please fill in all fields.');
              }
            },
            child: const Text('Add'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
    );
  }

  // Delete Terminal
  Future<void> deleteTerminal(String id) async {
    setState(() {
      isLoading = true;
    });
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Authentication token is missing or invalid.');
        return;
      }

      final response = await http.delete(
        Uri.parse('http://$ip:3000/api/v1/terminals/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSuccessSnackbar('Terminal deleted successfully.');
        fetchTerminals(); // Reload terminals after deleting
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'An unknown error occurred.';
        _showErrorSnackbar('Failed to delete terminal: $errorMessage');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _confirmDeleteTerminal(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content:
        const Text('Are you sure you want to delete this terminal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
            const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              deleteTerminal(id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // Update Terminal
  Future<void> updateTerminal(String id, String terminalName,
      String locationCenter, String totalVehicles, String userId) async {
    setState(() {
      isLoading = true;
    });
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Authentication token is missing or invalid.');
        return;
      }

      final response = await http.put(
        Uri.parse('http://$ip:3000/api/v1/terminals/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
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
        _showSuccessSnackbar('Terminal updated successfully.');
        fetchTerminals(); // Reload terminals after updating
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'An unknown error occurred.';
        _showErrorSnackbar('Failed to update terminal: $errorMessage');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Show Edit Terminal Dialog
  void _showEditTerminalDialog(dynamic terminal) {
    final terminalNameController =
    TextEditingController(text: terminal['terminal_name']);
    final locationCenterController =
    TextEditingController(text: terminal['location_center'] ?? '');
    final totalVehiclesController =
    TextEditingController(text: terminal['total_vehicles'].toString());
    String? selectedAdminId = terminal['user_id']?.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Terminal',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Terminal Name
              TextField(
                controller: terminalNameController,
                decoration: const InputDecoration(
                  labelText: 'Terminal Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              // Location Center
              TextField(
                controller: locationCenterController,
                decoration: const InputDecoration(
                  labelText: 'Location Center',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              // Total Vehicles
              TextField(
                controller: totalVehiclesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Vehicles',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),
              // Select Admin
              DropdownButtonFormField<String>(
                value: selectedAdminId,
                items: admins.map((admin) {
                  return DropdownMenuItem(
                    value: admin['user_id'].toString(),
                    child: Text(admin['username']),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedAdminId = value;
                },
                decoration:
                const InputDecoration(labelText: 'Select Admin'),
                validator: (value) =>
                value == null ? 'Please select an admin' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
            const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (terminalNameController.text.isNotEmpty &&
                  locationCenterController.text.isNotEmpty &&
                  totalVehiclesController.text.isNotEmpty &&
                  selectedAdminId != null) {
                updateTerminal(
                  terminal['terminal_id'].toString(),
                  terminalNameController.text,
                  locationCenterController.text,
                  totalVehiclesController.text,
                  selectedAdminId!,
                );
                Navigator.of(context).pop();
              } else {
                _showErrorSnackbar('Please fill in all fields.');
              }
            },
            child: const Text('Update'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFFFFF),
            ),
          ),
        ],
      ),
    );
  }

  // Build Terminal List Item with improved styling
  Widget _buildTerminalCard(dynamic terminal) {
    String adminName = 'Not Available';
    try {
      var admin = admins.firstWhere(
              (admin) => admin['user_id'].toString() == terminal['user_id'].toString(),
          orElse: () => {'username': 'N/A'});
      adminName = admin['username'];
    } catch (e) {
      adminName = 'N/A';
    }

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
            // Terminal Icon
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF00B4DB),
              child: const Icon(
                Icons.location_on,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            // Terminal Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    terminal['terminal_name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF0083B0),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Location: ${terminal['location_center'] ?? 'Not Available'}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Total Vehicles: ${terminal['total_vehicles']}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Admin: $adminName',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showEditTerminalDialog(terminal),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteTerminal(
                      terminal['terminal_id'].toString()),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build Terminal List with responsive layout
  Widget _buildTerminalList(bool isWeb) {
    if (filteredTerminals.isEmpty) {
      return Center(
        child: Text(
          'No terminals available.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    if (isWeb) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 3,
        ),
        itemCount: filteredTerminals.length,
        itemBuilder: (context, index) {
          return _buildTerminalCard(filteredTerminals[index]);
        },
      );
    } else {
      return ListView.builder(
        itemCount: filteredTerminals.length,
        itemBuilder: (context, index) {
          return _buildTerminalCard(filteredTerminals[index]);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Updated AppBar with gradient colors
      appBar: AppBar(
        title: const Text('Terminals'),
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
                // Search Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by terminal name or admin',
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
                      // Removed the admin filter dropdown as per request
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Terminal List
                Expanded(child: _buildTerminalList(isWeb)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTerminalDialog,
        backgroundColor: const Color(0xFF0083B0),
        tooltip: 'Add Terminal',
        child: const Icon(Icons.add , color: Color(0xFFFFFFFF),),
      ),
    );
  }
}
