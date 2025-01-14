import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

const String ip = "192.168.1.8";

class ViewDriversOnMapPage extends StatefulWidget {
  const ViewDriversOnMapPage({super.key});

  @override
  _ViewDriversPageState createState() => _ViewDriversPageState();
}

class _ViewDriversPageState extends State<ViewDriversOnMapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Marker> _originalMarkers = {};
  bool _isLoading = true;
  String? _errorMessage;
  final _secureStorage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDriverLocations();
  }

  Future<BitmapDescriptor> _loadCustomIcon() async {
    final ByteData data = await rootBundle.load("assets/taxi-icon.png");
    final Uint8List bytes = data.buffer.asUint8List();
    final ui.Image image = await decodeImageFromList(bytes);

    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(
      recorder,
      Rect.fromPoints(const Offset(0, 0), const Offset(100, 100)),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint(),
    );

    final Picture picture = recorder.endRecording();
    final ui.Image resizedImage = await picture.toImage(100, 100);
    final ByteData? byteData = await resizedImage.toByteData(format: ImageByteFormat.png);
    final Uint8List resizedBytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(resizedBytes);
  }

  Future<void> _fetchDriverLocations() async {
    try {
      final String? token = await _secureStorage.read(key: 'jwt_token');
      if (token == null) throw Exception('Token not found');

      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/line/drivers/locations'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        for (var vehicle in data) {
          final driver = vehicle['driver'];
          final customIcon = await _loadCustomIcon();
          final marker = Marker(
            markerId: MarkerId(vehicle['vehicle_id'].toString()),
            position: LatLng(vehicle['latitude'], vehicle['longitude']),
            infoWindow: InfoWindow(
              title: driver['username'],
              snippet: 'Phone: ${driver['phone_number']}\nEmail: ${driver['email']}',
            ),
            icon: customIcon,
          );
          _markers.add(marker);
        }

        // حفظ العلامات الأصلية
        _originalMarkers = Set.from(_markers);

        if (_mapController != null && _markers.isNotEmpty) {
          _centerMapAroundMarkers();
        }
      } else {
        throw Exception('Failed to load driver locations. Status: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Error: $error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _centerMapAroundMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    LatLngBounds bounds;
    var latitudes = _markers.map((m) => m.position.latitude).toList();
    var longitudes = _markers.map((m) => m.position.longitude).toList();
    bounds = LatLngBounds(
      southwest: LatLng(
        latitudes.reduce((a, b) => a < b ? a : b),
        longitudes.reduce((a, b) => a < b ? a : b),
      ),
      northeast: LatLng(
        latitudes.reduce((a, b) => a > b ? a : b),
        longitudes.reduce((a, b) => a > b ? a : b),
      ),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _searchDriver(String query) {
    final lowerCaseQuery = query.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _markers = Set.from(_originalMarkers);
      } else {
        _markers = _originalMarkers.where((marker) {
          final infoWindow = marker.infoWindow;
          final driverName = infoWindow.title?.toLowerCase() ?? '';
          final phoneNumber = infoWindow.snippet?.toLowerCase() ?? '';
          final email = infoWindow.snippet?.toLowerCase() ?? '';
          return driverName.contains(lowerCaseQuery) ||
              phoneNumber.contains(lowerCaseQuery) ||
              email.contains(lowerCaseQuery);
        }).toSet();
      }
    });

    if (_markers.isNotEmpty) {
      _centerMapAroundMarkers();
    } else {
      _resetCamera();
    }
  }

  void _resetCamera() {
    if (_mapController != null) {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: LatLng(37.4221, -122.084), // Default position
            zoom: 10,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drivers on Map'),
        backgroundColor: const Color(0xFFF5CF24),
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.4221, -122.084),
              zoom: 20,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              if (_markers.isNotEmpty) {
                _centerMapAroundMarkers();
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey[600]),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _markers = Set.from(_originalMarkers);
                      }); // Reset the markers when cleared
                    },
                  ),
                  hintText: 'Search by name, phone, or email',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                ),
                onChanged: _searchDriver,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _markers.isNotEmpty
          ? FloatingActionButton(
        onPressed: _centerMapAroundMarkers,
        child: const Icon(Icons.my_location),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}
