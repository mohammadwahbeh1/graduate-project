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
import 'package:flutter_rating_bar/flutter_rating_bar.dart'; // Import the rating bar package
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart'; // Import animations

const String ip = "192.168.1.12";

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _homePageState extends State<homePage> {
  List<Map<String, String>> terminals = [];
  bool _isHovered = false;
  bool isLoading = true;
  final storage = const FlutterSecureStorage();
  List<Map<String, dynamic>> notifications = [];
  int notificationCount = 0;
  WebSocketChannel? _channel;
  int _currentIndex = 0;
  String username="";
  final List<Widget> _pages = [
    Container(),  // Replace with your Home Page class
    ClosestPointPage(), // Replace with your Closest Point Page class
    const BookTaxiPage(), // Replace with your Book Taxi Page class
    const ReservationsPage(), // Replace with your Reservations Page class
  ];
// Theme state variable
  bool isDarkMode = false;

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

        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body)['data'];

          setState(() {
            terminals = data.map((terminal) {
              return {
                'terminal_id': terminal['terminal_id'].toString(),
                'terminal_name': terminal['terminal_name'].toString(),
                'average_rating': terminal['average_rating'] != null
                    ? double.parse(terminal['average_rating'].toString())
                    : 0.0,
                'total_vehicles': terminal['total_vehicles'].toString(),
                'latitude': terminal['latitude'],
                'longitude': terminal['longitude'],
                'user_id': terminal['user_id'].toString(),
                'image_path': terminal['image_path'] ?? 'assets/terminal.jpg', // Ensure image_path exists
              };
            }).toList();
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
              title: const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: notifications.isEmpty
                  ? const Text('No new notifications.')
                  : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        verticalOffset: 50.0,
                        child: FadeInAnimation(
                          child: GestureDetector(
                            onTap: () {
                              // Optionally handle tap on notification
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: notification['isRead']
                                    ? Colors.grey[100]
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.notifications,
                                    color: notification['isRead']
                                        ? Colors.grey
                                        : Colors.blue,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          notification['message'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: notification['isRead']
                                                ? FontWeight.normal
                                                : FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatTimestamp(notification['createdAt']),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () async {
                                                int notificationId = notification['id'];
                                                try {
                                                  await _handleMarkAsRead(notificationId);
                                                  setDialogState(() {});
                                                } catch (e) {
                                                  print('Error handling notification: $e');
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: const Size(50, 30),
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: Text(
                                                'Mark as Read',
                                                style: TextStyle(
                                                  color: Colors.green[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(String timestamp) {
    // Assuming timestamp is in ISO 8601 format
    DateTime dateTime = DateTime.parse(timestamp);
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
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
    Future.delayed(const Duration(seconds: 5), () {
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
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          // Header Section with Profile Info
          Container(
            height: MediaQuery.of(context).size.height * 0.30,
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : const Color(0xFFF6D533),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Profile Picture
                const CircleAvatar(
                  radius: 50,
                  backgroundImage:
                  AssetImage('assets/profile.jpg'), // Replace with your image path
                ),
                const SizedBox(height: 23),
                // User Information
                Text(
                  username,
                  style: GoogleFonts.lato(
                    textStyle: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Additional Information or Stats can be added here
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Drawer List Items
          AnimationLimiter(
            child: Column(
              children: List.generate(7, (index) { // Increased to 7 to include Dark Mode
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Column(
                        children: [
                          // Dark Mode Toggle
                          if (index == 6)
                            SwitchListTile(
                              secondary: Icon(
                                isDarkMode ? Icons.dark_mode : Icons.light_mode,
                                color: isDarkMode ? Colors.yellow : Colors.blue,
                              ),
                              title: Text(
                                'Dark Mode',
                                style: GoogleFonts.lato(
                                  textStyle: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              value: isDarkMode,
                              onChanged: (bool value) {
                                setState(() {
                                  isDarkMode = value;
                                });
                              },
                            )
                          else
                            ListTile(
                              leading: _getDrawerIcon(index),
                              title: Text(
                                _getDrawerTitle(index),
                                style: TextStyle(
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              onTap: () {
                                Navigator.pop(context);
                                _handleDrawerTap(index);
                              },
                            ),
                          if (index < 6) const Divider(),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Icon _getDrawerIcon(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.home, color: Colors.blue);
      case 1:
        return const Icon(Icons.location_on, color: Colors.blue);
      case 2:
        return const Icon(Icons.contact_phone, color: Colors.blue);
      case 3:
        return const Icon(Icons.book_online, color: Colors.blue);
      case 4:
        return const Icon(Icons.event_available, color: Colors.blue);
      case 5:
        return const Icon(Icons.logout, color: Colors.blue);
      default:
        return const Icon(Icons.help, color: Colors.blue);
    }
  }

  String _getDrawerTitle(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Closest Point';
      case 2:
        return 'Contact Us';
      case 3:
        return 'Reservation';
      case 4:
        return 'Book A Taxi';
      case 5:
        return 'Log out';
      case 6:
        return 'Dark Mode';
      default:
        return 'Unknown';
    }
  }

  void _handleDrawerTap(int index) {
    switch (index) {
      case 0:
        setState(() {
          _currentIndex = 0;
        });
        break;
      case 1:
        setState(() {
          _currentIndex = 1;
        });
        break;
      case 2:
      // Implement contact functionality
        _showContactUsDialog();
        break;
      case 3:
        setState(() {
          _currentIndex = 3;
        });
        break;
      case 4:
        setState(() {
          _currentIndex = 2;
        });
        break;
      case 5:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        break;
      case 6:
      // Handled by the SwitchListTile
        break;
      default:
        setState(() {
          _currentIndex = 0;
        });
    }
  }

  void _showContactUsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Us'),
          content: const Text(
              'For any inquiries, please email us at support@example.com or call us at (123) 456-7890.'),
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

  // Build Terminal Card with improved design and accurate rating
  Widget buildCard(
      BuildContext context,
      String terminalName,
      String imagePath, // This should be the asset path, e.g., 'assets/terminal.jpg'
      String terminalId,
      double averageRating,
      String totalVehicles) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TerminalDetailsPage(
              terminalId: terminalId,
              terminalName: terminalName,
            ),
          ),
        );
      },
      child: AnimationConfiguration.staggeredList(
        position: terminals.indexWhere((t) => t['terminal_id'] == terminalId),
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  side: const BorderSide(
                    color: Colors.grey,
                    width: 1,
                  ),
                ),
                elevation: 8,
                clipBehavior: Clip.antiAlias,
                color: isDarkMode ? Colors.grey[800] : Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Terminal Image
                    Stack(
                      children: [
                        // Use Image.asset for local images
                        Image.asset(
                          imagePath,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        // Overlay for Terminal Name and Review Button
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.transparent, Colors.black54],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Terminal Name
                                Expanded(
                                  child: Text(
                                    terminalName,
                                    style: GoogleFonts.lato(
                                      textStyle: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Review Button
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ReviewPage(
                                          terminalId: terminalId,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.transparent,
                                    side: const BorderSide(color: Colors.white, width: 1),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15, vertical: 8),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    "View Reviews",
                                    style: TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Terminal Details
                    Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Total Vehicles
                          Row(
                            children: [
                              const Icon(Icons.directions_car, color: Colors.blue),
                              const SizedBox(width: 5),
                              Text(
                                '$totalVehicles Vehicles',
                                style: GoogleFonts.lato(
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Rating
                          Row(
                            children: [
                              RatingBarIndicator(
                                rating: averageRating,
                                itemBuilder: (context, index) => const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                itemCount: 5,
                                itemSize: 24.0,
                                unratedColor: Colors.amber.withAlpha(50),
                                direction: Axis.horizontal,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                averageRating > 0
                                    ? averageRating.toStringAsFixed(1)
                                    : 'No ratings yet',
                                style: GoogleFonts.lato(
                                  textStyle: TextStyle(
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build Home Content with improved card
  Widget _buildHomeContent() {
    return isLoading
        ? Center(
      child: CircularProgressIndicator(
        color: isDarkMode ? Colors.white : Colors.blue,
      ),
    )
        : RefreshIndicator(
      onRefresh: fetchTerminals,
      child: AnimationLimiter(
        child: ListView.builder(
          itemCount: terminals.length,
          itemBuilder: (context, index) {
            return buildCard(
              context,
              terminals[index]['terminal_name'],
              terminals[index]['image_path'], // Ensure image_path is a valid asset path
              terminals[index]['terminal_id'],
              terminals[index]['average_rating'],
              terminals[index]['total_vehicles'],
            );
          },
        ),
      ),
    );
  }
  Widget _buildCustomBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
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
        selectedItemColor: isDarkMode ? Colors.white : Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.lato(fontSize: 12),
        unselectedLabelStyle: GoogleFonts.lato(fontSize: 12),
        items: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.location_on, 'Closest Point', 1),
          _buildNavItem(Icons.event_available, 'Book Taxi', 2),
          _buildNavItem(Icons.book_online, 'Reservations', 3),
        ],
      ),
    );
  }

  // Build individual Bottom Navigation Bar Item
  BottomNavigationBarItem _buildNavItem(
      IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: Stack(
        alignment: Alignment.center,
        children: [
          if (_currentIndex == index)
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blueGrey : const Color(0xFFF6D533), // Adjust color based on theme
                shape: BoxShape.circle,
              ),
            ),
          Icon(
            icon,
            size: 28,
            color: _currentIndex == index
                ? (isDarkMode ? Colors.white : Colors.black)
                : Colors.grey,
          ),
        ],
      ),
      label: label,
    );
  }

  // Get AppBar Title based on current index
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

  @override
  Widget build(BuildContext context) {
    // Define light and dark themes
    ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: const Color(0xFFFED300),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        color: Color(0xFFFED300),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        centerTitle: true,
      ),
    );

    ThemeData darkTheme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.grey[900],
      scaffoldBackgroundColor: Colors.grey[850],
      appBarTheme: AppBarTheme(
        color: Colors.grey[900],
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        centerTitle: true,
      ),
    );

    return Theme(
      data: isDarkMode ? darkTheme : lightTheme,
      child: Scaffold(
        appBar: _currentIndex != 2
            ? PreferredSize(
          preferredSize: const Size.fromHeight(60.0),
          child: AppBar(
            title: Text(
              _getAppBarTitle(),
              style: GoogleFonts.lato(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ),
            backgroundColor: isDarkMode
                ? darkTheme.appBarTheme.backgroundColor
                : lightTheme.appBarTheme.backgroundColor,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Stack(
                  children: [
                    IconButton(
                      icon: Image.asset(
                        'assets/notification.png',
                        width: 30,
                        height: 30,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        _showNotifications(context);
                      },
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Center(
                            child: Text(
                              '$notificationCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.person,
                  size: 30,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                onPressed: () {
                  _showProfileOptions(context);
                },
              ),
            ],
          ),
        )
            : null, // Hide AppBar on Book Taxi tab
        drawer: buildDrawer(context),
        body: _currentIndex == 0 ? _buildHomeContent() : _pages[_currentIndex],
        bottomNavigationBar: _buildCustomBottomNavigationBar(),
      ),
    );
  }
}
