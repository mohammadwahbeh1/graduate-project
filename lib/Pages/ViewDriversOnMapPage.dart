import 'dart:ui' as ui;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
const String ip = "192.168.1.5";


class ViewDriversOnMapPage extends StatefulWidget {
  @override
  _ViewDriversPageState createState() => _ViewDriversPageState();
}

class _ViewDriversPageState extends State<ViewDriversOnMapPage> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  String? _errorMessage;
  final _secureStorage = const FlutterSecureStorage();
  TextEditingController _searchController = TextEditingController();
  Marker? _selectedMarker;

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
    final Canvas canvas = Canvas(recorder, Rect.fromPoints(Offset(0, 0), Offset(100, 100)));
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, 100, 100),
        Paint()
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
          print(driver);
          final customIcon = await _loadCustomIcon();
          _markers.add(
            Marker(
              markerId: MarkerId(vehicle['vehicle_id'].toString()),
              position: LatLng(vehicle['latitude'], vehicle['longitude']),
              infoWindow: InfoWindow(
                title: driver['username'],
                snippet: 'Phone: ${driver['phone_number']}\nEmail: ${driver['email']}',
              ),
              icon: customIcon,
            ),
          );
        }
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
      southwest: LatLng(latitudes.reduce((a, b) => a < b ? a : b),
          longitudes.reduce((a, b) => a < b ? a : b)),
      northeast: LatLng(latitudes.reduce((a, b) => a > b ? a : b),
          longitudes.reduce((a, b) => a > b ? a : b)),
    );
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  void _searchDriver(String query) {
    final lowerCaseQuery = query.toLowerCase();
    final filteredMarkers = _markers.where((marker) {
      final infoWindow = marker.infoWindow;
      final driverName = infoWindow.title?.toLowerCase() ?? '';
      final phoneNumber = infoWindow.snippet?.toLowerCase() ?? '';
      final email = infoWindow.snippet?.toLowerCase() ?? '';
      return driverName.contains(lowerCaseQuery) ||
          phoneNumber.contains(lowerCaseQuery) ||
          email.contains(lowerCaseQuery);
    }).toSet();

    setState(() {
      _markers = filteredMarkers;
    });

    if (filteredMarkers.isNotEmpty) {
      _centerMapAroundMarkers();
    } else {
      // Reset the camera to the default position if no drivers are found
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
        backgroundColor: Color(0xFFF5CF24),
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
                zoom: 10,
              ),
              markers: _markers,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                _mapController?.setMapStyle('''
            [
              {
                "elementType": "geometry",
                "stylers": [
                  {
                    "color": "#ebe3cd"
                  }
                ]
              },
              {
                "elementType": "labels.text.fill",
                "stylers": [
                  {
                    "color": "#523735"
                  }
                ]
              },
              {
                "elementType": "labels.text.stroke",
                "stylers": [
                  {
                    "color": "#f5f1e6"
                  }
                ]
              },
              {
                "featureType": "administrative",
                "elementType": "geometry.stroke",
                "stylers": [
                  {
                    "color": "#c9b2a6"
                  }
                ]
              },
              {
                "featureType": "administrative.land_parcel",
                "elementType": "geometry.stroke",
                "stylers": [
                  {
                    "color": "#dcd2be"
                  }
                ]
              },
              {
                "featureType": "administrative.land_parcel",
                "elementType": "labels.text.fill",
                "stylers": [
                  {
                    "color": "#ae9e90"
                  }
                ]
              },
              {
                "featureType": "landscape.natural",
                "elementType": "geometry",
                "stylers": [
                  {
                    "color": "#dfd2ae"
                  }
                ]
              },
              {
                "featureType": "poi",
                "elementType": "geometry",
                "stylers": [
                  {
                    "color": "#dfd2ae"
                  }
                ]
              },
              {
                "featureType": "poi",
                "elementType": "labels.text.fill",
                "stylers": [
                  {
                    "color": "#93817c"
                  }
                ]
              },
              {
                "featureType": "poi.park",
                "elementType": "geometry.fill",
                "stylers": [
                  {
                    "color": "#a5b076"
                  }
                ]
              },
              {
                "featureType": "poi.park",
                "elementType": "labels.text.fill",
                "stylers": [
                  {
                    "color": "#447530"
                  }
                ]
              },
              {
                "featureType": "road",
                "elementType": "geometry",
                "stylers": [
                  {
                    "color": "#f5f1e6"
                  }
                ]
              },
              {
                "featureType": "road.arterial",
                "elementType": "labels.text.fill",
                "stylers": [
                  {
                    "color": "#757575"
                  }
                ]
              },
              {
                "featureType": "road.highway",
                "elementType": "geometry",
                "stylers": [
                  {
                    "color": "#f8c967"
                  }
                ]
              },
              {
                "featureType": "road.highway",
                "elementType": "geometry.stroke",
                "stylers": [
                  {
                    "color": "#e9bc62"
                  }
                ]
              },
              {
                "featureType": "road.highway.controlled_access",
                "elementType": "geometry",
                "stylers": [
                  {
                    "color": "#e98d58"
                  }
                ]
              },
              {
                "featureType": "road.highway.controlled_access",
                "elementType": "geometry.stroke",
                "stylers": [
                  {
                    "color": "#db8555"
                  }
                ]
              },
              {
                "featureType": "road.local",
                "elementType": "labels.text.fill",
                "stylers": [
                  {
                    "color": "#806b63"
                  }
                ]
              },
              {
                "featureType": "transit.line",
                "elementType": "geometry",
                "stylers": [
                  {
                    "color": "#dfd2ae"
                  }
                ]
              },
              {
                "featureType": "transit.line",
                "elementType": "labels.text.fill",
                "stylers": [
                  {
                    "color": "#8f7d77"
                  }
                ]
              },
              {
                "featureType": "transit.line",
                "elementType": "labels.text.stroke",
                "stylers": [
                  {
                    "color": "#ebe3cd"
                  }
                ]
              },
              {
                "featureType": "transit.station",
                "elementType": "geometry",
                "stylers": [
                  {
                    "color": "#dfd2ae"
                  }
                ]
              },
              {
                "featureType": "water",
                "elementType": "geometry.fill",
                "stylers": [
                  {
                    "color": "#b9d3c2"
                  }
                ]
              },
              {
                "featureType": "water",
                "elementType": "labels.text.fill",
                "stylers": [
                  {
                    "color": "#92998d"
                  }
                ]
              }
            ]
          ''');
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
                    offset: Offset(0, 3),
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
                      _fetchDriverLocations(); // Reset the markers when cleared
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
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0,),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat
    );
  }
}
