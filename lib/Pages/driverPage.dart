// driver_page.dart
import 'package:flutter/material.dart';
import 'package:untitled/Pages/Recommendationspage.dart';
import 'accepted_reservations_page.dart';
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

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  _DriverPageState createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  List<dynamic> pendingReservations = [];
  List<dynamic> filteredPendingReservations = [];
  bool isLoading = true;
  String searchQuery = '';
  String username = '';
  final locationService = LocationService();
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchPendingReservations();
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
      List<dynamic> filteredList = pendingReservations.where((reservation) {
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

      filteredPendingReservations = filteredList;
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
          "Driver Dashboard",
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
        ],
      ),
      drawer: buildDrawer(context),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
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
          Expanded(
            child: ListView(
              children: [
                if (filteredPendingReservations.isNotEmpty) ...[
                  for (var reservation in filteredPendingReservations)
                    _buildReservationCard(
                      reservation: reservation,
                      isPending: true,
                      onAction: () {
                        _showConfirmationDialog(
                          context: context,
                          title: 'Accept Reservation',
                          message:
                          'Are you sure you want to accept this reservation?',
                          onConfirm: () {
                            _acceptReservation(
                              reservation['reservation_id'],
                              reservation['user_id'].toString(),
                            );
                          },
                          confirmText: 'Accept',
                        );
                      },
                    ),
                ],
                if (filteredPendingReservations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text("No pending reservations.")),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AcceptedReservationsPage()),
            );
          }

         else if(index == 2){
            Navigator.push(
              context,
                MaterialPageRoute(builder: (context) => const Recommendationspage()),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.check),
            label: 'Recomindation',
          ),
        ],
      ),
    );
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
            // نقطة الانطلاق
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
                Expanded(
                  child: Text(
                    "Start_date: ${reservation['scheduled_date']}",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    "at: ${reservation['scheduled_time']}",
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // الوصف
            Text(
              "Description: ${reservation['description'] ?? 'No description provided.'}",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 8),
            // تفاصيل التكرار إذا كانت موجودة
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
            const SizedBox(height: 16),
            // زر الإجراء (قبول أو رفض)
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isPending ? const Color(0xFFF5CF24) : const Color(0xFFF2643A),
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
            title: const Text('Recommendationspage', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Recommendationspage()),
              );            },
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.supervisor_account, size: 28),
            title: const Text('Line Manager', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LineManagerCall()),
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
                  style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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

  // دالة عرض خيارات الملف الشخصي
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

  // دالة للتنقل إلى صفحة "My Routes"
  void _navigateToMyRoutes(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to My Routes...')),
    );
  }

  // دالة للتنقل إلى صفحة "Notifications"
  void _navigateToNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigating to Notifications...')),
    );
  }

  // دالة عرض رسالة النجاح
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

  // دالة عرض رسالة الخطأ
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

  Future<void> _fetchPendingReservations() async {
    try {
      String? token = await storage.read(key: 'jwt_token');

      if (token != null) {
        final pendingResponse = await http.get(
          Uri.parse('http://$ip:3000/api/v1/reservation/pending/all'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (pendingResponse.statusCode == 200) {
          setState(() {
            pendingReservations = json.decode(pendingResponse.body)['data'];
            filteredPendingReservations = List.from(pendingReservations);
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          _showErrorDialog('Failed to load pending reservations.');
        }

        // فلترة الحجوزات بعد جلبها
        _filterReservations();
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching pending reservations: $error");
      _showErrorDialog('Error fetching pending reservations.');
    }
  }

  Future<void> _acceptReservation(int reservationId, String userId) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/reservation/accept/$reservationId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print("the response is :  $response");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null) {
          final driverInfo = responseData['data'];
          String driverName = driverInfo['driver_id'].toString() ?? 'Unknown';
          String driverPhone = driverInfo['phone_number'].toString() ?? 'N/A';

          _createNotification(
            userId,
            'Your taxi has been booked successfully by $driverName. Contact: $driverPhone.',
          );
        } else {
          _showErrorDialog('Driver information not found.');
        }

        _fetchPendingReservations();
        _showSuccessDialog('Reservation accepted successfully');
        setState(() {
          filteredPendingReservations.removeWhere(
                (reservation) => reservation['reservation_id'] == reservationId,
          );
        });
      } else {
        _showErrorDialog('Error accepting reservation');
      }
    } catch (e) {
      _showErrorDialog('Error accepting reservation: $e');
    }
  }

  // دالة إنشاء الإشعارات
  void _createNotification(String userId, String message) async {
    // إرسال الإشعار إلى الخادم الخلفي
    String? token = await storage.read(key: 'jwt_token');
    if (token == null) return;

    var notificationDetails = {
      'userId': userId, // ID of the user receiving the notification
      'message': message, // The notification message
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
