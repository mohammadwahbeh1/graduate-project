import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'Splash_screen.dart';

const String ip = "192.168.1.8";

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
      Uri.parse('http://$ip:3000/api/v1/terminals/${widget.terminalId}/lines'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body)['data'];
      bool hasChanged = false;

      for (var line in data) {
        String lineId = line['line_id'].toString();
        int currentCount = line['current_vehicles_count'];
        if (previousVehicleCounts[lineId] != currentCount) {
          hasChanged = true;
          previousVehicleCounts[lineId] = currentCount;
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Full',
        style: TextStyle(
          color: isAvailable ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildLineCard(dynamic line) {
    bool isVehicleCountHigh = line['current_vehicles_count'] > 10;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          line['line_name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      FlashingIndicator(isVehicleCountHigh: isVehicleCountHigh),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.time_to_leave,
                    'Vehicles Available',
                    '${line['current_vehicles_count']}',
                    isVehicleCountHigh ? Colors.green : Colors.red,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time,
                    'Last Updated',
                    formatDateTime(line['last_updated']),
                    Colors.grey[600]!,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(isVehicleCountHigh),
                ],
              ),
            ),
          ),
        ),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFFF5CF24),
        title: Text(
          '${widget.terminalName} Terminal',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.yellow[50]!,
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          padding: const EdgeInsets.only(top: 115, bottom: 20),
          itemCount: lines.length,

          itemBuilder: (context, index) {
            return buildLineCard(lines[index]);
          },

        ),
      ),
    );
  }
}

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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.5),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
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
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.isVehicleCountHigh ? Colors.green : Colors.red,
          boxShadow: [
            BoxShadow(
              color: (widget.isVehicleCountHigh ? Colors.green : Colors.red).withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
