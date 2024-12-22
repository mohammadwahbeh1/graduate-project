import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

const String ip = "192.168.1.5";
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
    String? userId = await storage.read(key: 'user_id');
    String? token = await storage.read(key: 'jwt_token');

    if (userId != null && token != null) {
      try {
        final response = await http.get(
          Uri.parse('http://$ip:3000/api/v1/reservation/user/$userId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body)['data'];
          setState(() {
            _reservations = data.map((reservation) => {
              "reservation_id": reservation['reservation_id'],
              "user_id": reservation['user_id'],
              "driver_id": reservation['driver_id'],
              "start_destination": reservation['start_destination'],
              "end_destination": reservation['end_destination'],
              "status": reservation['status'],
              "created_at": DateTime.parse(reservation['created_at']),
              "scheduled_date": reservation['scheduled_date'] != null
                  ? DateTime.parse(reservation['scheduled_date'])
                  : null,
              "scheduled_time": reservation['scheduled_time'],
              "is_recurring": reservation['is_recurring'] ?? false,
              "recurring_days": reservation['recurring_days']?.split(','),
              "description": reservation['description'],
              "phone_number": reservation['phone_number'],
              "recurrence_pattern": reservation['recurrence_pattern'],
              "recurrence_interval": reservation['recurrence_interval'],
              "recurrence_end_date": reservation['recurrence_end_date'] != null
                  ? DateTime.parse(reservation['recurrence_end_date'])
                  : null,
            }).toList();
          });
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching reservations: $e')),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteReservation(int reservationId) async {
    String? token = await storage.read(key: 'jwt_token');

    try {
      final response = await http.delete(
        Uri.parse('http://$ip:3000/api/v1/reservation/$reservationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _reservations.removeWhere((r) => r['reservation_id'] == reservationId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reservation removed successfully')),
        );
        await _fetchReservations();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing reservation: $e')),
      );
    }
  }

  Future<void> _pauseReservation(Map<String, dynamic> reservation) async {
    String? token = await storage.read(key: 'jwt_token');

    try {
      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/reservation/pause/${reservation['reservation_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          reservation['status'] = 'Pause';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reservation paused successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error pausing reservation: $e')),
      );
    }
  }

  Future<void> _resumeReservation(Map<String, dynamic> reservation) async {
    String? token = await storage.read(key: 'jwt_token');

    try {
      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/reservation/${reservation['reservation_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': 'Confirmed',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          reservation['status'] = 'Confirmed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation resumed successfully')),
        );
        await _fetchReservations();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resuming reservation: $e')),
      );
    }
  }

  Future<void> _renewReservation(Map<String, dynamic> reservation) async {
    String? token = await storage.read(key: 'jwt_token');

    try {
      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/reservation/${reservation['reservation_id']}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'status': 'Pending',
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          reservation['status'] = 'Confirmed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation renewed successfully')),
        );
        await _fetchReservations();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error renewing reservation: $e')),
      );
    }
  }

  void _showRatingDialog(Map<String, dynamic> reservation) {
    double _ratingValue = 3.0;
    TextEditingController _commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rate the Driver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RatingBar.builder(
                initialRating: _ratingValue,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemSize: 30,
                itemBuilder: (context, _) => const Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {
                  _ratingValue = rating;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Add a comment',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                Navigator.pop(context);
                _submitRating(
                  reservationId: reservation['reservation_id'].toString(),
                  driverId: reservation['driver_id'].toString(),
                  rating: _ratingValue.toString(),
                  comment: _commentController.text,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitRating({
    required String reservationId,
    required String driverId,
    required String rating,
    required String comment,
  }) async {
    String? token = await storage.read(key: 'jwt_token');

    try {
      final response = await http.post(
        Uri.parse('http://$ip:3000/api/v1/driver-ratings/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          "reservation_id": reservationId,
          "driver_id": driverId,
          "rating": rating,
          "comment": comment
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating created successfully')),
        );
      } else if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit rating. Code: ${response.statusCode}',
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting rating: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _fetchReservations,
        child: _reservations.isEmpty
            ? _buildEmptyState()
            : _buildReservationsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[400]),
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
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reservations.length,
      itemBuilder: (context, index) =>
          _buildReservationCard(_reservations[index]),
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
      case 'pause':
        statusColor = Colors.blue;
        statusIcon = Icons.pause_circle_filled;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            leading: Icon(statusIcon, color: statusColor),
            title: Text(
              reservation['status'].toString().toUpperCase(),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reservation['status'].toString().toLowerCase() != 'confirmed' &&
                    reservation['status'].toString().toLowerCase() != 'pause')
                  TextButton.icon(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    label: Text('Cancel', style: TextStyle(color: Colors.red)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _deleteReservation(reservation['reservation_id']),
                  ),
                if (reservation['status'].toString().toLowerCase() == 'confirmed') ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.pause, color: Colors.blue),
                    label: const Text('Pause', style: TextStyle(color: Colors.blue)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _pauseReservation(reservation),
                  ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    icon: Icon(Icons.cancel, color: Colors.red),
                    label: Text('Cancel', style: TextStyle(color: Colors.red)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _deleteReservation(reservation['reservation_id']),
                  ),
                  SizedBox(width: 8),
                  TextButton.icon(
                    icon: Icon(Icons.star, color: Colors.amber),
                    label: Text('Rate Driver', style: TextStyle(color: Colors.amber[800])),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.amber.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showRatingDialog(reservation),
                  ),
                ],
                if (reservation['status'].toString().toLowerCase() == 'pause') ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                    label: const Text('Resume', style: TextStyle(color: Colors.green)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _resumeReservation(reservation),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _deleteReservation(reservation['reservation_id']),
                  ),
                ],
                if (reservation['status'].toString().toLowerCase() == 'cancelled')
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, color: Colors.green),
                    label: const Text('Renew', style: TextStyle(color: Colors.green)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _renewReservation(reservation),
                  ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRouteInfo(reservation['start_destination'], reservation['end_destination']),
                const SizedBox(height: 16),
                if (reservation['scheduled_date'] != null)
                  _buildScheduledInfo(
                    reservation['scheduled_date'],
                    reservation['scheduled_time'],
                    reservation['reservation_id'],
                  ),
                if (reservation['is_recurring'] == true)
                  _buildRecurringDays(reservation['recurring_days'], reservation['reservation_id']),
                _buildContactInfo(reservation['phone_number'], reservation['description']),
                if (reservation['driver_id'] != null) _buildDriverInfo(reservation['driver_id']),
                if (reservation['recurrence_pattern'] != null)
                  _buildRecurrenceInfo(reservation),
              ],
            ),
          ),
        ],
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
              Text('From', style: TextStyle(color: Colors.grey[600])),
              Text(start, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward, color: Colors.grey),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('To', style: TextStyle(color: Colors.grey[600])),
              Text(end, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduledInfo(DateTime date, String? time, int reservationId) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMM dd, yyyy').format(date),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (time != null) ...[
            const SizedBox(width: 90),
            const Icon(Icons.access_time, color: Colors.blue),
            const SizedBox(width: 10),
            Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildRecurringDays(List<String>? days, int reservationId) {
    if (days == null || days.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recurring Days',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days
                .map((day) => Chip(
              label: Text(day),
            ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(String phone, String? description) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone, color: Colors.grey),
              SizedBox(width: 8),
              Text(phone),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.description, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(child: Text(description)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverInfo(int driverId) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          const Icon(Icons.directions_car, color: Colors.grey),
          const SizedBox(width: 8),
          Text('Driver ID: $driverId'),
        ],
      ),
    );
  }

  Widget _buildRecurrenceInfo(Map<String, dynamic> reservation) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recurrence Pattern: ${reservation['recurrence_pattern']}'),
          if (reservation['recurrence_end_date'] != null)
            Text('Recurrence Ends: ${DateFormat('MMM dd, yyyy').format(reservation['recurrence_end_date'])}'),
        ],
      ),
    );
  }
}
