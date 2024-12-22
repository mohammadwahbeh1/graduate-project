import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
const String ip = "192.168.1.5";


class VehiclePage extends StatefulWidget {
  const VehiclePage({Key? key}) : super(key: key);

  @override
  _VehiclePageState createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  final storage = const FlutterSecureStorage();
  List<dynamic> vehicles = [];
  List<dynamic> filteredVehicles = [];
  List<dynamic> drivers = [];
  List<dynamic> lines = [];
  bool isLoading = false;
  String? selectedDriver;
  String? selectedLine;
  String? selectedStatus;
  double? latitude;
  double? longitude;
  final TextEditingController searchController = TextEditingController();

  // Primary and Secondary Colors for consistency
  static const Color primaryColor = Color(0xFF00B4DB);
  static const Color secondaryColor = Color(0xFF0083B0);

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
        Uri.parse('http://$ip:3000/api/v1/vehicle/'),
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
        Uri.parse('http://$ip:3000/api/v1/admin/drivers'),
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
        Uri.parse('http://$ip:3000/api/v1/line/term/line'),
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

  // Show Error Snackbar
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
              color: Colors.white,
            )),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Show Success Snackbar
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
              color: Colors.white,
            )),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Filter Vehicles based on search input
  void _filterVehicles() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredVehicles = vehicles.where((vehicle) {
        return vehicle['vehicle_id']
            .toString()
            .toLowerCase()
            .contains(query) ||
            vehicle['driver']['username']
                .toString()
                .toLowerCase()
                .contains(query) ||
            vehicle['line']['line_name']
                .toString()
                .toLowerCase()
                .contains(query) ||
            (vehicle['current_status'] != null &&
                vehicle['current_status']
                    .toString()
                    .toLowerCase()
                    .contains(query));
      }).toList();
    });
  }

  // Create Vehicle
  Future<void> _createVehicle() async {
    if (selectedDriver == null ||
        selectedLine == null ||
        selectedStatus == null ||
        latitude == null ||
        longitude == null) {
      _showErrorSnackbar('Please fill in all fields and select a location');
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
        Uri.parse('http://$ip:3000/api/v1/vehicle/'),
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
        latitude == null ||
        longitude == null) {
      _showErrorSnackbar('Please fill in all fields and select a location');
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
        Uri.parse('http://$ip:3000/api/v1/vehicle/$vehicleId'),
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
        Uri.parse('http://$ip:3000/api/v1/vehicle/$vehicleId'),
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
      latitude = double.tryParse(vehicle['latitude'].toString());
      longitude = double.tryParse(vehicle['longitude'].toString());
    } else {
      selectedDriver = null;
      selectedLine = null;
      selectedStatus = null;
      latitude = null;
      longitude = null;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit Vehicle' : 'Create Vehicle',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Select Driver
                    DropdownButtonFormField<String>(
                      value: selectedDriver,
                      decoration: const InputDecoration(
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
                        setStateDialog(() {
                          selectedDriver = value;
                        });
                      },
                      validator: (value) =>
                      value == null ? 'Please select a driver' : null,
                    ),
                    const SizedBox(height: 15),
                    // Select Line
                    DropdownButtonFormField<String>(
                      value: selectedLine,
                      decoration: const InputDecoration(
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
                        setStateDialog(() {
                          selectedLine = value;
                        });
                      },
                      validator: (value) =>
                      value == null ? 'Please select a line' : null,
                    ),
                    const SizedBox(height: 15),
                    // Current Status (Dropdown)
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Current Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
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
                        setStateDialog(() {
                          selectedStatus = value;
                        });
                      },
                      validator: (value) =>
                      value == null ? 'Please select a status' : null,
                    ),
                    const SizedBox(height: 15),
                    // Latitude and Longitude Display (Read-Only)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        (latitude == null || longitude == null)
                            ? 'Location: Not Selected'
                            : 'Location: $latitude, $longitude',
                        style:
                        TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Button to Select Location from Map
                    ElevatedButton.icon(
                      onPressed: () async {
                        // Open Map Selection Dialog
                        LatLng? selectedLatLng = await showDialog<LatLng>(
                          context: context,
                          builder: (context) => _MapSelectionDialog(
                            initialLocation: (latitude != null &&
                                longitude != null)
                                ? LatLng(latitude!, longitude!)
                                : null,
                          ),
                        );

                        if (selectedLatLng != null) {
                          setStateDialog(() {
                            latitude = selectedLatLng.latitude;
                            longitude = selectedLatLng.longitude;
                          });
                        }
                      },
                      icon: const Icon(Icons.location_on, color: Colors.white),
                      label: const Text('Select Location from Map',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: secondaryColor,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
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
                    if (isEdit) {
                      _updateVehicle(vehicle!['vehicle_id'].toString());
                    } else {
                      _createVehicle();
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(isEdit ? 'Update' : 'Create',
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: secondaryColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Confirm Delete Vehicle
  void _confirmDeleteVehicle(String vehicleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this vehicle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child:
            const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteVehicle(vehicleId);
              Navigator.of(context).pop();
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
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
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Vehicle Icon
            const CircleAvatar(
              radius: 30,
              backgroundColor: primaryColor,
              child: Icon(
                Icons.location_on,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            // Vehicle Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vehicle ID: ${vehicle['vehicle_id']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: secondaryColor,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Driver: ${vehicle['driver']['username']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Line: ${vehicle['line']['line_name']}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 5),
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
                // Button to View Location
                IconButton(
                  icon: const Icon(Icons.location_on, color: Colors.blueAccent),
                  onPressed: () {
                    // Show Vehicle Location on Map within a dialog
                    showDialog(
                      context: context,
                      builder: (context) => _VehicleLocationDialog(
                        vehicleId: vehicle['vehicle_id'].toString(),
                        latitude: double.parse(vehicle['latitude'].toString()),
                        longitude: double.parse(vehicle['longitude'].toString()),
                      ),
                    );
                  },
                  tooltip: 'View Location',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                  onPressed: () => _showVehicleDialog(vehicle: vehicle),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
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
      return const Center(
        child: Text(
          'No vehicles available.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      );
    }

    if (isWeb) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        title: const Text('Vehicle Management'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
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
          bool isWeb = constraints.maxWidth > 800;

          return isLoading
              ? Center(
            child: CircularProgressIndicator(
              valueColor:
              const AlwaysStoppedAnimation<Color>(secondaryColor),
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
                      prefixIcon:
                      Icon(Icons.search, color: secondaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
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
                const SizedBox(height: 16),
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
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Dialog for Selecting Location on Map
class _MapSelectionDialog extends StatefulWidget {
  final LatLng? initialLocation;

  const _MapSelectionDialog({Key? key, this.initialLocation}) : super(key: key);

  @override
  __MapSelectionDialogState createState() => __MapSelectionDialogState();
}

class __MapSelectionDialogState extends State<_MapSelectionDialog> {
  LatLng? _selectedLocation;
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ??
        const LatLng(37.7749, -122.4194); // Default to San Francisco
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
  }

  void _onConfirm() {
    if (_selectedLocation != null) {
      Navigator.of(context).pop(_selectedLocation);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a location on the map',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Vehicle Location',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _selectedLocation!,
            zoom: 14,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onTap: _onMapTapped,
          markers: _selectedLocation != null
              ? {
            Marker(
              markerId: const MarkerId('selected-location'),
              position: _selectedLocation!,
            ),
          }
              : {},
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:
          const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          child: const Text('Confirm',
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }
}

// Dialog for Viewing Vehicle Location on Map
class _VehicleLocationDialog extends StatelessWidget {
  final String vehicleId;
  final double latitude;
  final double longitude;

  const _VehicleLocationDialog({
    Key? key,
    required this.vehicleId,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    LatLng vehicleLocation = LatLng(latitude, longitude);

    return AlertDialog(
      title: Text('Vehicle Location: $vehicleId',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: vehicleLocation,
            zoom: 14,
          ),
          markers: {
            Marker(
              markerId: MarkerId(vehicleId),
              position: vehicleLocation,
              infoWindow: InfoWindow(title: 'Vehicle ID: $vehicleId'),
            ),
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child:
          const Text('Close', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
