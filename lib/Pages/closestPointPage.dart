import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geocoding/geocoding.dart';

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
  String? _estimatedTime; // Variable to store estimated time

  @override
  void initState() {
    super.initState();
    requestLocationPermission().then((_) {
      _getCurrentLocation();
    });
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
          desiredAccuracy: LocationAccuracy.bestForNavigation); // Highest accuracy
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
        SnackBar(content: Text("Error fetching location. Please check your permissions and try again.")),
      );
    }
  }

  Future<void> _fetchLineLocation(String lineName) async {
    String? token = await storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('http://192.168.1.8:3000/api/v1/line/location?lineName=$lineName'),
      headers: {'Authorization': 'Bearer $token'},
    );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch line location.")),
      );
    }
  }

  Future<void> _getRoute() async {
    if (_currentLocation != null && _finalDestination != null) {
      String origin = "${_currentLocation!.latitude},${_currentLocation!.longitude}";
      String destination = "${_finalDestination!.latitude},${_finalDestination!.longitude}";

      String apiKey = 'AIzaSyBUyuByMAu02NKWp76MsQ1xRWHKb2FsWEg';
      String url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination&mode=driving&traffic_model=best_guess&departure_time=now&key=$apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> routes = data['routes'];
        if (routes.isNotEmpty) {
          List<dynamic> legs = routes[0]['legs'];
          if (legs.isNotEmpty) {
            List<dynamic> steps = legs[0]['steps'];

            // Extract the duration from the response
            String duration = legs[0]['duration']['text']; // Duration in text format (e.g., "15 mins")

            setState(() {
              _estimatedTime = duration; // Store the estimated time
            });

            List<LatLng> polylineCoordinates = [];
            for (var step in steps) {
              polylineCoordinates.add(LatLng(step['end_location']['lat'], step['end_location']['lng']));
            }

            setState(() {
              _polylines.clear();
              _polylines.add(Polyline(
                polylineId: PolylineId('route'),
                points: polylineCoordinates,
                color: Colors.blue,
                width: 5,
              ));
            });

            _googleMapController?.animateCamera(
              CameraUpdate.newLatLngBounds(
                LatLngBounds(
                  southwest: LatLng(
                    polylineCoordinates.map((e) => e.latitude).reduce((a, b) => a < b ? a : b),
                    polylineCoordinates.map((e) => e.longitude).reduce((a, b) => a < b ? a : b),
                  ),
                  northeast: LatLng(
                    polylineCoordinates.map((e) => e.latitude).reduce((a, b) => a > b ? a : b),
                    polylineCoordinates.map((e) => e.longitude).reduce((a, b) => a > b ? a : b),
                  ),
                ),
                100.0,
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to fetch route.")));
      }
    }
  }

  Future<void> _findDestination() async {
    String destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid destination.")),
      );
      return;
    }

    await _fetchLineLocation(destination);

    try {
      List<Location> locations = await locationFromAddress(destination);
      if (locations.isNotEmpty) {
        setState(() {
          _finalDestination = LatLng(locations[0].latitude, locations[0].longitude);
          _markers.add(Marker(
            markerId: MarkerId('final_destination'),
            position: _finalDestination!,
            infoWindow: InfoWindow(title: 'Final Destination: $destination'),
          ));
          _getRoute();
        });
      }
    } catch (e) {
      print("Error fetching final destination: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to find the destination. Please try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Planner'),
        backgroundColor: Colors.yellow,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _destinationController,
              decoration: const InputDecoration(
                labelText: 'Enter Line Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _findDestination,
            child: const Text('Find Route'),
          ),
          if (_estimatedTime != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Estimated Time: $_estimatedTime",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: _currentLocation == null
                ? Center(child: CircularProgressIndicator())
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
              },
            ),
          ),
        ],
      ),
    );
  }
}