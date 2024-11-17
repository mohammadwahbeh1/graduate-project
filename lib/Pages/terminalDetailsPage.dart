import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'Splash_screen.dart';

class TerminalDetailsPage extends StatefulWidget {
  final String terminalName;
  final String terminalId;

  TerminalDetailsPage({required this.terminalName, required this.terminalId});

  @override
  _TerminalDetailsPageState createState() => _TerminalDetailsPageState();
}

class _TerminalDetailsPageState extends State<TerminalDetailsPage> {
  List<dynamic> lines = [];
  Map<String, int> previousVehicleCounts = {};
  bool isLoading = true;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    fetchLines();
    timer = Timer.periodic(const Duration(minutes: 1), (Timer t) {
      fetchLines();
    });
  }

  Future<void> fetchLines() async {
    String? token = await storage.read(key: 'jwt_token');
    final response = await http.get(
      Uri.parse('http://192.168.1.8:3000/api/v1/terminals/${widget.terminalId}/lines'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];

      // Compare current and previous vehicle counts
      bool hasChanged = false;
      for (var line in data) {
        String lineId = line['line_id'].toString();
        int currentCount = line['current_vehicles_count'];
        if (previousVehicleCounts[lineId] != currentCount) {
          hasChanged = true;
          previousVehicleCounts[lineId] = currentCount;  // Update the count
        }
      }

      if (hasChanged) {
        setState(() {
          lines = data;
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load lines');
    }
  }

  String formatDateTime(String dateTime) {
    final DateTime parsedDate = DateTime.parse(dateTime);
    final formattedTime = DateFormat('hh:mm a').format(parsedDate);
    final formattedDate = DateFormat('yyyy/MM/dd').format(parsedDate);
    return '$formattedTime, $formattedDate';
  }

  // Function to determine the line status
  String getLineStatus(int count) {
    return count > 10 ? "Available" : "Full";
  }

  // Widget to build each line card
  Widget buildLineCard(line) {
    bool isVehicleCountHigh = line['current_vehicles_count'] > 10;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: ListTile(
        title: Text(
          line['line_name'],
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 5),
            Text('Last updated: ${formatDateTime(line['last_updated'])}'),
            SizedBox(height: 5),
            Text('Vehicles: ${line['current_vehicles_count']}'),
            SizedBox(height: 5),
            Text(
              'Status: ${getLineStatus(line['current_vehicles_count'])}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isVehicleCountHigh ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        trailing: FlashingIndicator(isVehicleCountHigh: isVehicleCountHigh),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.terminalName} Terminal'),
        centerTitle: true,
        backgroundColor: Colors.yellow,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: lines.length,
        itemBuilder: (context, index) {
          return buildLineCard(lines[index]);
        },
      ),
    );
  }
}

// Widget for the flashing indicator
class FlashingIndicator extends StatefulWidget {
  final bool isVehicleCountHigh;

  FlashingIndicator({required this.isVehicleCountHigh});

  @override
  _FlashingIndicatorState createState() => _FlashingIndicatorState();
}

class _FlashingIndicatorState extends State<FlashingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 500))..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Icon(
        Icons.circle,
        color: widget.isVehicleCountHigh ? Colors.green : Colors.red,
        size: 24,
      ),
    );
  }
}
