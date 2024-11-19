import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:untitled/Pages/reviewPage.dart';
import './loginPage.dart';
import './terminalDetailsPage.dart';
import 'package:untitled/Pages/reservationPage.dart';
import 'bookingTaxi.dart';
const String ip ="192.168.1.172";


class homePage extends StatefulWidget {
  @override
  _homePageState createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  List<Map<String, String>> terminals = [];
  bool _isHovered = false;
  bool isLoading = true;
  final storage = FlutterSecureStorage();
  List<Map<String, dynamic>> notifications = [];
  int notificationCount = 0; // Start notification count from 0

  void addNotification(Map<String, dynamic> notification) {
    setState(() {
      notifications.add(notification);
      notificationCount++;
    });
  }


  @override
  void initState() {
    super.initState();
    fetchTerminals();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchNotifications(); // Fetch notifications whenever the widget is reloaded
  }

  // Fetch terminals
  Future<void> fetchTerminals() async {
    try {
      String? token = await storage.read(key: 'jwt_token');

      if (token != null) {
        final response = await http.get(
          Uri.parse('http://$ip:3000/api/v1/terminals'),
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
          Uri.parse('http://$ip:3000/api/v1/notifications'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body)['data'];

          setState(() {
            notifications = data.map((notif) {
              return {
                'id': notif['notification_id'],
                'message': notif['message'],
                'isRead': notif['is_read'],
                'createdAt': notif['created_at'],
              };
            }).toList();
            notificationCount = notifications.length;
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

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token != null) {
        final response = await http.patch(
          Uri.parse('http://$ip:3000/api/v1/notifications/$notificationId'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        print('notiiii ');
        if (response.statusCode == 200) {
          print('notiiii senddddd');

          setState(() {
            notifications.removeWhere((notif) => notif == notificationId); // Remove notification from the list
            notificationCount--; // Update the notification count
          });
        } else {
          print('Failed to mark notification as read: ${response.statusCode}');
        }
      } else {
        throw Exception('Token is null');
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
  Future<void> _handleMarkAsRead(int notificationId) async {
    try {
      // Call the API to mark the notification as read
      await markNotificationAsRead(notificationId); // Replace with actual API implementation
      setState(() {
        notifications.removeWhere((notif) => notif['id'] == notificationId); // Remove globally
        notificationCount = notifications.length; // Update global count
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _removeNotification(int notificationId) {
    setState(() {
      notifications.removeWhere((notification) => notification['id'] == notificationId);
      notificationCount = notifications.length; // Update the count
    });
  }

  void _showNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Notifications'),
              content: notifications.isEmpty
                  ? const Text('No new notifications.')
                  : SizedBox(
                width: double.maxFinite, // Ensure ListView takes up the full width
                child: ListView(
                  shrinkWrap: true, // Makes ListView only take the space it needs
                  children: notifications.map((notification) {
                    return ListTile(
                      leading: const Icon(Icons.notification_important),
                      title: Text(notification['message']), // Access and display the message
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MouseRegion(
                            onEnter: (_) {
                              setState(() {
                                _isHovered = true;
                              });
                            },
                            onExit: (_) {
                              setState(() {
                                _isHovered = false;
                              });
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MouseRegion(
                                  onEnter: (_) {
                                    setState(() {
                                      _isHovered = true;
                                    });
                                  },
                                  onExit: (_) {
                                    setState(() {
                                      _isHovered = false;
                                    });
                                  },
                                  child: IconButton(
                                    icon: const Icon(Icons.check, color: Colors.grey),
                                    onPressed: () async {
                                      int notificationId = notification['id']; // Get notification ID

                                      try {
                                        // Call _handleMarkAsRead and update the state
                                        await _handleMarkAsRead(notificationId);

                                        // Update state inside the dialog to reflect changes immediately
                                        setDialogState(() {
                                          notifications.removeWhere((notif) => notif['id'] == notificationId);
                                        });
                                      } catch (e) {
                                        print('Error handling notification: $e');
                                      }
                                    },
                                  ),
                                ),
                                if (_isHovered)
                                  const Text(
                                    'Mark as Read',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
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
          content: SingleChildScrollView( // Wrap the content in a SingleChildScrollView
            child: ListBody( // Use ListBody instead of Column for more efficient layout
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
  Widget buildCard(BuildContext context, String terminalName, String imagePath, String terminalId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TerminalDetailsPage(terminalId: terminalId, terminalName: terminalName),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 20, right: 5, left: 5),
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
              Positioned(
                bottom: 10,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReviewPage(terminalId: terminalId),
                      ),
                    );
                  },
                  child: Text("View Reviews"),
                ),
              ),
            ],
          ),
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
                  'assets/notification.png',
                  width: 30,
                  height: 30,
                ),
                onPressed: () {
                  _showNotifications(context);
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
              _showProfileOptions(context); // Show profile options
            },
          ),
        ],
      ),
      drawer: buildDrawer(context),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: terminals.length,
        itemBuilder: (context, index) {
          return buildCard(
            context,
            terminals[index]['terminal_name']!,
            'assets/terminal.jpg',
            terminals[index]['terminal_id']!,
          );
        },
      ),
    );
  } }
