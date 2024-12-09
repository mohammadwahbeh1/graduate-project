import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class VehiclePage extends StatefulWidget {
  const VehiclePage({Key? key}) : super(key: key);

  @override
  _VehiclePageState createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  final storage = FlutterSecureStorage();
  List<dynamic> vehicles = [];
  List<dynamic> filteredVehicles = [];
  List<dynamic> drivers = [];
  List<dynamic> lines = [];
  bool isLoading = false;
  String? selectedDriver;
  String? selectedLine;
  String? selectedStatus;
  String latitude = '';
  String longitude = '';
  TextEditingController latitudeController = TextEditingController();
  TextEditingController longitudeController = TextEditingController();
  TextEditingController searchController = TextEditingController();

  // Primary and Secondary Colors for consistency
  final Color primaryColor = Color(0xFF00B4DB);
  final Color secondaryColor = Color(0xFF0083B0);

  @override
  void initState() {
    super.initState();
    fetchVehicles();
    fetchDrivers();
    fetchLines();
    searchController.addListener(_filterVehicles);
  }

  @override
  void dispose() {
    latitudeController.dispose();
    longitudeController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // Fetch Vehicles
  Future<void> fetchVehicles() async {
    setState(() {
      isLoading = true;
    });
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Token is missing or invalid');
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.1.8:3000/api/v1/vehicle/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          vehicles = data;
          filteredVehicles = data;
        });
      } else {
        _showErrorSnackbar('Failed to load vehicles');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fetch Drivers
  Future<void> fetchDrivers() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Token is missing or invalid');
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.1.8:3000/api/v1/admin/drivers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          drivers = data;
        });
      } else {
        _showErrorSnackbar('Failed to fetch drivers');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: $e');
    }
  }

  // Fetch Lines
  Future<void> fetchLines() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Token is missing or invalid');
        return;
      }

      final response = await http.get(
        Uri.parse('http://192.168.1.8:3000/api/v1/line/term/line'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        setState(() {
          lines = data;
        });
      } else {
        _showErrorSnackbar('Failed to fetch lines');
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: $e');
    }
  }

  // Filter Vehicles based on search input
  void _filterVehicles() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredVehicles = vehicles.where((vehicle) {
        return vehicle['vehicle_id'].toString().toLowerCase().contains(query) ||
            vehicle['driver']['username'].toLowerCase().contains(query) ||
            vehicle['line']['line_name'].toLowerCase().contains(query) ||
            (vehicle['current_status'] != null &&
                vehicle['current_status'].toLowerCase().contains(query));
      }).toList();
    });
  }

  // Show Error Snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Show Success Snackbar
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Create Vehicle
  Future<void> _createVehicle() async {
    if (selectedDriver == null ||
        selectedLine == null ||
        selectedStatus == null ||
        latitude.isEmpty ||
        longitude.isEmpty) {
      _showErrorSnackbar('Please fill in all fields');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Token is missing or invalid');
        return;
      }

      final response = await http.post(
        Uri.parse('http://192.168.1.8:3000/api/v1/vehicle/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'driver_id': selectedDriver,
          'line_id': selectedLine,
          'current_status': selectedStatus,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 201) {
        _showSuccessSnackbar('Vehicle created successfully');
        fetchVehicles();
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Failed to create vehicle';
        _showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update Vehicle
  Future<void> _updateVehicle(String vehicleId) async {
    if (selectedDriver == null ||
        selectedLine == null ||
        selectedStatus == null ||
        latitude.isEmpty ||
        longitude.isEmpty) {
      _showErrorSnackbar('Please fill in all fields');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Token is missing or invalid');
        return;
      }

      final response = await http.put(
        Uri.parse('http://192.168.1.8:3000/api/v1/vehicle/$vehicleId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'driver_id': selectedDriver,
          'line_id': selectedLine,
          'current_status': selectedStatus,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        _showSuccessSnackbar('Vehicle updated successfully');
        fetchVehicles();
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Failed to update vehicle';
        _showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Delete Vehicle
  Future<void> _deleteVehicle(String vehicleId) async {
    setState(() {
      isLoading = true;
    });

    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Token is missing or invalid');
        return;
      }

      final response = await http.delete(
        Uri.parse('http://192.168.1.8:3000/api/v1/vehicle/$vehicleId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSuccessSnackbar('Vehicle deleted successfully');
        fetchVehicles();
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Failed to delete vehicle';
        _showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Show Add/Edit Vehicle Dialog
  void _showVehicleDialog({Map? vehicle}) {
    bool isEdit = vehicle != null;
    if (isEdit) {
      selectedDriver = vehicle['driver']['user_id'].toString();
      selectedLine = vehicle['line']['line_id'].toString();
      selectedStatus = vehicle['current_status'];
      latitude = vehicle['latitude'].toString();
      longitude = vehicle['longitude'].toString();

      latitudeController.text = latitude;
      longitudeController.text = longitude;
    } else {
      selectedDriver = null;
      selectedLine = null;
      selectedStatus = null;
      latitudeController.clear();
      longitudeController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Vehicle' : 'Create Vehicle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Select Driver
                DropdownButtonFormField<String>(
                  value: selectedDriver,
                  decoration: InputDecoration(
                    labelText: 'Select Driver',
                    border: OutlineInputBorder(),
                  ),
                  items: drivers.map((driver) {
                    return DropdownMenuItem<String>(
                      value: driver['user_id'].toString(),
                      child: Text(driver['username']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDriver = value;
                    });
                  },
                  validator: (value) =>
                  value == null ? 'Please select a driver' : null,
                ),
                SizedBox(height: 15),
                // Select Line
                DropdownButtonFormField<String>(
                  value: selectedLine,
                  decoration: InputDecoration(
                    labelText: 'Select Line',
                    border: OutlineInputBorder(),
                  ),
                  items: lines.map((line) {
                    return DropdownMenuItem<String>(
                      value: line['line_id'].toString(),
                      child: Text(line['line_name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedLine = value;
                    });
                  },
                  validator: (value) =>
                  value == null ? 'Please select a line' : null,
                ),
                SizedBox(height: 15),
                // Current Status (Dropdown)
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Current Status',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'on_the_way',
                      child: Text('On The Way'),
                    ),
                    DropdownMenuItem(
                      value: 'in_terminal',
                      child: Text('In Terminal'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value;
                    });
                  },
                  validator: (value) =>
                  value == null ? 'Please select a status' : null,
                ),
                SizedBox(height: 15),
                // Latitude
                TextField(
                  controller: latitudeController,
                  decoration: InputDecoration(
                    labelText: 'Latitude',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    latitude = value;
                  },
                ),
                SizedBox(height: 15),
                // Longitude
                TextField(
                  controller: longitudeController,
                  decoration: InputDecoration(
                    labelText: 'Longitude',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    longitude = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () {
                if (isEdit) {
                  _updateVehicle(vehicle!['vehicle_id'].toString());
                } else {
                  _createVehicle();
                }
                Navigator.of(context).pop();
              },
              child: Text(isEdit ? 'Update' : 'Create'),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
              ),
            ),
          ],
        );
      },
    );
  }

  // Confirm Delete Vehicle
  void _confirmDeleteVehicle(String vehicleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Deletion',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete this vehicle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
            Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteVehicle(vehicleId);
              Navigator.of(context).pop();
            },
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  // Build Vehicle Card with enhanced design
  Widget _buildVehicleCard(Map vehicle) {
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
              Colors.teal.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            // Vehicle Icon
            CircleAvatar(
              radius: 30,
              backgroundColor: primaryColor,
              child: Icon(
                Icons.directions_car,
                size: 30,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 20),
            // Vehicle Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle ID: ${vehicle['vehicle_id']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: secondaryColor,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Driver: ${vehicle['driver']['username']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Line: ${vehicle['line']['line_name']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Status: ${vehicle['current_status'] != null ? _formatStatus(vehicle['current_status']) : 'N/A'}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
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
                  icon: Icon(Icons.edit, color: Colors.orangeAccent),
                  onPressed: () => _showVehicleDialog(vehicle: vehicle),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () =>
                      _confirmDeleteVehicle(vehicle['vehicle_id'].toString()),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper to format status text
  String _formatStatus(String status) {
    switch (status) {
      case 'on_the_way':
        return 'On The Way';
      case 'in_terminal':
        return 'In Terminal';
      default:
        return status;
    }
  }

  // Build Vehicle List with responsive layout
  Widget _buildVehicleList(bool isWeb) {
    if (filteredVehicles.isEmpty) {
      return Center(
        child: Text(
          'No vehicles available.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    if (isWeb) {
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Adjust as needed
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 3,
        ),
        itemCount: filteredVehicles.length,
        itemBuilder: (context, index) {
          return _buildVehicleCard(filteredVehicles[index]);
        },
      );
    } else {
      return ListView.builder(
        itemCount: filteredVehicles.length,
        itemBuilder: (context, index) {
          return _buildVehicleCard(filteredVehicles[index]);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar with Gradient
      appBar: AppBar(
        title: Text('Vehicle Management'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWeb = constraints.maxWidth > 800;

          return isLoading
              ? Center(
            child: CircularProgressIndicator(
              valueColor:
              AlwaysStoppedAnimation<Color>(secondaryColor),
            ),
          )
              : Padding(
            padding: isWeb
                ? const EdgeInsets.symmetric(
                horizontal: 32.0, vertical: 24.0)
                : const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText:
                      'Search by ID, Driver, Line, or Status',
                      prefixIcon: Icon(Icons.search,
                          color: secondaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 0, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                        BorderSide(color: secondaryColor),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // Vehicle List
                Expanded(child: _buildVehicleList(isWeb)),
              ],
            ),
          );
        },
      ),
      // Floating Action Button to Add Vehicle
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showVehicleDialog(),
        backgroundColor: secondaryColor,
        tooltip: 'Add Vehicle',
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
