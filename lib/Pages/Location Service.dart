import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;


import 'location_provider.dart';
const String ip = "192.168.1.4";

class LocationService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Timer? _locationTimer;

  // Terminal's latitude and longitude (fetch from API)
  double terminalLatitude = 0.0;
  double terminalLongitude = 0.0;
  Position? _lastPosition;

  // Flag to track whether the driver is inside the range
  bool _isInRange = false;

  Future<void> startTracking(BuildContext context) async {
    bool isDriver = await _isDriver();
    if (isDriver) {
      // Check and request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return;
      }

      // Fetch the terminal location once (you can store this in a global state)
      await _fetchTerminalLocation();

      // Start periodic updates for the driver's location
      _locationTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        if(_lastPosition!=null){
          double distance= Geolocator.distanceBetween(
              _lastPosition!.latitude,
              _lastPosition!.longitude ,
              position.latitude,
              position.longitude);
          if(distance>=10){
            _updateVehicleLocation();
            _lastPosition=position;
          }
        }
        else{
          _lastPosition=position;
          print("the last position is : $_lastPosition");
        }
        _updateDriverLocation(position);
        Provider.of<LocationProvider>(context, listen: false).updatePosition(position);
        print('Position updated: ${position.latitude}, ${position.longitude}');
      });
    }
  }

  // Define the _isDriver method to check if the user is a driver
  Future<bool> _isDriver() async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
      return decodedToken['role']?.trim() == 'driver';
    }
    return false;
  }

  // Fetch terminal location (call your API here)
  Future<void> _fetchTerminalLocation() async {
    // Assuming you have an API endpoint to fetch terminal info
    try {
      String? token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        final response = await http.get(
          Uri.parse('http://$ip:3000/api/v1/terminals/terminal-position'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          terminalLatitude = data['latitude'];
          terminalLongitude = data['longitude'];
        } else {
          print("Error fetching terminal location");
        }
      }
    } catch (e) {
      print("Error fetching terminal location: $e");
    }
  }

  // Calculate the distance between the driver's position and the terminal
  Future<void> _updateDriverLocation(Position position) async {
    // Calculate the distance between the driver's position and the terminal
    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      terminalLatitude,
      terminalLongitude,
    );
    print('Distance: $distance meters');

    // If the driver is within 500 meters and wasn't already inside, increment the count
    if (distance <= 500 && !_isInRange) {
      _isInRange = true; // Set the flag to true
      print('Driver entered the range');
      await _incrementVehicleCount();
    }

    // If the driver is outside of 500 meters and was previously inside, decrement the count
    if (distance > 500 && _isInRange) {
      _isInRange = false; // Set the flag to false
      print('Driver exited the range');
      await _decrementVehicleCount();
    }
  }

  // Call the backend to increment the vehicle count
  Future<void> _incrementVehicleCount() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        await http.patch(
          Uri.parse('http://$ip:3000/api/v1/vehicle/increment'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print("Vehicle count incremented successfully.");
      }
    } catch (e) {
      print("Error incrementing vehicle count: $e");
    }
  }

  // Call the backend to decrement the vehicle count
  Future<void> _decrementVehicleCount() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        await http.patch(
          Uri.parse('http://$ip:3000/api/v1/vehicle/decrement'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print("Vehicle count decremented successfully.");
      }
    } catch (e) {
      print("Error decrementing vehicle count: $e");
    }
  }
  Future<void> _updateVehicleLocation() async {
    try {
      // Retrieve JWT token from secure storage
      String? token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        print("JWT token not found.");
        return;
      }

      if (_lastPosition == null) {
        print("No last known position to update vehicle location.");
        return;
      }

      // Prepare the payload with the driver's current location
      final body = jsonEncode({
        'latitude': _lastPosition!.latitude,
        'longitude': _lastPosition!.longitude,
      });

      // Make the PATCH request to the backend
      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/vehicle/update-location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      // Handle the response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Vehicle location updated successfully: ${responseData['vehicle']}");
      } else {
        print("Failed to update vehicle location. Response: ${response.body}");
      }
    } catch (e) {
      print("Error updating vehicle location: $e");
    }
  }


  // Stop location tracking
  void stopTracking() {
    _locationTimer?.cancel(); // Stop the periodic timer when tracking is stopped
  }
}
