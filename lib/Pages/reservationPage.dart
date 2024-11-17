import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Create a secure storage instance
final storage = FlutterSecureStorage();

class ReservationsPage extends StatefulWidget {
  @override
  _ReservationsPageState createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  List<Map<String, dynamic>> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    String? userId = await storage.read(key: 'user_id'); // Retrieve user ID
    String? token = await storage.read(key: 'jwt_token'); // Retrieve JWT token
    if (userId != null && token != null) {
      final response = await http.get(
        Uri.parse('http://192.168.1.8:3000/api/v1/reservation/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // Include the token here
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        setState(() {
          _reservations = data.map((reservation) => {
            "reservation_id": reservation['reservation_id'],
            "start_destination": reservation['start_destination'],
            "end_destination": reservation['end_destination'],
            "status": reservation['status'],
            "created_at": DateTime.parse(reservation['created_at']),
          }).toList();
        });
      } else {
        print("Failed to fetch reservations, Status Code: ${response.statusCode}, Response: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch reservations')),
        );
      }
    } else {
      print("User ID or token not found");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User ID or token not found')),
      );
    }
    setState(() {
      _isLoading = false; // Reset loading state
    });
  }

  void _cancelReservation(int reservationId) async {
    String? token = await storage.read(key: 'jwt_token'); // Retrieve JWT token
    final response = await http.delete(
      Uri.parse('http://192.168.1.8:3000/api/v1/reservation/$reservationId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Include the token here
      },
    );
    if (response.statusCode == 200) {
      // Successfully canceled the reservation
      print("Reservation $reservationId canceled");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reservation canceled')),
      );
      _fetchReservations(); // Refresh the reservations list
    } else {
      // Handle error
      print("Failed to cancel reservation, Status Code: ${response.statusCode}, Response: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel reservation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: const Text(
          'Your Reservations',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
        itemCount: _reservations.length,
        itemBuilder: (context, index) {
          final reservation = _reservations[index];
          return _buildReservationCard(reservation);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: const Text(
        "You don't have any reservations.",
        style: TextStyle(fontSize: 18, color: Colors.black),
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "From: ${reservation['start_destination']} To: ${reservation['end_destination']}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Status: ${reservation['status']}",
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  "Date: ${reservation['created_at'].toLocal().toString().split(' ')[0]} ${reservation['created_at'].toLocal().toString().split(' ')[1].substring(0, 5)}",
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _cancelReservation(reservation['reservation_id']),
            ),
          ),
        ],
      ),
    );
  }
}
