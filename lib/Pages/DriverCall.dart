// call_driver_page.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'splash_screen.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'WebRTC.dart';

const String ip = "192.168.1.12";

class CallDriverPage extends StatefulWidget {
  const CallDriverPage({super.key});

  @override
  _CallDriverPageState createState() => _CallDriverPageState();
}

class _CallDriverPageState extends State<CallDriverPage> {
  List<Map<String, dynamic>>? drivers;
  List<Map<String, dynamic>>? filteredDrivers;
  List<bool> isRecordingList = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  String targetId = "";
  bool isMicActive = false;
  bool isSpeakerActive = false;
  late WebRTCSignaling signaling;
  late MediaStream localStream;
  bool isConnected = true;
  bool canReceiveCalls = true;

  @override
  void initState() {
    super.initState();
    _fetchDrivers();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.microphone.request();
    if (status.isGranted) {
      await _initializeWebRTC();
    } else if (status.isDenied || status.isPermanentlyDenied) {
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
      signaling = WebRTCSignaling(
          WebSocketChannel.connect(
              Uri.parse('ws://$ip:3000/ws/notifications?userId=$userId')
          ),
          ''
      );

      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      await signaling.initialize(
        onRemoteAudioStateChange: (bool isActive) {
          setState(() {
            isSpeakerActive = isActive && targetId.isNotEmpty;
          });
        },
      );

      signaling.setAvailability(true);
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
          isRecordingList = List<bool>.filled(drivers!.length, false);
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
    if (!isConnected || !canReceiveCalls) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calls are currently disabled')),
      );
      return;
    }

    setState(() {
      isMicActive = !isMicActive;
      isRecordingList[index] = isMicActive;
    });

    final driver = filteredDrivers![index];
    targetId = driver['user_id'].toString();

    if (isMicActive) {
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

  void _toggleAvailability() async {
    setState(() {
      isConnected = !isConnected;
      canReceiveCalls = !canReceiveCalls;
    });

    if (!isConnected) {
      if (isMicActive) {
        await signaling.stopCall();
        localStream.getAudioTracks().forEach((track) {
          track.enabled = false;
        });
      }

      setState(() {
        isRecordingList = List<bool>.filled(drivers?.length ?? 0, false);
        isMicActive = false;
        isSpeakerActive = false;
      });
      signaling.setAvailability(false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All calls disabled - Cannot make or receive calls')),
      );
    } else {
      await _initializeWebRTC();
      signaling.setAvailability(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calls enabled - Ready to make and receive calls')),
      );
    }
  }

  @override
  void dispose() {
    signaling.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Driver'),
        backgroundColor: Color(0xFFF5CF24),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: _toggleAvailability,
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isConnected ? Icons.phone_enabled : Icons.phone_disabled,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? 'Available' : 'Unavailable',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
              onChanged: _filterDrivers,
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
                        backgroundImage:
                        AssetImage('assets/commenter-1.jpg'),
                      ),
                      title: Text(
                        driver['username'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle:
                      Text('Phone: ${driver['phone_number']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => _toggleMic(index),
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
                                    : Colors.green,
                                borderRadius:
                                BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                Icons.mic,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          AnimatedContainer(
                            duration:
                            const Duration(milliseconds: 200),
                            width: isSpeakerActive &&
                                targetId ==
                                    driver['user_id'].toString()
                                ? 60
                                : 50,
                            height: isSpeakerActive &&
                                targetId ==
                                    driver['user_id'].toString()
                                ? 60
                                : 50,
                            decoration: BoxDecoration(
                              color: isSpeakerActive &&
                                  targetId ==
                                      driver['user_id'].toString()
                                  ? Colors.green
                                  : Colors.grey,
                              borderRadius:
                              BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.volume_up,
                              color: Colors.white,
                              size: 30,
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