import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

const String ip = "192.168.1.7";

const storage = FlutterSecureStorage();

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({Key? key}) : super(key: key);

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
    final String? userId = await storage.read(key: 'user_id');
    final String? token = await storage.read(key: 'jwt_token');

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
            _reservations = data.map((reservation) {
              return {
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
                "recurrence_end_date":
                reservation['recurrence_end_date'] != null
                    ? DateTime.parse(reservation['recurrence_end_date'])
                    : null,
              };
            }).toList();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text('Failed to fetch reservations: ${response.statusCode}'),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching reservations: $e'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteReservation(int reservationId) async {
    final String? token = await storage.read(key: 'jwt_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

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
          _reservations
              .removeWhere((r) => r['reservation_id'] == reservationId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation removed successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('Failed to remove reservation: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing reservation: $e')),
      );
    }
  }

  Future<void> _pauseReservation(Map<String, dynamic> reservation) async {
    final String? token = await storage.read(key: 'jwt_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse(
            'http://$ip:3000/api/v1/reservation/pause/${reservation['reservation_id']}'),
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
          const SnackBar(content: Text('Reservation paused successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pause reservation: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error pausing reservation: $e')),
      );
    }
  }

  Future<void> _resumeReservation(Map<String, dynamic> reservation) async {
    final String? token = await storage.read(key: 'jwt_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse(
            'http://$ip:3000/api/v1/reservation/${reservation['reservation_id']}'),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('Failed to resume reservation: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resuming reservation: $e')),
      );
    }
  }

  Future<void> _renewReservation(Map<String, dynamic> reservation) async {
    final String? token = await storage.read(key: 'jwt_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    try {
      final response = await http.patch(
        Uri.parse(
            'http://$ip:3000/api/v1/reservation/${reservation['reservation_id']}'),
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
          reservation['status'] = 'Pending';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation renewed successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
            Text('Failed to renew reservation: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error renewing reservation: $e')),
      );
    }
  }

  void _showRatingDialog(Map<String, dynamic> reservation) {
    double _ratingValue = 3.0;
    final TextEditingController _commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Rate the Driver'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RatingBar.builder(
                  initialRating: _ratingValue,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemSize: 30,
                  itemBuilder: (context, _) =>
                  const Icon(Icons.star, color: Colors.amber),
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
    final String? token = await storage.read(key: 'jwt_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

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
      appBar: AppBar(
        title: const Text('Your Reservations'),
      ),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No Reservations Yet",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Your reservations will appear here",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
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
    final String statusLower = reservation['status'].toString().toLowerCase();

    // تحديد اللون والأيقونة بناءً على حالة الحجز
    Color statusColor;
    IconData statusIcon;
    switch (statusLower) {
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

    final bool showWarning = statusLower == 'cancelled';

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,  // النصوص بمحاذاة اليسار
          children: [
            // سطر الحالة (الأيقونة + النص)
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reservation['status'].toString().toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // سطر الأزرار (في أقصى اليمين)
            if (statusLower == 'confirmed' ||
                statusLower == 'pending' ||
                statusLower == 'pause' ||
                statusLower == 'cancelled')
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 4,
                  runSpacing: 4,
                  children: _buildActionButtons(reservation),
                ),
              ),

            // تحذير إن كانت Cancelled
            if (showWarning) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No one accepted your request within 2 hours. '
                            'If your request is not renewed, it will be deleted within 24 hours.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),
            const Divider(),

            // بقية التفاصيل: المسار، التاريخ، الوصف، إلخ
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  _buildRouteInfo(
                    reservation['start_destination'],
                    reservation['end_destination'],
                  ),
                  const SizedBox(height: 8),
                  if (reservation['scheduled_date'] != null)
                    _buildScheduledInfo(
                      reservation['scheduled_date'],
                      reservation['scheduled_time'],
                    ),
                  if (reservation['is_recurring'] == true)
                    _buildRecurringDays(reservation['recurring_days']),
                  _buildContactInfo(
                    reservation['phone_number'],
                    reservation['description'],
                  ),
                  if (reservation['driver_id'] != null)
                    _buildDriverInfo(reservation['driver_id']),
                  if (reservation['recurrence_pattern'] != null)
                    _buildRecurrenceInfo(reservation),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(Map<String, dynamic> reservation) {
    final List<Widget> buttons = [];
    final String statusLower = reservation['status'].toString().toLowerCase();

    const TextStyle buttonTextStyle = TextStyle(fontSize: 17);
    const double iconSize = 22;

    if (statusLower != 'confirmed' && statusLower != 'pause') {
      buttons.add(
        TextButton.icon(
          icon: const Icon(Icons.delete_forever, color: Colors.red, size: iconSize),
          label: Text(
            'Delete',
            style: buttonTextStyle.copyWith(color: Colors.red),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.1),
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _deleteReservation(reservation['reservation_id']),
        ),
      );
    }

    if (statusLower == 'confirmed') {
      buttons.addAll([
        TextButton.icon(
          icon: const Icon(Icons.pause, color: Colors.blue, size: iconSize),
          label: Text(
            'Pause',
            style: buttonTextStyle.copyWith(color: Colors.blue),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.blue.withOpacity(0.1),
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _pauseReservation(reservation),
        ),
        TextButton.icon(
          icon: const Icon(Icons.delete_forever, color: Colors.red, size: iconSize),
          label: Text(
            'Delete',
            style: buttonTextStyle.copyWith(color: Colors.red),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.1),
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _deleteReservation(reservation['reservation_id']),
        ),
        TextButton.icon(
          icon: Icon(Icons.star, color: Colors.amber, size: iconSize),
          label: Text(
            'Rate Driver',
            style: buttonTextStyle.copyWith(color: Colors.amber),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.amber.withOpacity(0.1),
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _showRatingDialog(reservation),
        ),
      ]);
    }

    if (statusLower == 'pause') {
      buttons.addAll([
        TextButton.icon(
          icon: Icon(Icons.play_arrow, color: Colors.green, size: iconSize),
          label: Text(
            'Resume',
            style: buttonTextStyle.copyWith(color: Colors.green),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.green.withOpacity(0.1),
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _resumeReservation(reservation),
        ),
        TextButton.icon(
          icon: Icon(Icons.delete_forever, color: Colors.red, size: iconSize),
          label: Text(
            'Delete',
            style: buttonTextStyle.copyWith(color: Colors.red),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.red.withOpacity(0.1),
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _deleteReservation(reservation['reservation_id']),
        ),
      ]);
    }

    if (statusLower == 'cancelled') {
      buttons.add(
        TextButton.icon(
          icon: const Icon(Icons.refresh, color: Colors.green, size: iconSize),
          label: Text(
            'Renew',
            style: buttonTextStyle.copyWith(color: Colors.green),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.green.withOpacity(0.1),
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => _renewReservation(reservation),
        ),
      );
    }

    return buttons;
  }

  /// بناء معلومات المسار (From - To)
  Widget _buildRouteInfo(String start, String end) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'From',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                start,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward, color: Colors.grey),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'To',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                end,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// بناء معلومات التاريخ والوقت المجدول
  Widget _buildScheduledInfo(DateTime date, String? time) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.event, color: Colors.blue, size: 14),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMM dd, yyyy').format(date),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          if (time != null) ...[
            const SizedBox(width: 16),
            const Icon(Icons.access_time, color: Colors.blue, size: 14),
            const SizedBox(width: 8),
            Text(
              time,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  /// بناء الأيام المتكررة
  Widget _buildRecurringDays(List<String>? days) {
    if (days == null || days.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recurring Days',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: days
                .map(
                  (day) => Chip(
                label: Text(
                  day,
                  style: const TextStyle(fontSize: 12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }

  /// بناء معلومات التواصل (رقم الهاتف + الوصف)
  Widget _buildContactInfo(String phone, String? description) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone, color: Colors.grey, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  phone,
                  style: const TextStyle(fontSize: 14),
                  softWrap: true,
                ),
              ),
            ],
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.description, color: Colors.grey, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    description,
                    style: const TextStyle(fontSize: 14),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// معلومات السائق (Driver ID) إن وجدت
  Widget _buildDriverInfo(int driverId) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          const Icon(Icons.directions_car, color: Colors.grey, size: 14),
          const SizedBox(width: 8),
          Text(
            'Driver ID: $driverId',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// معلومات التكرار (Recurrence Pattern) إن وجدت
  Widget _buildRecurrenceInfo(Map<String, dynamic> reservation) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recurrence Pattern: ${reservation['recurrence_pattern']}',
            style: const TextStyle(fontSize: 14),
          ),
          if (reservation['recurrence_end_date'] != null)
            Text(
              'Recurrence Ends: ${DateFormat('MMM dd, yyyy').format(reservation['recurrence_end_date'])}',
              style: const TextStyle(fontSize: 14),
            ),
        ],
      ),
    );
  }
}
