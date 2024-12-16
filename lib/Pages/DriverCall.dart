import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'Splash_screen.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'WebRTC.dart'; // Import your WebRTC signaling class

const String ip = "192.168.1.8";

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
  String targetId="";
  bool isMicActive = false;  // WebRTC
  late WebRTCSignaling signaling;
  late MediaStream localStream;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
    _requestPermissions();
    _initializeWebRTC();

  }

  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.microphone.request();
    print("Microphone permission status: $status");
    if (status.isGranted) {
      // Permissions are granted, initialize WebRTC
      await _initializeWebRTC();
    } else if (status.isDenied || status.isPermanentlyDenied) {
      // Handle denied permissions
      _showErrorDialog('Microphone permission is required to use this feature.');
    }
  }



  Future<void> _initializeWebRTC() async {
    try {
      String? userId = await storage.read(key: 'user_id');

      if (userId == null) {
        _showErrorDialog('User ID is missing.');
        return;
      }

      // Initialize with empty targetId - it will be set when making a call
      signaling = WebRTCSignaling(
          WebSocketChannel.connect(
              Uri.parse('ws://$ip:3000/ws/notifications?userId=$userId')
          ),
          ''  // Empty initial targetId
      );

      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      await signaling.initialize();

    } catch (e) {
      _showErrorDialog('Failed to initialize WebRTC: $e');
    }
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

  void _startListening(int index) async {
    final driver = filteredDrivers![index];
    targetId = driver['user_id'].toString();

    // Log the targetId
    print('Starting call to driver with ID: $targetId');

    setState(() {
      isRecordingList[index] = true;
    });

    // Pass the targetId when starting the call
    await signaling.startCall(localStream, targetId);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling driver ${driver['username']}...')),
    );
  }

  void _stopListening(int index) async {
    // Stop recording and end the call
    setState(() {
      isRecordingList[index] = false; // Stop recording for specific card
    });

    await signaling.handleMessage({
      'type': 'endCall',
      'targetId': targetId,

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
  void _toggleMic(int index) async {
    setState(() {
      isMicActive = !isMicActive;
      isRecordingList[index] = isMicActive;
    });

    final driver = filteredDrivers![index];
    targetId = driver['user_id'].toString();

    if (isMicActive) {
      print("Target driver ID: $targetId");
      await signaling.startCall(localStream, targetId);
      localStream.getAudioTracks().forEach((track) {
        track.enabled = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calling driver ${driver['username']}...')),
      );
    } else {
      localStream.getAudioTracks().forEach((track) {
        track.enabled = false;
      });
      await signaling.stopCall();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call Ended')),
      );
    }
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
                          InkWell(
                            onTap: () => _toggleMic(index),  // Changed from _toggleMic(0) to _toggleMic(index)
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: isRecordingList[index] ? 60 : 50,  // Changed from [0] to [index]
                              height: isRecordingList[index] ? 60 : 50,  // Changed from [0] to [index]
                              decoration: BoxDecoration(
                                color: isRecordingList[index] ? Colors.red : Colors.green,  // Changed from [0] to [index]
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.mic,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          )


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
