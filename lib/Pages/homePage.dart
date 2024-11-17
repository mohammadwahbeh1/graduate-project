import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './loginPage.dart';
import './terminalDetailsPage.dart';
import 'package:untitled/Pages/reservationPage.dart';
import 'bookingTaxi.dart';

class homePage extends StatefulWidget {
  @override
  _homePageState createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  List<Map<String, String>> terminals = [];
  bool isLoading = true;
  final storage = FlutterSecureStorage();
  List<String> notifications = [];
  int notificationCount = 0;  // Start notification count from 0

  void addNotification(String notification) {
    setState(() {
      notifications.add(notification);
      notificationCount++;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchTerminals();
    fetchNotifications();  // Fetch notifications when the page is initialized
  }

  // Fetch terminals
  Future<void> fetchTerminals() async {
    try {
      String? token = await storage.read(key: 'jwt_token');

      if (token != null) {
        final response = await http.get(
          Uri.parse('http://192.168.1.8:3000/api/v1/terminals'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body)['data'];

          setState(() {
            terminals = data
                .map((terminal) => {
              'terminal_id': terminal['terminal_id'].toString(),
              'terminal_name': terminal['terminal_name'].toString(),
            })
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          throw Exception('Failed to load terminals ${response.statusCode}');
        }
      } else {
        throw Exception('Token is null');
      }
    } catch (e) {
      print('Error occurred: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to fetch unread notifications
  Future<void> fetchNotifications() async {
    try {
      String? token = await storage.read(key: 'jwt_token');

      if (token != null) {
        final response = await http.get(
          Uri.parse('http://192.168.1.8:3000/api/v1/notifications'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body)['data'];

          setState(() {
            notifications = List<String>.from(data.map((notif) => notif['message']));
            notificationCount = notifications.length; // Update the notification count
          });
        } else {
          throw Exception('Failed to fetch notifications');
        }
      } else {
        throw Exception('Token is null');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  // Show notifications in a dialog
  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: notifications.isEmpty
                ? [const Text('No new notifications.')]
                : notifications.map((notification) {
              return ListTile(
                leading: const Icon(Icons.notification_important),
                title: Text(notification),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      notifications.remove(notification); // Remove the notification
                      notificationCount = notifications.length; // Update count
                    });
                    Navigator.pop(context); // Close dialog
                  },
                ),
              );
            }).toList(),
          ),
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

  // Show profile options in a dialog
  void _showProfileOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profile Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Build drawer menu
  Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: MediaQuery.of(context).size.height * 0.25,
            decoration: const BoxDecoration(
              color: Colors.yellow,
            ),
            child: const DrawerHeader(
              margin: EdgeInsets.all(0),
              padding: EdgeInsets.all(0),
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
                    'Taxi Service',
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
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('The Closest Point'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_phone),
            title: const Text('Contact with Us'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.book_online),
            title: const Text('Reservation'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReservationsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_available),
            title: const Text('Book A Taxi'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => BookTaxiPage()),
              );
            },
          ),
          const Divider(),
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

  // Build terminal card UI
  Widget buildCard(BuildContext context, String terminalName, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
          side: const BorderSide(
            color: Colors.grey,
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        elevation: 5,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              imagePath,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              child: Text(
                terminalName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Terminals",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.yellow,
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Image.asset(
                  'assets/notification.png',  // Custom notification icon
                  width: 30,
                  height: 30,
                ),
                onPressed: () {
                  _showNotifications(context); // Show notification list
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$notificationCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
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
          : Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: ListView.builder(
          itemCount: terminals.length,
          itemBuilder: (context, index) {
            return Column(
              children: [
                buildCard(
                  context,
                  terminals[index]['terminal_name']!,
                  'assets/terminal.jpg',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TerminalDetailsPage(
                          terminalId: terminals[index]['terminal_id']!,
                          terminalName: terminals[index]['terminal_name']!,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
