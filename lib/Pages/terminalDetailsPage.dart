import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String ip = "192.168.1.8";

const storage = FlutterSecureStorage();

class TerminalDetailsPage extends StatefulWidget {
  final String terminalName;
  final String terminalId;

  const TerminalDetailsPage({
    Key? key,
    required this.terminalName,
    required this.terminalId,
  }) : super(key: key);

  @override
  _TerminalDetailsPageState createState() => _TerminalDetailsPageState();
}

class _TerminalDetailsPageState extends State<TerminalDetailsPage> {
  List<dynamic> lines = [];
  List<dynamic> filteredLines = [];
  Map<String, int> previousVehicleCounts = {};
  bool isLoading = true;
  Timer? timer;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchLines();
    timer = Timer.periodic(const Duration(minutes: 1), (Timer t) {
      fetchLines();
    });
    searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    timer?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    filterLines();
  }

  Future<int?> getETA(
      double originLat, double originLng, double destLat, double destLng) async {
    const String apiKey = 'AIzaSyBUyuByMAu02NKWp76MsQ1xRWHKb2FsWEg';
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$originLat,$originLng&destination=$destLat,$destLng&key=$apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if ((data['routes'] as List).isNotEmpty) {
        final route = data['routes'][0];
        final leg = route['legs'][0];
        final duration = leg['duration']['value'];
        return (duration / 60).round();
      }
    }
    return null;
  }

  Future<void> fetchLines() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.get(
        Uri.parse('http://$ip:3000/api/v1/terminals/${widget.terminalId}/lineVehicle/locations'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody['data'] != null && responseBody['data'] is List) {
          final data = responseBody['data'];
          bool hasChanged = false;

          for (var line in data) {
            String lineId = line['line_id'].toString();
            int currentCount =
            line['vehicles'] != null ? (line['vehicles'] as List).length : 0;

            if (previousVehicleCounts[lineId] != currentCount) {
              hasChanged = true;
              previousVehicleCounts[lineId] = currentCount;
            }

            List<dynamic> vehicles = line['vehicles'] ?? [];
            List<Future<int?>> etaFutures = [];

            for (var vehicle in vehicles) {
              double vehicleLat =
                  vehicle['vehicle_lat']?.toDouble() ?? 0.0;
              double vehicleLng =
                  vehicle['vehicle_long']?.toDouble() ?? 0.0;
              double lineLat = (line['line_lat'] != null)
                  ? double.tryParse(line['line_lat'].toString()) ?? 0.0
                  : 0.0;
              double lineLng = (line['line_long'] != null)
                  ? double.tryParse(line['line_long'].toString()) ?? 0.0
                  : 0.0;
              etaFutures.add(getETA(vehicleLat, vehicleLng, lineLat, lineLng));
            }

            List<int?> etas = await Future.wait(etaFutures);
            for (int i = 0; i < vehicles.length; i++) {
              vehicles[i]['eta'] = etas[i];
            }

            vehicles.sort((a, b) {
              if (a['eta'] == null) return 1;
              if (b['eta'] == null) return -1;
              return a['eta']!.compareTo(b['eta']!);
            });

            if (vehicles.isNotEmpty) {
              line['next_eta'] = vehicles.first['eta'];
            } else {
              line['next_eta'] = null;
            }

          }

          if (hasChanged) {
            setState(() {
              lines = data;
              isLoading = false;
              filterLines();
            });
          }
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
        throw Exception('Failed to load lines: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching lines: $e');
    }
  }

  void filterLines() {
    String query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredLines = lines;
      } else {
        filteredLines = lines.where((line) {
          String lineName = line['line_name']?.toString().toLowerCase() ?? '';
          return lineName.contains(query);
        }).toList();
      }
    });
  }

  String formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) {
      return 'N/A';
    }
    try {
      final DateTime parsedDate = DateTime.parse(dateTime).toLocal();
      final formattedTime = DateFormat('hh:mm a').format(parsedDate);
      final formattedDate = DateFormat('yyyy/MM/dd').format(parsedDate);
      return '$formattedTime, $formattedDate';
    } catch (e) {
      print('Error parsing date: $e');
      return 'Invalid Date';
    }
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color color) {
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

  Widget _buildStatusBadge(int vehicleCount) {
    String statusText;
    Color color;

    if (vehicleCount <= 2) {
      statusText = 'Critical';
      color = Colors.red;
    } else if (vehicleCount >= 3 && vehicleCount <= 5) {
      statusText = 'Moderate';
      color = Colors.orange;
    } else {
      statusText = 'Excellent';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget buildLineCard(dynamic line) {
    int currentCount =
    line['vehicles'] != null ? (line['vehicles'] as List).length : 0;
    String lineName = line['line_name'] ?? 'Unnamed Line';
    String? lastUpdatedRaw = line['last_updated'];
    String lastUpdated = formatDateTime(lastUpdatedRaw);
    int? nextEta = line['next_eta'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.blue[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
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
                          lineName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      FlashingIndicator(vehicleCount: currentCount),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.directions_car,
                    'Number of Vehicles',
                    '$currentCount',
                    currentCount <= 2
                        ? Colors.red
                        : (currentCount >= 3 && currentCount <= 5
                        ? Colors.orange
                        : Colors.green),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time,
                    'Last Updated',
                    lastUpdated,
                    Colors.grey[600]!,
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(currentCount),
                  const SizedBox(height: 8),
                  // عرض ETA
                  if (nextEta != null)
                    Row(
                      children: [
                        const Icon(Icons.timer,
                            size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'The next car will arrive in $nextEta minutes',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.timer_off,
                            size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'No ETA data',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Search for a line...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                searchController.clear();
                FocusScope.of(context).unfocus();
              },
            )
                : null,
            filled: true,
            fillColor: Colors.transparent,
            contentPadding:
            const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5CF24),
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
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue[50]!,
                Colors.white,
              ],
            ),
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: filteredLines.isEmpty
                    ? const Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(
                        fontSize: 18, color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  padding:
                  const EdgeInsets.only(top: 0, bottom: 20),
                  itemCount: filteredLines.length,
                  itemBuilder: (context, index) {
                    return buildLineCard(filteredLines[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlashingIndicator extends StatefulWidget {
  final int vehicleCount;

  const FlashingIndicator({required this.vehicleCount, Key? key})
      : super(key: key);

  @override
  _FlashingIndicatorState createState() => _FlashingIndicatorState();
}

class _FlashingIndicatorState extends State<FlashingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  Color indicatorColor = Colors.green;

  @override
  void initState() {
    super.initState();

    if (widget.vehicleCount <= 2) {
      indicatorColor = Colors.red;
    } else if (widget.vehicleCount >= 3 && widget.vehicleCount <= 5) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Colors.green;
    }

    if (widget.vehicleCount <= 2) {
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
  }

  @override
  void didUpdateWidget(covariant FlashingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vehicleCount != widget.vehicleCount) {
      setState(() {
        if (widget.vehicleCount <= 2) {
          indicatorColor = Colors.red;
          if (_controller.isAnimating == false) {
            _controller.repeat(reverse: true);
          }
        } else if (widget.vehicleCount >= 3 && widget.vehicleCount <= 5) {
          indicatorColor = Colors.orange;
          if (_controller.isAnimating) {
            _controller.stop();
          }
        } else {
          indicatorColor = Colors.green;
          if (_controller.isAnimating) {
            _controller.stop();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.vehicleCount <= 2) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.vehicleCount <= 2) {
      return ScaleTransition(
        scale: _animation,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: indicatorColor,
            boxShadow: [
              BoxShadow(
                color: indicatorColor.withAlpha(3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: indicatorColor,
          boxShadow: [
            BoxShadow(
              color: indicatorColor.withAlpha(3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      );
    }
  }
}
