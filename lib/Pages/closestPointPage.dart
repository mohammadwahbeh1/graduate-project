import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;

const ip = '192.168.1.12';
class SearchResult {
  final String lineName;
  final String description;

  SearchResult({required this.lineName, required this.description});
}

class ClosestPointPage extends StatefulWidget {
  @override
  _ClosestPointPageState createState() => _ClosestPointPageState();
}

class _ClosestPointPageState extends State<ClosestPointPage> {
  GoogleMapController? _googleMapController;
  LatLng? _currentLocation;
  LatLng? _lineLocation;
  LatLng? _finalDestination;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final TextEditingController _destinationController = TextEditingController();
  final storage = FlutterSecureStorage();
  String? _estimatedTime;
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;
  final FocusNode _focusNode = FocusNode();

  final String _retroMapStyle = ''' [
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
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#fdfcf8"
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
  
 '''; // Your existing map style

  @override
  void initState() {
    super.initState();
    requestLocationPermission().then((_) {
      _getCurrentLocation();
    });
    _destinationController.addListener(() {
      _onSearchChanged();
    });
  }

  Future<List<SearchResult>> fetchLines(String query) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/line/all'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((line) => SearchResult(
            lineName: line['lineName'], // Updated field
            description: 'Lat: ${line['latitude']}, Long: ${line['longitude']}' // Customize description
        )).toList();
      } else {
        throw Exception('Failed to fetch lines');
      }
    } catch (e) {
      print('Error fetching lines: $e');
      return [];
    }
  }


  void _onSearchChanged() async {
    if (_destinationController.text.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final lines = await fetchLines(_destinationController.text);

    setState(() {
      _searchResults = lines.where((result) =>
          result.lineName.toLowerCase().contains(_destinationController.text.toLowerCase())
      ).toList();
      _isSearching = false;
    });
  }

  void _applyMapStyle() {
    _googleMapController?.setMapStyle(_retroMapStyle);
  }

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      await Permission.location.request();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation
      );
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _markers.add(Marker(
          markerId: MarkerId('current_location'),
          position: _currentLocation!,
          infoWindow: InfoWindow(title: 'Your Location'),
        ));
      });

      _googleMapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 14.0),
      );
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching location. Please check permissions.")),
      );
    }
  }

  Future<void> _fetchLineLocation(String lineName) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/line/location?lineName=$lineName'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print(response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _lineLocation = LatLng(data['latitude'], data['longitude']);
          _markers.add(Marker(
            markerId: MarkerId('line_location'),
            position: _lineLocation!,
            infoWindow: InfoWindow(title: 'Line Location: $lineName'),
          ));
        });
      } else {
        throw Exception('Failed to fetch line location');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch line location.")),
      );
    }
  }

  Future<void> _getRoute() async {
    if (_currentLocation != null && _finalDestination != null) {
      try {
        String origin = "${_currentLocation!.latitude},${_currentLocation!.longitude}";
        String destination = "${_finalDestination!.latitude},${_finalDestination!.longitude}";
        String apiKey = 'AIzaSyBUyuByMAu02NKWp76MsQ1xRWHKb2FsWEg';

        final response = await http.get(Uri.parse(
            'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&key=$apiKey'
        ));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['routes'].isNotEmpty) {
            final legs = data['routes'][0]['legs'][0];
            final steps = legs['steps'];
            final duration = legs['duration']['text'];

            setState(() {
              _estimatedTime = duration;

              List<LatLng> polylineCoordinates = [];
              for (var step in steps) {
                polylineCoordinates.add(
                    LatLng(step['end_location']['lat'], step['end_location']['lng'])
                );
              }

              _polylines.clear();
              _polylines.add(Polyline(
                polylineId: PolylineId('route'),
                points: polylineCoordinates,
                color: Colors.blue,
                width: 5,
              ));

              _googleMapController?.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: LatLng(
                      polylineCoordinates.map((e) => e.latitude).reduce(math.min),
                      polylineCoordinates.map((e) => e.longitude).reduce(math.min),
                    ),
                    northeast: LatLng(
                      polylineCoordinates.map((e) => e.latitude).reduce(math.max),
                      polylineCoordinates.map((e) => e.longitude).reduce(math.max),
                    ),
                  ),
                  100.0,
                ),
              );
            });
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch route.")),
        );
      }
    }
  }

  Future<void> _findDestination() async {
    String destination = _destinationController.text.trim();
    if (destination.isEmpty) return;

    try {
      await _fetchLineLocation(destination);
      List<Location> locations = await locationFromAddress(destination);

      if (locations.isNotEmpty) {
        setState(() {
          _finalDestination = LatLng(locations[0].latitude, locations[0].longitude);
          _markers.add(Marker(
            markerId: MarkerId('final_destination'),
            position: _finalDestination!,
            infoWindow: InfoWindow(title: 'Destination: $destination'),
          ));
        });
        await _getRoute();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to find the destination.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _currentLocation == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation!,
              zoom: 14.0,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              _googleMapController = controller;
              _applyMapStyle();
            },
          ),

          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _destinationController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search for a line...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _destinationController.text.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _destinationController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      if (_isSearching)
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      if (_searchResults.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(_searchResults[index].lineName),
                                subtitle: Text(_searchResults[index].description),
                                onTap: () {
                                  _destinationController.text = _searchResults[index].lineName;
                                  _findDestination();
                                  _focusNode.unfocus();
                                  setState(() {
                                    _searchResults = [];
                                  });
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
                if (_estimatedTime != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          "Estimated Time: $_estimatedTime",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _focusNode.dispose();
    _googleMapController?.dispose();
    super.dispose();
  }
}
