import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'Splash_screen.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'WebRTC.dart';

const String ip = "192.168.1.8";
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

  // States
  List<bool> isRecordingList = [];
  List<bool> isSpeakingList = [];

  // WebRTC
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
            Uri.parse('ws://$ip:3000/ws/notifications?userId=${userId}')),
        "",
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
      print("Response: ${response.body}");

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
        const SnackBar(content: Text('Recording Started')),
      );
    } else {
      localStream.getAudioTracks().forEach((track) {
        track.enabled = false;
      });
      await signaling.stopCall(); // Use stopCall instead of dispose
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording Stopped')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Line Manager'),
        backgroundColor: Colors.yellow,
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
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text('Phone: ${lineManager!['phone']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSpeakingList[0] ? 60 : 50,
                  height: isSpeakingList[0] ? 60 : 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                    isSpeakingList[0] ? Colors.blue : Colors.grey,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.volume_up,
                    color: Colors.white,
                    size: isSpeakingList[0] ? 30 : 25,
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () => _toggleMic(0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isRecordingList[0] ? 60 : 50,
                    height: isRecordingList[0] ? 60 : 50,
                    decoration: BoxDecoration(
                      color: isRecordingList[0]
                          ? Colors.red
                          : Colors.green,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.mic,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
