import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'location_provider.dart';

class LocationService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Timer? _locationTimer;
  double terminalLatitude = 0.0;
  double terminalLongitude = 0.0;
  Position? _lastPosition;
  bool _isInRange = false;
  final String googleRoadsApiKey = "AIzaSyBUyuByMAu02NKWp76MsQ1xRWHKb2FsWEg";
  final String ip = "http://192.168.1.8:3000";

  Future<void> startTracking(BuildContext context) async {
    bool isDriver = await _isDriver();
    if (!isDriver) return;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }
    await _fetchTerminalLocation();
    _locationTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _checkSpeedAndWarn(context, position);
      if (_lastPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        if (distance >= 10) {
          _updateVehicleLocation();
          _lastPosition = position;
        }
      } else {
        _lastPosition = position;
      }
      _updateDriverLocation(position);
      Provider.of<LocationProvider>(context, listen: false).updatePosition(position);
    });
  }

  Future<double?> _fetchSpeedLimit(double latitude, double longitude) async {
    final Uri url = Uri.parse(
      "https://roads.googleapis.com/v1/speedLimits?path=$latitude,$longitude&key=$googleRoadsApiKey",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['speedLimits'] != null && (data['speedLimits'] as List).isNotEmpty) {
          final speedInfo = data['speedLimits'][0];
          final limit = speedInfo['speedLimit'];
          return limit.toDouble();
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _checkSpeedAndWarn(BuildContext context, Position position) async {
    double speedInKmh = position.speed * 3.6;
    double? roadSpeedLimit = await _fetchSpeedLimit(position.latitude, position.longitude);
    double actualSpeedLimit = roadSpeedLimit ?? 50.0;
    if (speedInKmh > actualSpeedLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "تحذير! سرعتك الحالية ${speedInKmh.toStringAsFixed(1)} وتتجاوز الحد المسموح $actualSpeedLimit",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
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

  Future<void> _fetchTerminalLocation() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        final response = await http.get(
          Uri.parse('$ip/api/v1/terminals/terminal-position'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          terminalLatitude = data['latitude'];
          terminalLongitude = data['longitude'];
        }
      }
    } catch (_) {}
  }

  Future<void> _updateDriverLocation(Position position) async {
    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      terminalLatitude,
      terminalLongitude,
    );
    if (distance <= 500 && !_isInRange) {
      _isInRange = true;
      await _incrementVehicleCount();
    } else if (distance > 500 && _isInRange) {
      _isInRange = false;
      await _decrementVehicleCount();
    }
  }

  Future<void> _incrementVehicleCount() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        await http.patch(
          Uri.parse('$ip/api/v1/vehicle/increment'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (_) {}
  }

  Future<void> _decrementVehicleCount() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        await http.patch(
          Uri.parse('$ip/api/v1/vehicle/decrement'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (_) {}
  }

  Future<void> _updateVehicleLocation() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');
      if (token == null) return;
      if (_lastPosition == null) return;
      final body = jsonEncode({
        'latitude': _lastPosition!.latitude,
        'longitude': _lastPosition!.longitude,
      });
      final response = await http.patch(
        Uri.parse('$ip/api/v1/vehicle/update-location'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print("Vehicle location updated successfully: ${responseData['vehicle']}");
      }
    } catch (_) {}
  }

  void stopTracking() {
    _locationTimer?.cancel();
  }
}
