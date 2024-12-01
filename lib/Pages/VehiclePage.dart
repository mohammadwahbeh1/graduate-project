import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VehiclePage extends StatefulWidget {
  const VehiclePage({Key? key}) : super(key: key);

  @override
  _VehiclePageState createState() => _VehiclePageState();
}

class _VehiclePageState extends State<VehiclePage> {
  final storage = FlutterSecureStorage();
  bool isLoading = false;
  List<dynamic> vehicles = [];
  List<dynamic> drivers = [];
  List<dynamic> lines = [];
  String? selectedDriver;
  String? selectedLine;
  String vehicleStatus = '';
  String latitude = '';
  String longitude = '';
  late TextEditingController vehicleStatusController;
  late TextEditingController latitudeController;
  late TextEditingController longitudeController;
  TextEditingController searchController = TextEditingController();
  List<dynamic> filteredVehicles = [];

  @override
  void initState() {
    super.initState();
    vehicleStatusController = TextEditingController();
    latitudeController = TextEditingController();
    longitudeController = TextEditingController();
    searchController.addListener(_filterVehicles);
    fetchVehicles();
    fetchDrivers();
    fetchLines();
  }

  @override
  void dispose() {
    vehicleStatusController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchVehicles() async {
    setState(() {
      isLoading = true;
    });
    String? token = await storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      _showErrorDialog('Token is missing or invalid');
      return;
    }

    final response = await http.get(
      Uri.parse('http://192.168.1.8:3000/api/v1/vehicle/'),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        vehicles = json.decode(response.body);
        filteredVehicles = vehicles; // Initial filtered list
      });
    } else {
      _showErrorDialog('Failed to load vehicles');
    }
    setState(() {
      isLoading = false;
    });
  }

  void _filterVehicles() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredVehicles = vehicles.where((vehicle) {
        return vehicle['vehicle_id'].toString().toLowerCase().contains(query) ||
            vehicle['driver']['username'].toLowerCase().contains(query) ||
            vehicle['line']['line_name'].toLowerCase().contains(query) ||
            vehicle['current_status'].toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> fetchDrivers() async {
    String? token = await storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('http://192.168.1.8:3000/api/v1/admin/drivers'),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        drivers = json.decode(response.body)['data'];
      });
    }
  }

  Future<void> fetchLines() async {
    String? token = await storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('http://192.168.1.8:3000/api/v1/line/term/line'),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        lines = json.decode(response.body)['data'];
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _createVehicle() async {
    String? token = await storage.read(key: 'jwt_token');

    final response = await http.post(
      Uri.parse('http://192.168.1.8:3000/api/v1/vehicle/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'driver_id': selectedDriver,
        'line_id': selectedLine,
        'current_status': vehicleStatus,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode == 201) {
      fetchVehicles();
    } else {
      _showErrorDialog('Failed to create vehicle');
    }
  }

  void _updateVehicle(String vehicleId) async {
    String? token = await storage.read(key: 'jwt_token');

    final response = await http.put(
      Uri.parse('http://192.168.1.8:3000/api/v1/vehicle/$vehicleId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'driver_id': selectedDriver,
        'line_id': selectedLine,
        'current_status': vehicleStatus,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode == 200) {
      fetchVehicles();
    } else {
      _showErrorDialog('Failed to update vehicle');
    }
  }

  void _deleteVehicle(String vehicleId) async {
    String? token = await storage.read(key: 'jwt_token');

    final response = await http.delete(
      Uri.parse('http://192.168.1.8:3000/api/v1/vehicle/$vehicleId'),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      fetchVehicles();
    } else {
      _showErrorDialog('Failed to delete vehicle');
    }
  }

  void _showEditVehicleDialog(Map vehicle) {
    setState(() {
      selectedDriver = vehicle['driver']['user_id'].toString();
      selectedLine = vehicle['line']['line_id'].toString();
      vehicleStatus = vehicle['current_status'];
      latitude = vehicle['latitude'].toString();
      longitude = vehicle['longitude'].toString();

      vehicleStatusController.text = vehicleStatus;
      latitudeController.text = latitude;
      longitudeController.text = longitude;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Vehicle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedDriver,
                hint: Text('Select Driver'),
                onChanged: (newValue) {
                  setState(() {
                    selectedDriver = newValue;
                  });
                },
                items: drivers.map<DropdownMenuItem<String>>((driver) {
                  return DropdownMenuItem<String>(
                    value: driver['user_id'].toString(),
                    child: Text(driver['username']),
                  );
                }).toList(),
              ),
              DropdownButton<String>(
                value: selectedLine,
                hint: Text('Select Line'),
                onChanged: (newValue) {
                  setState(() {
                    selectedLine = newValue;
                  });
                },
                items: lines.map<DropdownMenuItem<String>>((line) {
                  return DropdownMenuItem<String>(
                    value: line['line_id'].toString(),
                    child: Text(line['line_name']),
                  );
                }).toList(),
              ),
              TextField(
                controller: vehicleStatusController,
                onChanged: (value) {
                  setState(() {
                    vehicleStatus = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Vehicle Status',
                ),
              ),
              TextField(
                controller: latitudeController,
                onChanged: (value) {
                  setState(() {
                    latitude = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Latitude',
                ),
              ),
              TextField(
                controller: longitudeController,
                onChanged: (value) {
                  setState(() {
                    longitude = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _updateVehicle(vehicle['vehicle_id'].toString());
                Navigator.pop(context);
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Vehicle Management'),
        backgroundColor: Colors.teal,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                // Optionally focus on the search field
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search Vehicles',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(
                    vertical: 16, horizontal: 12),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: filteredVehicles.length,
              itemBuilder: (context, index) {
                var vehicle = filteredVehicles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 10,
                  shadowColor: Colors.black.withOpacity(0.3),
                  color: Colors.teal[50],
                  // Light background for the card
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Vehicle Image or Icon (for illustration)
                        Icon(
                          Icons.car_repair,
                          size: 50,
                          color: Colors.teal,
                        ),
                        SizedBox(width: 16),
                        // Vehicle Info Column
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vehicle: ${vehicle['vehicle_id']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors
                                      .teal[900], // Dark teal for the title
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Driver: ${vehicle['driver']['username']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Line: ${vehicle['line']['line_name']}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Action Buttons (Edit & Delete)
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blueAccent),
                              onPressed: () {
                                _showEditVehicleDialog(vehicle);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                _deleteVehicle(
                                    vehicle['vehicle_id'].toString());
                              },
                            ),
                          ],
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
        onPressed: () {
          // Show dialog to create vehicle with form fields
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Create Vehicle'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButton<String>(
                        value: selectedDriver,
                        hint: Text('Select Driver'),
                        onChanged: (newValue) {
                          setState(() {
                            selectedDriver = newValue;
                          });
                        },
                        items: drivers.map<DropdownMenuItem<String>>((driver) {
                          return DropdownMenuItem<String>(
                            value: driver['user_id'].toString(),
                            child: Text(driver['username']),
                          );
                        }).toList(),
                      ),
                      DropdownButton<String>(
                        value: selectedLine,
                        hint: Text('Select Line'),
                        onChanged: (newValue) {
                          setState(() {
                            selectedLine = newValue;
                          });
                        },
                        items: lines.map<DropdownMenuItem<String>>((line) {
                          return DropdownMenuItem<String>(
                            value: line['line_id'].toString(),
                            child: Text(line['line_name']),
                          );
                        }).toList(),
                      ),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            vehicleStatus = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Vehicle Status',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                        ),
                      ),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            latitude = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Latitude',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                        ),
                      ),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            longitude = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Longitude',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      _createVehicle();
                      Navigator.pop(context);
                    },
                    child: Text('Create'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}