import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'Splash_screen.dart';

const String ip = "192.168.1.18";

class LineManagerCall extends StatefulWidget {
  const LineManagerCall({super.key});

  @override
  _LineManagerCallState createState() => _LineManagerCallState();
}

class _LineManagerCallState extends State<LineManagerCall> {
  Map<String, dynamic>? lineManager;
  bool isLoading = true;

  // قوائم للحالات
  List<bool> isRecordingList = [];
  List<bool> isSpeakingList = [];

  @override
  void initState() {
    super.initState();
    _fetchLineManager();
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

          // إعداد القوائم لتتطابق مع عدد العناصر
          if (lineManager != null) {
            isRecordingList = List<bool>.filled(1, false); // عنصر واحد فقط في هذا السيناريو
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

  void _startListening(int index) {
    setState(() {
      isRecordingList[index] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recording...')),
    );
  }

  void _stopListening(int index) {
    setState(() {
      isRecordingList[index] = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stopped Recording')),
    );
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
              backgroundImage: AssetImage(
                  'assets/commenter-1.jpg'), // Replace with actual image path
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
                    color: isSpeakingList[0]
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
                    size: isSpeakingList[0] ? 30 : 25,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onLongPressStart: (_) {
                    _startListening(0); // Start recording when long press starts
                  },
                  onLongPressEnd: (_) {
                    _stopListening(0); // Stop recording when long press ends
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isRecordingList[0] ? 60 : 50,
                    height: isRecordingList[0] ? 60 : 50,
                    decoration: BoxDecoration(
                      color: isRecordingList[0]
                          ? Colors.red
                          : Colors.green, // Green when idle, red when recording
                      borderRadius: BorderRadius.circular(50),
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
      ),
    );
  }
}
