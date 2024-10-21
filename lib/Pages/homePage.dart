import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './loginPage.dart';
import './terminalDetailsPage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class homePage extends StatefulWidget {
  @override
  _homePageState createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  List<Map<String, String>> terminals = []; // Update to store terminal names and ids
  bool isLoading = true;
  final storage = FlutterSecureStorage(); // Ensure you have the secure storage initialized

  @override
  void initState() {
    super.initState();
    fetchTerminals();
  }

  Future<void> fetchTerminals() async {
    try {
      String? token = await storage.read(key: 'jwt_token');

      if (token != null) {
        final response = await http.get(
          Uri.parse('http://192.168.1.3:3000/api/v1/terminals'),
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
          throw Exception('Failed to load terminals');
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
                  terminals[index]['terminal_name']!, // Pass terminal name
                  'assets/terminal.jpg',
                      () {
                    // Navigate to TerminalDetailsPage and pass both terminal_id and terminal_name
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
                MaterialPageRoute(builder: (context) => LoginPage()), // Navigate to login page
              );
            },
          ),
        ],
      ),
    );
  }

  Widget buildCard(BuildContext context, String terminalName, String imagePath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap, // Trigger on tap
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
                  shadows: <Shadow>[
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 8.0,
                      color: Color.fromARGB(125, 0, 0, 255),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void main() {
    runApp(MaterialApp(
      home: homePage(),
    ));
  }
}
