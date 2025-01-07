import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

const String ip = "192.168.1.12";
final storage = FlutterSecureStorage();

class StatisticsPage extends StatefulWidget {
  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    String? token = await storage.read(key: 'jwt_token');

    if (token != null) {
      try {
        final responses = await Future.wait([
          http.get(Uri.parse('http://$ip:3000/api/v1/admin/users/statistics'), headers: {'Authorization': 'Bearer $token'}),
          http.get(Uri.parse('http://$ip:3000/api/v1/admin/vehicles/statistics'), headers: {'Authorization': 'Bearer $token'}),
          http.get(Uri.parse('http://$ip:3000/api/v1/admin/lines/statistics'), headers: {'Authorization': 'Bearer $token'}),
          http.get(Uri.parse('http://$ip:3000/api/v1/admin/reservations/statistics'), headers: {'Authorization': 'Bearer $token'}),
          http.get(Uri.parse('http://$ip:3000/api/v1/admin/reviews/statistics'), headers: {'Authorization': 'Bearer $token'}),
        ]);

        if (responses.every((response) => response.statusCode == 200)) {
          setState(() {
            _statistics = {
              'users': json.decode(responses[0].body),
              'vehicles': json.decode(responses[1].body),
              'lines': json.decode(responses[2].body),
              'reservations': json.decode(responses[3].body),
              'reviews': json.decode(responses[4].body),
            };
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load statistics')));
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('JWT token not found')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueAccent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWeb = constraints.maxWidth > 800; // Detects if on a larger screen
          return _isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
            padding: isWeb
                ? const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0)
                : const EdgeInsets.all(16.0),
            child: isWeb
                ? Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionTitle('User Statistics'),
                              _buildUserStats(),
                              Divider(thickness: 2),
                              _buildSectionTitle('Vehicle Statistics'),
                              _buildVehicleStats(),
                              Divider(thickness: 2),
                              _buildSectionTitle('Reservation Statistics'),
                              _buildReservationStats(),
                              Divider(thickness: 2),
                              _buildSectionTitle('Review Statistics'),
                              _buildReviewStats(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 20),
                // Additional widgets can be added here for web-only features
              ],
            )
                : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('User Statistics'),
                  _buildUserStats(),
                  Divider(thickness: 2),
                  _buildSectionTitle('Vehicle Statistics'),
                  _buildVehicleStats(),
                  Divider(thickness: 2),
                  _buildSectionTitle('Reservation Statistics'),
                  _buildReservationStats(),
                  Divider(thickness: 2),
                  _buildSectionTitle('Review Statistics'),
                  _buildReviewStats(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.blueAccent,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    );
  }

  Widget _buildUserStats() {
    var roleDistribution = _statistics['users']?['roleDistribution'] ?? [];
    var genderDistribution = _statistics['users']?['genderDistribution'] ?? [];
    var ageGroups = _statistics['users']?['ageGroups'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (roleDistribution.isNotEmpty)
          _buildBarChart(roleDistribution, 'Role Distribution'),
        if (genderDistribution.isNotEmpty)
          _buildPieChart(genderDistribution, 'Gender Distribution'),
        if (ageGroups.isNotEmpty)
          _buildAgeHistogram(ageGroups),
      ],
    );
  }

  Widget _buildAgeHistogram(List<dynamic> data) {
    Map<String, int> ageGroupCounts = {
      '18-25': 0,
      '26-35': 0,
      '36-45': 0,
      '46-60': 0,
      '60+': 0,
    };

    data.forEach((item) {
      String ageGroup = item['age_group'] ?? 'Unknown';
      int count = item['count'] ?? 0;

      if (ageGroupCounts.containsKey(ageGroup)) {
        ageGroupCounts[ageGroup] = ageGroupCounts[ageGroup]! + count;
      }
    });

    List<ChartData> chartData = ageGroupCounts.entries.map((entry) {
      return ChartData(entry.key, entry.value);
    }).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: SfCartesianChart(
        title: ChartTitle(text: 'Age Group Distribution', textStyle: TextStyle(color: Colors.blueAccent)),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(),
        series: <ChartSeries>[
          BarSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            color: Colors.lightBlueAccent,
            dataLabelSettings: DataLabelSettings(isVisible: true, textStyle: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationStats() {
    var reservationsByStatus = _statistics['reservations']?['reservationsByStatus'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reservationsByStatus.isNotEmpty)
          _buildPieChart(reservationsByStatus, 'Reservation Status'),
      ],
    );
  }

  Widget _buildVehicleStats() {
    var lines = _statistics['vehicles']?['lines'] ?? [];

    if (lines.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('No vehicle data available'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBarChart(
          lines.map((line) => {'line_name': line['line_name'], 'vehicle_count': line['vehicle_count']}).toList(),
          'Vehicle Count per Line',
        ),
      ],
    );
  }

  Widget _buildReviewStats() {
    var terminals = _statistics['reviews']?['terminals'] ?? {};
    var ratings = (terminals.isNotEmpty && terminals.containsKey('2')) ? terminals['2']['ratings'] ?? {} : {};

    List<Map<String, dynamic>> ratingDistribution = List.generate(5, (index) {
      int rating = index + 1;
      int count = ratings[rating.toString()] ?? 0;
      return {'rating': rating, 'count': count};
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Rating Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        if (ratingDistribution.isNotEmpty)
          _buildReviewBarChart(ratingDistribution, 'Rating Distribution'),
      ],
    );
  }

  Widget _buildReviewBarChart(List<dynamic> data, String title) {
    List<ChartData> chartData = [];

    data.forEach((item) {
      String x = 'Rating ${item['rating']}';
      int y = item['count'];
      chartData.add(ChartData(x, y));
    });

    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: SfCartesianChart(
        title: ChartTitle(text: title, textStyle: TextStyle(color: Colors.blueAccent)),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(),
        series: <ChartSeries>[
          BarSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            color: Colors.orangeAccent,
            dataLabelSettings: DataLabelSettings(isVisible: true, textStyle: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> data, String title) {
    List<ChartData> chartData = [];

    data.forEach((item) {
      if (item is Map) {
        String x = '';
        int y = 0;

        if (item.containsKey('role_name') || item.containsKey('line_name')) {
          x = item['role_name'] ?? item['line_name'] ?? 'Unknown Role';
          y = item['vehicle_count'] ?? item['count'] ?? 0;
        }
        else if (item.containsKey('age_group') || item.containsKey('gender') || item.containsKey('role')) {
          x = item['role'] ?? item['gender'] ?? item['age_group'] ?? 'Unknown';
          y = item['count'] ?? 0;
        } else {
          x = 'Unknown';
          y = 0;
        }

        chartData.add(ChartData(x, y));
      }
    });

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: SfCartesianChart(
        title: ChartTitle(text: title, textStyle: TextStyle(color: Colors.blueAccent)),
        primaryXAxis: CategoryAxis(),
        primaryYAxis: NumericAxis(),
        series: <ChartSeries>[
          BarSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.x,
            yValueMapper: (ChartData data, _) => data.y,
            color: Colors.blueAccent,
            dataLabelSettings: DataLabelSettings(isVisible: true, textStyle: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }


  Widget _buildPieChart(List<dynamic> data, String title) {
    List<PieData> pieData = data.map((item) {
      // Check for category type (gender, role, age group, or reservation status)
      String category = item.containsKey('gender') ? item['gender'] :
      item.containsKey('role') ? item['role'] :
      item.containsKey('age_group') ? item['age_group'] :
      item.containsKey('status') ? item['status'] : '';

      // Categorize based on "Male" or "Female", "User" or "Driver", "Age Group", or "Reservation Status"
      String status = item.containsKey('gender') ? (item['gender'] == 'Male' ? 'Male' : 'Female') :
      item.containsKey('role') ? item['role'] :
      item.containsKey('age_group') ? item['age_group'] :
      item.containsKey('status') ? item['status'] : 'Unknown';

      // Return PieData with a formatted category label like "Male (4)", "Confirmed (9)"
      return PieData('$category ', item['count'] ?? 0);
    }).toList();

    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: SfCircularChart(
        title: ChartTitle(text: title, textStyle: TextStyle(color: Colors.blueAccent)),
        legend: Legend(isVisible: true),
        series: <CircularSeries>[
          PieSeries<PieData, String>(
            dataSource: pieData,
            xValueMapper: (PieData data, _) => data.category,
            yValueMapper: (PieData data, _) => data.count,
            dataLabelSettings: DataLabelSettings(isVisible: true, textStyle: TextStyle(color: Colors.black)),
            explode: true,
            explodeIndex: 1,
          ),
        ],
      ),
    );
  }

}

class ChartData {
  final String x;
  final int y;

  ChartData(this.x, this.y);
}

class PieData {
  final String category;
  final int count;

  PieData(this.category, this.count);
}
