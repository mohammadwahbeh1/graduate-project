import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Define a Location Provider to update the app's state
class LocationProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  // Update the position and notify listeners
  void updatePosition(Position position) {
    _currentPosition = position;
    notifyListeners();
  }
}

class LocationService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  StreamSubscription<Position>? _positionStream;
  Timer? _locationTimer;

  Future<void> startTracking(BuildContext context) async {
    bool isDriver = await _isDriver();
    if (isDriver) {
      // Start a periodic timer to update location every minute (60 seconds)
      _locationTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _updateDriverLocation(position);

        // Update the location in the Provider
        Provider.of<LocationProvider>(context, listen: false).updatePosition(position);
      });
    }
  }

  Future<bool> _isDriver() async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      Map<String, dynamic> decodedToken = Jwt.parseJwt(token);
      return decodedToken['role']?.trim() == 'driver';
    }
    return false;
  }

  Future<void> _updateDriverLocation(Position position) async {
    try {
      String? token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        await http.patch(
          Uri.parse('http://192.168.1.8:3000/api/v1/vehicle/update-location'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'latitude': position.latitude,
            'longitude': position.longitude,
          }),
        );

        // Print the updated latitude and longitude after each successful update
        print("Location updated: Latitude: ${position.latitude}, Longitude: ${position.longitude}");
      }
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  void stopTracking() {
    _positionStream?.cancel();
    _locationTimer?.cancel(); // Stop the periodic timer when tracking is stopped
  }
}
