import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';

class TerminalPage extends StatefulWidget {
  @override
  _TerminalPageState createState() => _TerminalPageState();
}

class _TerminalPageState extends State<TerminalPage> {
  final storage = const FlutterSecureStorage();
  List<dynamic> terminals = [];
  List<dynamic> filteredTerminals = [];
  List<dynamic> admins = [];
  String ip = "192.168.1.4";
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();

  Future<void> _fetchIpAddress() async {
    final info = NetworkInfo();
    String? wifiIP = await info.getWifiIP(); // الحصول على عنوان الـ IP الخاص بالواي فاي
    setState(() {
      ip = wifiIP ?? 'غير متصل بالشبكة';
    });
  }

  // Primary and Secondary Colors for consistency
  final Color primaryColor = const Color(0xFF00B4DB);
  final Color secondaryColor = const Color(0xFF0083B0);

  @override
  void initState() {
    super.initState();
    fetchTerminals();
    fetchAdmins();
    searchController.addListener(_filterTerminals);
    _fetchIpAddress(); // استدعاء الدالة للحصول على الـ IP عند بدء الصفحة
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
        Uri.parse('http://$ip:3000/api/v1/admin/terminals'), // Updated endpoint
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
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  // Show success snackbar
  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Filter Terminals based on search input
  void _filterTerminals() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredTerminals = terminals.where((terminal) {
        bool matchesName =
        terminal['terminal_name'].toString().toLowerCase().contains(query);

        // Fetch admin name for filtering
        String adminName = 'N/A';
        try {
          var admin = admins.firstWhere(
                  (admin) => admin['user_id'].toString() == terminal['user_id'].toString(),
              orElse: () => {'username': 'N/A'});
          adminName = admin['username'].toString().toLowerCase();
        } catch (_) {
          adminName = 'N/A';
        }

        bool matchesAdmin = adminName.contains(query);
        return matchesName || matchesAdmin;
      }).toList();
    });
  }

  // Create new terminal (send latitude and longitude separately)
  Future<void> createTerminal(
      String terminalName, double? latitude, double? longitude, String totalVehicles, String userId) async {
    setState(() {
      isLoading = true;
    });
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Authentication token is missing or invalid.');
        return;
      }

      final requestBody = {
        'terminal_name': terminalName,
        'total_vehicles': totalVehicles,
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
      };

      final response = await http.post(
        Uri.parse('http://$ip:3000/api/v1/terminals'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
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

  // Update Terminal (send latitude and longitude separately)
  Future<void> updateTerminal(String id, String terminalName, double? latitude,
      double? longitude, String totalVehicles, String userId) async {
    setState(() {
      isLoading = true;
    });
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Authentication token is missing or invalid.');
        return;
      }

      final requestBody = {
        'terminal_name': terminalName,
        'total_vehicles': totalVehicles,
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
      };

      final response = await http.put(
        Uri.parse('http://$ip:3000/api/v1/terminals/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
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

  // Confirm Delete Terminal
  void _confirmDeleteTerminal(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this terminal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              deleteTerminal(id);
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white, // Ensure text is white
            ),
          ),
        ],
      ),
    );
  }

  // Show Add Terminal Dialog
  void _showAddTerminalDialog() {
    final terminalNameController = TextEditingController();
    final totalVehiclesController = TextEditingController();
    String? selectedAdminId;
    double? selectedLatitude;
    double? selectedLongitude;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Terminal', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
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
                      return DropdownMenuItem<String>(
                        value: admin['user_id'].toString(),
                        child: Text(admin['username']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedAdminId = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Select Admin'),
                    validator: (value) => value == null ? 'Please select an admin' : null,
                  ),
                  const SizedBox(height: 15),
                  // Show chosen coordinates or not
                  Text(
                    (selectedLatitude == null || selectedLongitude == null)
                        ? 'Location: Not Selected'
                        : 'Location: $selectedLatitude, $selectedLongitude',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 15),
                  // Button to Select Location from Map
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Open Map Selection Dialog
                      LatLng? selectedLatLng = await showDialog<LatLng>(
                        context: context,
                        builder: (context) => _MapSelectionDialog(
                          initialLocation: selectedLatitude != null && selectedLongitude != null
                              ? LatLng(selectedLatitude!, selectedLongitude!)
                              : null,
                        ),
                      );

                      if (selectedLatLng != null) {
                        setStateDialog(() {
                          selectedLatitude = selectedLatLng.latitude;
                          selectedLongitude = selectedLatLng.longitude;
                        });
                      }
                    },
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    label: const Text('Select Location from Map',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (terminalNameController.text.isNotEmpty &&
                  totalVehiclesController.text.isNotEmpty &&
                  selectedAdminId != null) {
                createTerminal(
                  terminalNameController.text,
                  selectedLatitude,
                  selectedLongitude,
                  totalVehiclesController.text,
                  selectedAdminId!,
                );
                Navigator.of(context).pop();
              } else {
                _showErrorSnackbar('Please fill in all required fields.');
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show Edit Terminal Dialog
  void _showEditTerminalDialog(dynamic terminal) {
    final terminalNameController = TextEditingController(text: terminal['terminal_name'].toString());
    final totalVehiclesController = TextEditingController(text: terminal['total_vehicles'].toString());
    String? selectedAdminId = terminal['user_id']?.toString();

    double? selectedLatitude = terminal['latitude'] == null ? null : (terminal['latitude'] as num?)?.toDouble();
    double? selectedLongitude = terminal['longitude'] == null ? null : (terminal['longitude'] as num?)?.toDouble();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Terminal', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
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
                      return DropdownMenuItem<String>(
                        value: admin['user_id'].toString(),
                        child: Text(admin['username']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedAdminId = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Select Admin'),
                    validator: (value) => value == null ? 'Please select an admin' : null,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    (selectedLatitude == null || selectedLongitude == null)
                        ? 'Location: Not Available'
                        : (selectedLatitude == 0 && selectedLongitude == 0)
                        ? 'Location: Not Available'
                        : 'Location: $selectedLatitude, $selectedLongitude',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 15),
                  // Button to Select Location from Map
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Open Map Selection Dialog
                      LatLng? selectedLatLng = await showDialog<LatLng>(
                        context: context,
                        builder: (context) => _MapSelectionDialog(
                          initialLocation: (selectedLatitude != null && selectedLongitude != null)
                              ? LatLng(selectedLatitude!.toDouble(), selectedLongitude!.toDouble())
                              : null,
                        ),
                      );

                      if (selectedLatLng != null) {
                        setStateDialog(() {
                          selectedLatitude = selectedLatLng.latitude;
                          selectedLongitude = selectedLatLng.longitude;
                        });
                      }
                    },
                    icon: const Icon(Icons.location_on, color: Colors.white),
                    label: const Text('Select Location from Map',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (terminalNameController.text.isNotEmpty &&
                  totalVehiclesController.text.isNotEmpty &&
                  selectedAdminId != null) {
                updateTerminal(
                  terminal['terminal_id'].toString(),
                  terminalNameController.text,
                  selectedLatitude,
                  selectedLongitude,
                  totalVehiclesController.text,
                  selectedAdminId!,
                );
                Navigator.of(context).pop();
              } else {
                _showErrorSnackbar('Please fill in all required fields.');
              }
            },
            child: const Text('Update', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build Terminal Card with enhanced design
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

    double? latitude = terminal['latitude'] == null ? null : (terminal['latitude'] as num?)?.toDouble();
    double? longitude = terminal['longitude'] == null ? null : (terminal['longitude'] as num?)?.toDouble();

    // Determine location display
    String locationDisplay;
    if (latitude == null || longitude == null || (latitude == 0 && longitude == 0)) {
      locationDisplay = 'Not Available';
    } else {
      locationDisplay = '$latitude, $longitude';
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
              backgroundColor: primaryColor,
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
                    terminal['terminal_name'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF0083B0),
                    ),
                  ),

                  const SizedBox(height: 5),
                  Text(
                    'Total Vehicles: ${terminal['vehicleCount']}', // Updated field
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
                // Button to View Location
                IconButton(
                  icon: const Icon(Icons.location_on, color: Colors.blueAccent),
                  onPressed: (latitude == null || longitude == null || (latitude == 0 && longitude == 0))
                      ? null // Disable if no location
                      : () {
                    // Show Terminal Location on Map within a dialog
                    showDialog(
                      context: context,
                      builder: (context) => _TerminalLocationDialog(
                        terminalId: terminal['terminal_id'].toString(),
                        latitude: latitude,
                        longitude: longitude,
                      ),
                    );
                  },
                  tooltip: 'View Location',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                  onPressed: () => _showEditTerminalDialog(terminal),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () => _confirmDeleteTerminal(terminal['terminal_id'].toString()),
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
          bool isWeb = constraints.maxWidth > 800; // Determines if screen size is for web

          return isLoading
              ? Center(
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B4DB)),
            ),
          )
              : Padding(
            padding: isWeb
                ? const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0)
                : const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by terminal name or admin',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF0083B0)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
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
        backgroundColor: secondaryColor,
        tooltip: 'Add Terminal',
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
    _selectedLocation = widget.initialLocation ?? const LatLng(32.2077, 35.2813); // Default to specified location
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
      title: const Text('Select Terminal Location'),
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
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }
}

// Dialog for Viewing Terminal Location on Map
class _TerminalLocationDialog extends StatelessWidget {
  final String terminalId;
  final double? latitude;
  final double? longitude;

  const _TerminalLocationDialog({
    Key? key,
    required this.terminalId,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Since this dialog is only opened if we have valid coordinates, no need to check null here
    LatLng terminalLocation = LatLng(latitude!, longitude!);

    return AlertDialog(
      title: Text('Terminal Location: $terminalId'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: terminalLocation,
            zoom: 14,
          ),
          markers: {
            Marker(
              markerId: MarkerId(terminalId),
              position: terminalLocation,
              infoWindow: InfoWindow(title: 'Terminal ID: $terminalId'),
            ),
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
