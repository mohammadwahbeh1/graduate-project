import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled/Pages/profilePage.dart';
import 'LineMangerCall.dart';
import 'loginPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:untitled/Pages/Location Service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

const String ip = "192.168.1.12";

class DriverPage extends StatefulWidget {
  const DriverPage({super.key});

  @override
  _DriverPageState createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  List<dynamic> pendingReservations = [];
  List<dynamic> acceptedReservations = [];
  List<dynamic> filteredPendingReservations = [];
  List<dynamic> filteredAcceptedReservations = [];
  bool isPending = true;
  bool isLoading = true;
  String searchQuery = '';
  String username='';
  final locationService = LocationService();
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchReservations();
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

  // Function to filter reservations based on search query
  void _filterReservations() {
    setState(() {
      if (isPending) {
        filteredPendingReservations = pendingReservations
            .where((reservation) {
          return reservation['User']['username']
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
              reservation['phone_number']
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              reservation['start_destination']
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              reservation['end_destination']
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              reservation['created_at']
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());
        })
            .toList();
      } else {
        filteredAcceptedReservations = acceptedReservations
            .where((reservation) {
          return reservation['User']['username']
              .toLowerCase()
              .contains(searchQuery.toLowerCase()) ||
              reservation['phone_number']
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              reservation['start_destination']
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              reservation['end_destination']
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()) ||
              reservation['created_at']
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase());
        })
            .toList();
      }
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

    final url = Uri.parse("http://192.168.1.8:3000/api/v1/users/Profile");

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
        backgroundColor: Color(0xFFF5CF24),
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
      body:

      isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(

              decoration: const InputDecoration(

                hintText: 'Search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),                 ),
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
                if (isPending && filteredPendingReservations.isNotEmpty) ...[
                  for (var reservation in filteredPendingReservations)
                    Card(
                      color: Colors.white,
                      elevation: 8,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
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
                              "${reservation['created_at']}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const Divider(height: 20, color: Colors.grey),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5CF24),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xFFFCF3C2),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.my_location_outlined,
                                    color: Colors.black,
                                    size: 30, // icon size
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Pick Up: ${reservation['start_destination']}",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5CF24),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xFFFCF3C2),
                                      width: 2, // border width
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.black,
                                    size: 30, // icon size
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Drop Off: ${reservation['end_destination']}",
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Description: ${reservation['description'] ?? 'No description provided.'}",
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _showConfirmationDialog(
                                  context: context,
                                  title: 'Accept Reservation',
                                  message: 'Are you sure you want to accept this reservation?',
                                  onConfirm: () {
                                    _acceptReservation(
                                      reservation['reservation_id'],
                                      reservation['user_id'].toString(),
                                    );
                                  },
                                  confirmText: 'Accept',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFF5CF24),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                minimumSize: Size(double.infinity, 48),
                              ),
                              child: const Text(
                                'Accept',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                if (isPending && filteredPendingReservations.isEmpty)
                  const Center(child: Text("No pending reservations.")),

                if (!isPending && filteredAcceptedReservations.isNotEmpty) ...[
                  for (var reservation in filteredAcceptedReservations)
                    Card(
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
                              "${reservation['created_at']}",
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const Divider(height: 20, color: Colors.grey),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5CF24),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xFFFCF3C2),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.my_location_outlined,
                                    color: Colors.black,
                                    size: 30, // icon size
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Pick Up: ${reservation['start_destination']}",
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF5CF24),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xFFFCF3C2),
                                      width: 2, // border width
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.location_on_outlined,
                                    color: Colors.black,
                                    size: 30, // icon size
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Drop Off: ${reservation['end_destination']}",
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Description: ${reservation['description'] ?? 'No description provided.'}",
                              style: const TextStyle(fontSize: 14, color: Colors.black),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                _showConfirmationDialog(
                                  context: context,
                                  title: 'Reject Reservation',
                                  message: 'Are you sure you want to reject this reservation?',
                                  onConfirm: () {
                                    _cancelReservation(reservation['reservation_id']);
                                  },
                                  confirmText: 'Reject',
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFF2643A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                minimumSize: Size(double.infinity, 48),
                              ),
                              child: const Text(
                                'Reject',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black,fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                if (!isPending && filteredAcceptedReservations.isEmpty)
                  const Center(child: Text("No accepted reservations.")),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: isPending ? 0 : 1,
        onTap: (index) {
          setState(() {
            isPending = index == 0;
            isLoading = true;
            _fetchReservations();
          });
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
            child:  Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/profile.jpg'),
                ),
                SizedBox(height: 23),
                // User Information
                Text(
                  username,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,

                  ),
                ),


                // Stats Row

              ],
            ),
          ),
          SizedBox(height: 20),
          // Drawer List Items (your existing logic)
          ListTile(
            leading:  const Icon(Icons.map, size: 28),
            title: const Text('My Routes', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              _navigateToMyRoutes(context);
            },
          ),
          SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.contact_phone),
            title: const Text('Contact with Us'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.notifications, size: 28),
            title: const Text('Notifications', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              _navigateToNotifications(context);
            },
          ),
          SizedBox(height: 20),
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
          SizedBox(height: 20),
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
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                      MaterialPageRoute(builder: (context) => const ProfilePage()),
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
  // Success dialog
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

  // Error dialog
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
  // Fetch reservations from the API
  Future<void> _fetchReservations() async {
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
          });
        }

        final acceptedResponse = await http.get(
          Uri.parse('http://$ip:3000/api/v1/reservation/driver/reservations'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (acceptedResponse.statusCode == 200) {
          setState(() {
            acceptedReservations = json.decode(acceptedResponse.body)['data'];
            filteredAcceptedReservations = List.from(acceptedReservations);
            isLoading = false;
          });
        }
      }
    } catch (error) {

      setState(() {
        isLoading = false;
      });
    }
  }
  void _createNotification(String userId, String message) async {
    // Instead of sending via WebSocket, send to backend server
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
        final driverInfo = responseData['data']['driver'];
        String driverName = driverInfo['username'];
        String driverPhone = driverInfo['phone_number'];

        _createNotification(
          userId,
          'Your taxi has been booked successfully by $driverName. Contact: $driverPhone.',
        );

        _fetchReservations();
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


  // Cancel reservation
  Future<void> _cancelReservation(int reservationId) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/reservation/cancel/$reservationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchReservations();
        _showSuccessDialog('Reservation cancelled successfully');
      } else {
        _showErrorDialog('Error canceling reservation');
      }
    } catch (e) {
      _showErrorDialog('Error canceling reservation: $e');
    }
  }



}
