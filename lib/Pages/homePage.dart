import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:untitled/Pages/reviewPage.dart';
import './loginPage.dart';
import './terminalDetailsPage.dart';
import 'package:untitled/Pages/reservationPage.dart';
import 'bookingTaxi.dart';
import 'closestPointPage.dart';
import 'profilePage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

const String ip ="192.168.1.8";





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
  int notificationCount = 0;
  WebSocketChannel? _channel;
  int _currentIndex = 0;
  String username="";
  final List<Widget> _pages = [
    Container(),  // Replace with your Home Page class
    ClosestPointPage(), // Replace with your Closest Point Page class
    BookTaxiPage(), // Replace with your Book Taxi Page class
    ReservationsPage(), // Replace with your Reservations Page class
  ];

  void addNotification(Map<String, dynamic> notification) {
    setState(() {
      notifications.add(notification);
      notificationCount++;
    });
  }


  @override
  void initState() {
    super.initState();
    // Load data in parallel
    Future.wait([
    fetchNotifications(),
      fetchTerminals(),
      fetchUserProfile(),

    ]);
    _initializeWebSocket();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    fetchNotifications();
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
        print("Token: $token");
        print(response);
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

                                        await _handleMarkAsRead(notificationId);


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
  void _initializeWebSocket() async {
    String? token = await storage.read(key: 'jwt_token'); // Retrieve JWT token
    String? userId = await storage.read(key: 'user_id');

    if (token != null) {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://$ip:3000/ws/notifications?token=$token&userId=$userId'), // Add your WebSocket server URL
      );


      _channel!.stream.listen(
            (message) {
          final notification = jsonDecode(message);
          print('Received notification: $notification');
          setState(() {
            notifications.add({
              'id': notification['id'],
              'message': notification['message'],
              'isRead': false,
              'createdAt': notification['created_at'],
            });
            notificationCount++;
          });
        },
        onError: (error) {
          print("WebSocket error: $error");
          _reconnectWebSocket(); // Reconnect if there is an error
        },
        onDone: () {
          print("WebSocket connection closed.");
          _reconnectWebSocket(); // Reconnect when connection is closed
        },
      );
    }
  }
  void _reconnectWebSocket() {
    Future.delayed(Duration(seconds: 5), () {
      print("Reconnecting WebSocket...");
      _initializeWebSocket();
    });
  }
  @override
  void dispose() {
    _channel?.sink.close();  // Gracefully close the WebSocket connection
    super.dispose();
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
              color: Color(0xFFF6D533),
            ),
            child:  Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Picture
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/profile.jpg'), // Replace with your image path
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
            leading: const Icon(Icons.location_on),
            title: const Text('The Closest Point'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ClosestPointPage()),
              );
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
          SizedBox(height: 20),
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
                cacheWidth: 600,
                cacheHeight: 400,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),  // Slightly reduced blur intensity
                    child: Container(
                      height: 70,  // Adjusted height for better balance
                      alignment: Alignment.center,
                      color: Colors.black.withOpacity(0.4),  // Slightly lighter opacity
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Spread the items across the row
                        children: [
                          // Terminal name on the left
                          Padding(
                            padding: const EdgeInsets.only(left: 15),  // Added padding to the left for better spacing
                            child: Text(
                              terminalName,
                              style: const TextStyle(
                                fontSize: 20,  // Slightly smaller and thinner font size
                                fontWeight: FontWeight.w300,  // Lighter font weight for a refined look
                                color: Colors.white,
                                fontFamily: 'Roboto',  // Font set to 'Roboto', but can be replaced with any lightweight font
                              ),
                            ),
                          ),
                          // Review button on the right with slight offset
                          Padding(
                            padding: const EdgeInsets.only(right: 20),  // Added some space from the right edge
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReviewPage(terminalId: terminalId),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,  // Transparent background
                                side: BorderSide(color: Colors.white, width: 2),  // White border
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),  // Rounded corners for the button
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 10),  // Button padding
                              ),
                              child: const Text(
                                "View Reviews",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,  // White text color
                                  fontFamily: 'Roboto',  // Consistent font
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
      appBar: _currentIndex != 2 ? PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          title: Text(
            _getAppBarTitle(),
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: Color(0xFFFED300),
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
                _showProfileOptions(context);
              },
            ),
          ],
        ),
      ) : null, // Return null when Book Taxi tab is selected
      drawer: buildDrawer(context),
      body: _currentIndex == 0
          ? _buildHomeContent()
          : _pages[_currentIndex],
      bottomNavigationBar: _buildCustomBottomNavigationBar(),
    );

  }
  Widget _buildHomeContent() {
    return isLoading
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
    );
  }
  Widget _buildCustomBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.location_on, 'Closest Point', 1),
          _buildNavItem(Icons.event_available, 'Book Taxi', 2),
          _buildNavItem(Icons.book_online, 'Reservations', 3),
        ],
      ),
    );
  }
  BottomNavigationBarItem _buildNavItem(IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          if (_currentIndex == index)
            Container(
              height: 45,
              width: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFF6D533), // Yellow highlight color
                shape: BoxShape.circle,
              ),
            ),
          Icon(icon, size: 28),
        ],
      ),
      label: label,
    );
  }
  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return "Terminals"; // Title for Home tab
      case 1:
        return "Closest Point"; // Title for Closest Point tab
      case 2:
        return "Book Taxi"; // Title for Book Taxi tab
      case 3:
        return "Reservations"; // Title for Reservations tab
      default:
        return "Terminals"; // Default title
    }
  }
}