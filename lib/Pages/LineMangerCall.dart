import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'Splash_screen.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'WebRTC.dart';

const String ip = "192.168.1.4";
String targetId = "";

class LineManagerCall extends StatefulWidget {
  const LineManagerCall({super.key});

  @override
  _LineManagerCallState createState() => _LineManagerCallState();
}

class _LineManagerCallState extends State<LineManagerCall> {
  Map<String, dynamic>? lineManager;
  bool isLoading = true;
  bool isMicActive = false;
  List<bool> isRecordingList = [];
  List<bool> isSpeakingList = [];
  bool isConnected = true;
  bool canReceiveCalls = true;
  late WebRTCSignaling signaling;
  late MediaStream localStream;

  @override
  void initState() {
    super.initState();
    _fetchLineManager();
    _requestPermissions();
    _initializeWebRTC();
  }

  Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.microphone.request();
    print("Microphone permission status: $status");
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
        "",
      );

      localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      await signaling.initialize();

      // Set initial availability status
      signaling.setAvailability(true);

    } catch (e) {
      _showErrorDialog('Failed to initialize WebRTC: $e');
    }
  }

  Future<void> _fetchLineManager() async {
    try {
      String? token = await storage.read(key: 'jwt_token');

      if (token == null || token.isEmpty) {
        _showErrorDialog('Token is missing or invalid');
        return;
      }

      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/line/drivers/line-manager'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        setState(() {
          lineManager = json.decode(response.body)['lineManager'];
          isLoading = false;

          if (lineManager != null) {
            isRecordingList = List<bool>.filled(1, false);
            isSpeakingList = List<bool>.filled(1, false);
          }
        });
      } else {
        _showErrorDialog('Failed to load line manager: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error fetching line manager: $e');
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

    if (isMicActive) {
      targetId = lineManager?['id']?.toString() ?? "";
      print("Target line manager ID: $targetId");
      await signaling.startCall(localStream, targetId);
      localStream.getAudioTracks().forEach((track) {
        track.enabled = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Call Started')),
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
      // Stop ongoing calls
      if (isMicActive) {
        await signaling.stopCall();
        localStream.getAudioTracks().forEach((track) {
          track.enabled = false;
        });
      }

      // Reset states
      setState(() {
        isRecordingList = List.filled(1, false);
        isMicActive = false;
      });

      // Update availability status
      signaling.setAvailability(false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All calls disabled - Cannot make or receive calls')),
      );
    } else {
      await _initializeWebRTC();

      // Update availability status
      signaling.setAvailability(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calls enabled - Ready to make and receive calls')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Line Manager'),
        backgroundColor: Colors.yellow,
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : lineManager == null
          ? const Center(child: Text('No Line Manager found.'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              radius: 30,
              backgroundImage: AssetImage('assets/commenter-1.jpg'),
            ),
            title: Text(
              lineManager!['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text('Phone: ${lineManager!['phone']}'),
            trailing: InkWell(
              onTap: () => _toggleMic(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isRecordingList[0] ? 60 : 50,
                height: isRecordingList[0] ? 60 : 50,
                decoration: BoxDecoration(
                  color: isRecordingList[0] ? Colors.red : Colors.green,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(
                  Icons.mic,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
