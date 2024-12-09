import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationProvider with ChangeNotifier {
  Position? _currentPosition;

  Position? get currentPosition => _currentPosition;

  // Update the position and notify listeners
  void updatePosition(Position position) {
    _currentPosition = position;
    notifyListeners();
  }
}
