import 'package:flutter/material.dart';
import 'package:untitled/Pages/profilePage.dart';
import 'LineMangerCall.dart';
import 'loginPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

const String ip = "192.168.1.8"; // Use your server IP address here

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
  bool isPending = true; // Flag to track which tab is selected
  bool isLoading = true; // Flag to show loading state
  String searchQuery = ''; // Store the search query


  @override
  void initState() {
    super.initState();
    _fetchReservations();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Driver Dashboard",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.yellow,
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
      drawer: buildDrawer(context, 'Driver'),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search bar for live search functionality
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  _filterReservations();
                });
              },
            ),
          ),
          // Show either Pending or Accepted reservations based on the selected tab
          Expanded(
            child: ListView(
              children: [
                // Pending Reservations List
                if (isPending && filteredPendingReservations.isNotEmpty) ...[
                  for (var reservation in filteredPendingReservations)
                    Card(
                      elevation: 8,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.blue.shade50,
                      child: ListTile(
                        leading: const CircleAvatar(
                          radius: 30,
                          backgroundImage:
                          AssetImage('assets/commenter-1.jpg'),
                        ),
                        title: Row(
                          children: [
                            Text(
                              "${reservation['User']['username']}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "(${reservation['reservation_type']})",
                              style:
                              const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    color: Colors.green, size: 18),
                                const SizedBox(width: 5),
                                Text("${reservation['phone_number']}"),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.blue, size: 18),
                                const SizedBox(width: 5),
                                Text(
                                    "From: ${reservation['start_destination']} -> To: ${reservation['end_destination']}"),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text("Created: ${reservation['created_at']}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green, size: 35),
                          onPressed: () {
                            _acceptReservation(reservation['reservation_id']);
                          },
                        ),
                      ),
                    ),
                ],
                // Show a message if no pending reservations
                if (isPending && filteredPendingReservations.isEmpty)
                  const Center(child: Text("No pending reservations.")),

                // Accepted Reservations List
                if (!isPending && filteredAcceptedReservations.isNotEmpty) ...[
                  for (var reservation in filteredAcceptedReservations)
                    Card(
                      elevation: 8,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading: const CircleAvatar(
                          radius: 30,
                          backgroundImage:
                          AssetImage('assets/commenter-1.jpg'),
                        ),
                        title: Row(
                          children: [
                            Text(
                              "${reservation['User'] != null ? reservation['User']['username'] : 'Unknown User'}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "(${reservation['reservation_type']})",
                              style:
                              const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    color: Colors.green, size: 18),
                                const SizedBox(width: 5),
                                Text("${reservation['phone_number']}"),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.blue, size: 18),
                                const SizedBox(width: 5),
                                Text(
                                    "From: ${reservation['start_destination']} -> To: ${reservation['end_destination']}"),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text("Created: ${reservation['created_at']}"),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel,
                              color: Colors.red, size: 35),
                          onPressed: () {
                            _cancelReservation(reservation['reservation_id']);
                          },
                        ),
                      ),
                    ),
                ],
                // Show a message if no accepted reservations
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
            _fetchReservations(); // Fetch new data when tab is switched
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



  Widget buildDrawer(BuildContext context, String role) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Drawer Header Section
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: const BoxDecoration(
              color: Colors.yellow,
            ),
            child: const DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 80,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Driver Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Drawer Menu Items Section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.map, size: 28),
                  title: const Text('My Routes', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToMyRoutes(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications, size: 28),
                  title: const Text('Notifications', style: TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToNotifications(context);
                  },
                ),
                const Divider(thickness: 1),
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
              ],
            ),
          ),

          // Logout Section
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: ListTile(
              leading: const Icon(Icons.logout, size: 28),
              title: const Text('Log Out', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ),
        ],
      ),
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
      String? token = await storage.read(key: 'jwt_token'); // Assuming storage is used for JWT token

      if (token != null) {
        final pendingResponse = await http.get(
          Uri.parse('http://$ip:3000/api/v1/reservation/pending/all'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (pendingResponse.statusCode == 200) {
          setState(() {
            pendingReservations = json.decode(pendingResponse.body)['data']; // Adjusted for proper data extraction
            filteredPendingReservations = List.from(pendingReservations); // Set initial filtered data
          });
        }

        final acceptedResponse = await http.get(
          Uri.parse('http://$ip:3000/api/v1/reservation/driver/reservations'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (acceptedResponse.statusCode == 200) {
          setState(() {
            acceptedReservations = json.decode(acceptedResponse.body)['data']; // Adjusted for proper data extraction
            filteredAcceptedReservations = List.from(acceptedReservations); // Set initial filtered data
            isLoading = false;
          });
        }
      }
    } catch (error) {
      // Handle error properly
      setState(() {
        isLoading = false;
      });
    }
  }
  void _createNotification(String message) async {
    String? token = await storage.read(key: 'jwt_token');
    if (token == null) return;

    var notificationDetails = {'message': message};

    final response = await http.post(
      Uri.parse('http:$ip:3000/api/v1/notifications'),
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
  // Accept reservation
  Future<void> _acceptReservation(int reservationId) async {
    try {
      String? token = await storage.read(key: 'jwt_token'); // Assuming storage is used for JWT token
      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/reservation/accept/$reservationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchReservations(); // Re-fetch reservations after acceptance
        _showSuccessDialog('Reservation accepted successfully');


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
      String? token = await storage.read(key: 'jwt_token'); // Assuming storage is used for JWT token
      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/reservation/cancel/$reservationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        _fetchReservations(); // Re-fetch reservations after cancellation
        _showSuccessDialog('Reservation cancelled successfully');
      } else {
        _showErrorDialog('Error canceling reservation');
      }
    } catch (e) {
      _showErrorDialog('Error canceling reservation: $e');
    }
  }



}
