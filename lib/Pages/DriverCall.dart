import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Splash_screen.dart';

const String ip = "192.168.1.4";

class CallDriverPage extends StatefulWidget {
  const CallDriverPage({super.key});

  @override
  _CallDriverPageState createState() => _CallDriverPageState();
}

class _CallDriverPageState extends State<CallDriverPage> {
  List<Map<String, dynamic>>? drivers;
  List<Map<String, dynamic>>? filteredDrivers; // List for filtered drivers
  List<bool> isRecordingList = []; // Track recording for each card
  List<bool> isSpeakingList = []; // Track speaking for each card
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
  }

  Future<void> _fetchDrivers() async {
    try {
      String? token = await storage.read(key: 'jwt_token');

      if (token == null || token.isEmpty) {
        _showErrorDialog('Token is missing or invalid');
        return;
      }

      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/line/line-manager/drivers'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          drivers = List<Map<String, dynamic>>.from(data['drivers']);
          filteredDrivers = List<Map<String, dynamic>>.from(drivers!);
          isRecordingList = List.filled(drivers!.length, false);
          isSpeakingList = List.filled(drivers!.length, false);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        _showErrorDialog('Failed to load drivers: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error fetching drivers: $e');
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

  void _startListening(int index) {
    setState(() {
      isRecordingList[index] = true; // Start recording for specific card
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recording...')),
    );
  }

  void _stopListening(int index) {
    setState(() {
      isRecordingList[index] = false; // Stop recording for specific card
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stopped Recording')),
    );
  }

  void _filterDrivers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredDrivers = drivers;
      } else {
        filteredDrivers = drivers!.where((driver) {
          return driver['username']
              .toLowerCase()
              .contains(query.toLowerCase()) ||
              driver['phone_number'].contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Driver'),
        backgroundColor:Color(0xFFF5CF24),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search by username or phone',
                border: OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _filterDrivers, // Call filter function
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredDrivers == null || filteredDrivers!.isEmpty
                ? const Center(child: Text('No drivers found.'))
                : ListView.builder(
              itemCount: filteredDrivers!.length,
              itemBuilder: (context, index) {
                final driver = filteredDrivers![index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        radius: 30,
                        backgroundImage: AssetImage(
                            'assets/commenter-1.jpg'), // Replace with actual image
                      ),
                      title: Text(
                        driver['username'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                      subtitle: Text(
                          'Phone: ${driver['phone_number']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 200),
                            width: isSpeakingList[index] ? 60 : 50,
                            height: isSpeakingList[index] ? 60 : 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSpeakingList[index]
                                  ? Colors.blue
                                  : Colors.grey, // Blue when receiving sound
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.volume_up, // Speaker icon
                              color: Colors.white,
                              size: isSpeakingList[index] ? 30 : 25,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onLongPressStart: (_) {
                              _startListening(index); // Start recording for this card
                            },
                            onLongPressEnd: (_) {
                              _stopListening(index); // Stop recording for this card
                            },
                            child: AnimatedContainer(
                              duration:
                              const Duration(milliseconds: 200),
                              width:
                              isRecordingList[index] ? 60 : 50,
                              height:
                              isRecordingList[index] ? 60 : 50,
                              decoration: BoxDecoration(
                                color: isRecordingList[index]
                                    ? Colors.red
                                    : Colors.green, // Green when idle, red when recording
                                borderRadius:
                                BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.mic, // Microphone icon
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
