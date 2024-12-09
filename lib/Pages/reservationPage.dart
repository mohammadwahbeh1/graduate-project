import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // Add this package for date formatting

const String ip = "192.168.1.8";
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
        Uri.parse('http://$ip:3000/api/v1/reservation/user/$userId'),
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
      Uri.parse('http://$ip:3000/api/v1/reservation/$reservationId'),
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
  // ... Keep your existing _fetchReservations and _cancelReservation methods ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.blue,
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchReservations,
        child: _reservations.isEmpty
            ? _buildEmptyState(context)
            : _buildReservationsList(),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            "No Reservations Yet",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your reservations will appear here",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final reservation = _reservations[index];
        return _buildReservationCard(reservation);
      },
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    Color statusColor;
    IconData statusIcon;

    switch (reservation['status'].toString().toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Handle tap if needed
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      reservation['status'].toString().toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _showCancelDialog(reservation['reservation_id']),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),
                _buildRouteInfo(
                  reservation['start_destination'],
                  reservation['end_destination'],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(reservation['created_at']),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfo(String start, String end) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'From',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                start,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.arrow_forward, color: Colors.grey[400]),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'To',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                end,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showCancelDialog(int reservationId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Cancel Reservation'),
          content: const Text('Are you sure you want to cancel this reservation?'),
          actions: [
            TextButton(
              child: const Text('No', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Yes', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelReservation(reservationId);
              },
            ),
          ],
        );
      },
    );
  }
}
