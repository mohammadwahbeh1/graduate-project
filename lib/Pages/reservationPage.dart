import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

const String ip = "192.168.1.12";
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing reservation: $e')),
      );
    }
  }

  Future<void> _deleteScheduledTime(int reservationId) async {
    String? token = await storage.read(key: 'jwt_token');

    try {
      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/reservation/$reservationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'scheduled_date': null,
          'scheduled_time': null,
          'is_recurring': false,
          'recurring_days': null,
        }),
      );

      if (response.statusCode == 200) {
        _fetchReservations();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Schedule removed successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing schedule: $e')),
      );
    }
  }

  Future<void> _deleteRecurringDay(int reservationId, String day) async {
    String? token = await storage.read(key: 'jwt_token');

    try {
      final currentReservation = _reservations.firstWhere(
              (r) => r['reservation_id'] == reservationId
      );
      List<String> currentDays = List<String>.from(currentReservation['recurring_days'] ?? []);
      currentDays.remove(day);

      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/reservation/$reservationId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'recurring_days': currentDays.join(','),
          'is_recurring': currentDays.isNotEmpty,
        }),
      );

      if (response.statusCode == 200) {
        _fetchReservations();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recurring day removed successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing recurring day: $e')),
      );
    }
  }

  Future<void> _showEmergencyCancelDialog(Map<String, dynamic> reservation) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.emergency, color: Colors.red),
              SizedBox(width: 8),
              Flexible(child: Text('Emergency Cancellation')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What would you like to cancel?'),
                SizedBox(height: 16),
                if (reservation['is_recurring'] == true &&
                    reservation['recurring_days'] != null &&
                    (reservation['recurring_days'] as List).isNotEmpty)
                  ElevatedButton.icon(
                    icon: Icon(Icons.calendar_today),
                    label: Text('Cancel Recurring Days'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 45),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showRecurringDaysCancelDialog(reservation);
                    },
                  ),
                SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: Icon(Icons.cancel),
                  label: Text('Cancel Entire Reservation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 45),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteReservation(reservation['reservation_id']);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRecurringDaysCancelDialog(Map<String, dynamic> reservation) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Recurring Days'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select days to cancel:'),
                SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (reservation['recurring_days'] as List).map((day) {
                    return FilterChip(
                      label: Text(day),
                      selected: true,
                      onSelected: (bool selected) {
                        if (!selected) {
                          Navigator.of(context).pop();
                          _deleteRecurringDay(reservation['reservation_id'], day);
                        }
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
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
          SizedBox(height: 16),
          Text(
            "No Reservations Yet",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
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
      padding: EdgeInsets.all(16),
      itemCount: _reservations.length,
      itemBuilder: (context, index) => _buildReservationCard(_reservations[index]),
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
                TextButton.icon(
                  icon: Icon(Icons.emergency, color: Colors.red),
                  label: Text('Cancel', style: TextStyle(color: Colors.red)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => _showEmergencyCancelDialog(reservation),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _showDeleteDialog(reservation['reservation_id']),
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildRouteInfo(
                  reservation['start_destination'],
                  reservation['end_destination'],
                ),
                SizedBox(height: 16),
                if (reservation['scheduled_date'] != null)
                  _buildScheduledInfo(
                    reservation['scheduled_date'],
                    reservation['scheduled_time'],
                    reservation['reservation_id'],
                  ),
                if (reservation['is_recurring'] == true)
                  _buildRecurringDays(
                    reservation['recurring_days'],
                    reservation['reservation_id'],
                  ),
                _buildContactInfo(
                  reservation['phone_number'],
                  reservation['description'],
                ),
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
              Text(start, style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Icon(Icons.arrow_forward, color: Colors.grey),
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
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: Colors.blue),
          SizedBox(width: 8),
          Text(
            DateFormat('MMM dd, yyyy').format(date),
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (time != null) ...[
            SizedBox(width: 90),
            Icon(Icons.access_time, color: Colors.blue),
            SizedBox(width: 10),
            Text(time, style: TextStyle(fontWeight: FontWeight.bold)),
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
            children: days.map((day) => Chip(
              label: Text(day),

            )).toList(),
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

  Future<void> _showDeleteDialog(int reservationId) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Reservation'),
          content: Text('Are you sure you want to delete this reservation?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteReservation(reservationId);
              },
            ),
          ],
        );
      },
    );
  }
}