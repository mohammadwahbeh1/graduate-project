// accepted_reservations_page.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'driverPage.dart';
import 'loginPage.dart';
import 'LineMangerCall.dart';
import 'profilePage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:untitled/Pages/Location Service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String ip = "192.168.1.8";
final storage = FlutterSecureStorage();

class AcceptedReservationsPage extends StatefulWidget {
  const AcceptedReservationsPage({super.key});

  @override
  _AcceptedReservationsPageState createState() =>
      _AcceptedReservationsPageState();
}

class _AcceptedReservationsPageState extends State<AcceptedReservationsPage> {
  List<dynamic> acceptedReservations = [];
  List<dynamic> filteredAcceptedReservations = [];
  bool isLoading = true;
  String searchQuery = '';
  String username = '';
  final locationService = LocationService();
  WebSocketChannel? _channel;

  // إضافة متغيرات للتقويم
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _reservationsByDate = {};

  @override
  void initState() {
    super.initState();
    _fetchAcceptedReservations();
    fetchUserProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      locationService.startTracking(context);
    });
  }

  @override
  void dispose() {
    locationService.stopTracking();
    super.dispose();
    _channel?.sink.close();
  }


  void _filterReservations() {
    setState(() {
      List<dynamic> filteredList = acceptedReservations.where((reservation) {
        String username = reservation['User'] != null
            ? reservation['User']['username'] ?? ''
            : '';
        return username.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (reservation['phone_number'] != null &&
                reservation['phone_number']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())) ||
            (reservation['start_destination'] != null &&
                reservation['start_destination']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())) ||
            (reservation['end_destination'] != null &&
                reservation['end_destination']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())) ||
            (reservation['created_at'] != null &&
                reservation['created_at']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())) ||
            (reservation['recurrence_pattern'] != null &&
                reservation['recurrence_pattern']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())) ||
            (reservation['recurring_days'] != null &&
                reservation['recurring_days']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()));
      }).toList();

      filteredAcceptedReservations = filteredList;
    });
  }


  Future<void> fetchUserProfile() async {
    String? token = await storage.read(key: 'jwt_token');

    if (token == null) {
      setState(() {
        username = "No Token Found";
      });
      return;
    }

    final url = Uri.parse("http://$ip:3000/api/v1/users/Profile");

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          username = data['data']['username'];
        });
      } else {
        setState(() {
          username = "Failed to load";
        });
      }
    } catch (e) {
      setState(() {
        username = "Error";
      });
      print("Error fetching user profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Accepted Reservations",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFFF5CF24),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person,
              size: 30,
              color: Colors.black,
            ),
            onPressed: () {
              _showProfileOptions(context);
            },
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(
                Icons.calendar_today,
                size: 30,
                color: Colors.black,
              ),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      drawer: buildDrawer(context),
      endDrawer: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Drawer(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Select Date",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    eventLoader: _getEventsForDay,
                    startingDayOfWeek: StartingDayOfWeek.monday,
                    calendarStyle: const CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ReservationsByDatePage(selectedDate: selectedDay),
                        ),
                      );
                    },
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // شريط البحث
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search',
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.all(Radius.circular(12)),
                  ),
                  prefixIcon: Icon(Icons.search),
                  fillColor: Colors.white,
                  filled: true,
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                    _filterReservations();
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // قائمة الحجوزات
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAcceptedReservations.length,
              itemBuilder: (context, index) {
                var reservation = filteredAcceptedReservations[index];
                return _buildReservationCard(
                  reservation: reservation,
                  isPending: false,
                  onAction: () {
                    _showConfirmationDialog(
                      context: context,
                      title: 'Reject Reservation',
                      message:
                      'Are you sure you want to reject this reservation?',
                      onConfirm: () {
                        _cancelReservation(
                            reservation['reservation_id']);
                      },
                      confirmText: 'Cancel',
                    );
                  },
                );
              },
            ),
            if (filteredAcceptedReservations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child:
                Center(child: Text("No accepted reservations.")),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // ثابت على 1 للصفحة الجديدة
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DriverPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Pending Reservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'Accepted Reservations',
          ),
        ],
      ),
    );
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _reservationsByDate[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Widget _buildReservationCard({
    required Map<String, dynamic> reservation,
    required bool isPending,
    required VoidCallback onAction,
  }) {
    String username = reservation['User'] != null
        ? reservation['User']['username'] ?? 'Unknown'
        : 'Unknown';
    String phoneNumber = reservation['phone_number'] ?? 'N/A';

    return Card(
      color: Colors.white,
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان الحجز
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ride #${reservation['reservation_id']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Created At: ${reservation['created_at']}",
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 20, color: Colors.grey),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5CF24),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFCF3C2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.my_location_outlined,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Pick Up: ${reservation['start_destination']}",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5CF24),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFCF3C2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Drop Off: ${reservation['end_destination']}",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Description: ${reservation['description'] ?? 'No description provided.'}",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            Text(
              "Start: ${reservation['scheduled_date'] ?? 'لم يحدد '}",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            Text(
              "Start: ${reservation['scheduled_time'] ?? 'لم يحدد '}",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 8),
            if (reservation['is_recurring'] == true) ...[
              const Text(
                "Recurring: Yes",
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                "Pattern: ${reservation['recurrence_pattern'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                "Interval: ${reservation['recurrence_interval'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                "End Date: ${reservation['recurrence_end_date'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              if (reservation['recurring_days'] != null)
                Text(
                  "Days: ${reservation['recurring_days']}",
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              const SizedBox(height: 8),
            ],
            if (!isPending && reservation['User'] != null) ...[
              Text(
                "User: $username",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                "Phone: $phoneNumber",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending
                    ? const Color(0xFFF5CF24)
                    : const Color(0xFFF2643A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                isPending ? 'Accept' : 'Reject',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Header Section with Profile Info
          Container(
            height: MediaQuery.of(context).size.height * 0.30,
            decoration: const BoxDecoration(
              color: Color(0xFFF5CF24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Picture
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
                const SizedBox(height: 23),
                // User Information
                Text(
                  username,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Drawer List Items
          ListTile(
            leading: const Icon(Icons.map, size: 28),
            title: const Text('My Routes', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              _navigateToMyRoutes(context);
            },
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.contact_phone),
            title: const Text('Contact with Us'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.notifications, size: 28),
            title:
            const Text('Notifications', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              _navigateToNotifications(context);
            },
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.supervisor_account, size: 28),
            title: const Text('Line Manager',
                style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const LineManagerCall()),
              );
            },
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log out'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required String confirmText,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: Text(confirmText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProfileOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile Options'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.visibility),
                  title: const Text('View Profile'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfilePage()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToMyRoutes(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to My Routes...')),
    );
  }

  void _navigateToNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Notifications...')),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchAcceptedReservations() async {
    try {
      String? token = await storage.read(key: 'jwt_token');

      if (token != null) {
        final acceptedResponse = await http.get(
          Uri.parse(
              'http://$ip:3000/api/v1/reservation/driver/reservations'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (acceptedResponse.statusCode == 200) {
          final data = json.decode(acceptedResponse.body);
          setState(() {
            acceptedReservations = data['data'];
            filteredAcceptedReservations = List.from(acceptedReservations);
            isLoading = false;
            _mapReservationsByDate();
          });
        } else {
          setState(() {
            isLoading = false;
          });
          _showErrorDialog('Failed to load accepted reservations.');
        }

        _filterReservations();
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching accepted reservations: $error");
      _showErrorDialog('Error fetching accepted reservations.');
    }
  }

  // دالة لرسم الحجوزات حسب التاريخ
  void _mapReservationsByDate() {
    _reservationsByDate.clear();
    for (var reservation in acceptedReservations) {
      String dateStr = reservation['scheduled_date'];
      if (dateStr != null) {
        DateTime date = DateTime.parse(dateStr);
        DateTime key = DateTime(date.year, date.month, date.day);
        if (_reservationsByDate.containsKey(key)) {
          _reservationsByDate[key]!.add(reservation);
        } else {
          _reservationsByDate[key] = [reservation];
        }
      }
    }
  }

  Future<void> _cancelReservation(int reservationId) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.patch(
        Uri.parse(
            'http://$ip:3000/api/v1/reservation/cancel/$reservationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchAcceptedReservations();
        _showSuccessDialog('Reservation cancelled successfully');
      } else {
        _showErrorDialog('Error canceling reservation');
      }
    } catch (e) {
      _showErrorDialog('Error canceling reservation: $e');
    }
  }

  void _createNotification(String userId, String message) async {
    String? token = await storage.read(key: 'jwt_token');
    if (token == null) return;

    var notificationDetails = {
      'userId': userId,
      'message': message,
    };

    final response = await http.post(
      Uri.parse('http://$ip:3000/api/v1/notifications/$userId/driver'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(notificationDetails),
    );

    if (response.statusCode == 200) {
      print('Notification created successfully');
    } else {
      print('Failed to create notification: ${response.body}');
    }
  }
}


class ReservationsByDatePage extends StatefulWidget {
  final DateTime selectedDate;

  const ReservationsByDatePage({super.key, required this.selectedDate});

  @override
  _ReservationsByDatePageState createState() =>
      _ReservationsByDatePageState();
}

class _ReservationsByDatePageState extends State<ReservationsByDatePage> {
  List<dynamic> reservationsForDate = [];
  bool isLoading = true;
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchReservationsForDate();
  }

  Future<void> _fetchReservationsForDate() async {
    try {
      String? token = await storage.read(key: 'jwt_token');

      if (token != null) {
        final response = await http.get(
          Uri.parse(
              'http://$ip:3000/api/v1/reservation/driver/reservations'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          List<dynamic> allReservations = data['data'];
          setState(() {
            reservationsForDate = allReservations.where((reservation) {
              String dateStr = reservation['scheduled_date'];
              if (dateStr != null) {
                DateTime date = DateTime.parse(dateStr);
                return date.year == widget.selectedDate.year &&
                    date.month == widget.selectedDate.month &&
                    date.day == widget.selectedDate.day;
              }
              return false;
            }).toList();
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          _showErrorDialog('Failed to load reservations.');
        }
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching reservations: $error");
      _showErrorDialog('Error fetching reservations.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelReservation(int reservationId) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/reservation/cancel/$reservationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchReservationsForDate();
        _showSuccessDialog('Reservation cancelled successfully');
      } else {
        _showErrorDialog('Error canceling reservation');
      }
    } catch (e) {
      _showErrorDialog('Error canceling reservation: $e');
    }
  }

  Widget _buildReservationCard({
    required Map<String, dynamic> reservation,
    required bool isPending,
    required VoidCallback onAction,
  }) {
    String username = reservation['User'] != null
        ? reservation['User']['username'] ?? 'Unknown'
        : 'Unknown';
    String phoneNumber = reservation['phone_number'] ?? 'N/A';

    return Card(
      color: Colors.white,
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ride #${reservation['reservation_id']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Created At: ${reservation['created_at']}",
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 20, color: Colors.grey),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5CF24),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFCF3C2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.my_location_outlined,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Pick Up: ${reservation['start_destination']}",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // نقطة الوصول
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5CF24),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFCF3C2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Drop Off: ${reservation['end_destination']}",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Description: ${reservation['description'] ?? 'No description provided.'}",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            Text(
              "Start: ${reservation['scheduled_date'] ?? 'لم يحدد '}",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            Text(
              "Start: ${reservation['scheduled_time'] ?? 'لم يحدد '}",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 8),
            if (reservation['is_recurring'] == true) ...[
              const Text(
                "Recurring: Yes",
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                "Pattern: ${reservation['recurrence_pattern'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                "Interval: ${reservation['recurrence_interval'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                "End Date: ${reservation['recurrence_end_date'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              if (reservation['recurring_days'] != null)
                Text(
                  "Days: ${reservation['recurring_days']}",
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              const SizedBox(height: 8),
            ],
            if (!isPending && reservation['User'] != null) ...[
              Text(
                "User: $username",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                "Phone: $phoneNumber",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending
                    ? const Color(0xFFF5CF24)
                    : const Color(0xFFF2643A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                isPending ? 'Accept' : 'Reject',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String formattedDate =
        "${widget.selectedDate.year}-${widget.selectedDate.month}-${widget.selectedDate.day}";
    return Scaffold(
      appBar: AppBar(
        title: Text("Reservations on $formattedDate"),
        backgroundColor: const Color(0xFFF5CF24),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reservationsForDate.isEmpty
          ? const Center(child: Text("No reservations on this day."))
          : ListView.builder(
        itemCount: reservationsForDate.length,
        itemBuilder: (context, index) {
          var reservation = reservationsForDate[index];
          return _buildReservationCard(
            reservation: reservation,
            isPending: false,
            onAction: () {
              _showConfirmationDialog(
                context: context,
                title: 'Reject Reservation',
                message:
                'Are you sure you want to reject this reservation?',
                onConfirm: () {
                  _cancelReservation(
                      reservation['reservation_id']);
                },
                confirmText: 'Cancel',
              );
            },
          );
        },
      ),
    );
  }

  // دالة عرض نافذة التأكيد
  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required String confirmText,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: Text(confirmText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}