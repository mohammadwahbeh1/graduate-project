import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';


class DriverRating {
  final int driverId;
  final String driverName;
  final double avgRating;

  DriverRating({
    required this.driverId,
    required this.driverName,
    required this.avgRating,
  });

  factory DriverRating.fromJson(Map<String, dynamic> json) {
    return DriverRating(
      driverId: json['driver_id'],
      driverName: json['driver_name'],
      avgRating: double.parse(json['avg_rating'].toString()),
    );
  }
}

class DriversRatingPage extends StatefulWidget {
  @override
  _DriversRatingPageState createState() => _DriversRatingPageState();
}

class _DriversRatingPageState extends State<DriversRatingPage>
    with SingleTickerProviderStateMixin {
  final FlutterSecureStorage storage = FlutterSecureStorage();
  List<DriverRating> _drivers = [];
  bool _isLoading = true;
  String? _errorMessage;
  double averageRating = 0.0;

  final String ip = "192.168.1.3";

  // Animation Controller
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    fetchDriverRatings();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchDriverRatings() async {
    String? token = await storage.read(key: 'jwt_token');

    if (token == null) {
      setState(() {
        _errorMessage = "Token not found.";
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse("http://$ip:3000/api/v1/line/driver/rating");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success']) {
          final List<dynamic> data = responseData['data'];
          setState(() {
            _drivers =
                data.map((item) => DriverRating.fromJson(item)).toList();
            averageRating = calculateAverageRating();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = "Failed to fetch data.";
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = "Error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = "Error: $error";
        _isLoading = false;
      });
    }
  }

  double calculateAverageRating() {
    // Calculate average only for drivers who have been rated (avgRating > 0)
    List<DriverRating> ratedDrivers =
    _drivers.where((driver) => driver.avgRating > 0).toList();

    if (ratedDrivers.isEmpty) return 0.0;

    double total =
    ratedDrivers.fold(0.0, (sum, driver) => sum + driver.avgRating);
    return total / ratedDrivers.length;
  }

  Widget buildHistogramChart() {
    if (_drivers.isEmpty) {
      return Center(
          child: Text(
            "No data available to display.",
            style: TextStyle(color: Colors.white),
          ));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(
          labelRotation: 45,
          majorGridLines: MajorGridLines(width: 0),
          labelStyle: TextStyle(color: Colors.white),
        ),
        primaryYAxis: NumericAxis(
          minimum: 0,
          maximum: 5,
          interval: 1,
          majorGridLines:
          MajorGridLines(width: 0.5, color: Colors.white30),
          labelStyle: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        plotAreaBackgroundColor: Colors.transparent,
        title: ChartTitle(
          text: 'Driver Rating Distribution',
          textStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        tooltipBehavior: TooltipBehavior(enable: true),
        legend: Legend(isVisible: false),
        series: <ChartSeries>[
          ColumnSeries<DriverRating, String>(
            dataSource: _drivers,
            xValueMapper: (DriverRating driver, _) => driver.driverName,
            yValueMapper: (DriverRating driver, _) => driver.avgRating,
            name: 'Ratings',
            color: Colors.orangeAccent,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(
                fontSize: 10,
                color: Colors.white,
              ),
            ),
            borderRadius: BorderRadius.circular(5),
          )
        ],
      ),
    );
  }

  Widget buildAverageRatingGauge() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SfRadialGauge(
        title: GaugeTitle(
          text: 'Average Rating',
          textStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        axes: <RadialAxis>[
          RadialAxis(
            minimum: 0,
            maximum: 5,
            interval: 1,
            axisLineStyle: AxisLineStyle(
              thickness: 0.2,
              color: Colors.white30,
              thicknessUnit: GaugeSizeUnit.factor,
            ),
            ranges: <GaugeRange>[
              GaugeRange(
                startValue: 0,
                endValue: averageRating,
                color: Colors.greenAccent,
                startWidth: 0.2,
                endWidth: 0.2,
              ),
              GaugeRange(
                startValue: averageRating,
                endValue: 5,
                color: Colors.white10,
                startWidth: 0.2,
                endWidth: 0.2,
              ),
            ],
            pointers: <GaugePointer>[
              NeedlePointer(
                value: averageRating,
                needleColor: Colors.redAccent,
                knobStyle: KnobStyle(color: Colors.red),
                needleLength: 0.7,
              )
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                widget: averageRating > 0
                    ? Text(
                  averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  "No Ratings",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                angle: 90,
                positionFactor: 0.5,
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPieChart() {
    if (_drivers.isEmpty) {
      return Center(
          child: Text(
            "No data available to display.",
            style: TextStyle(color: Colors.white),
          ));
    }

    // Categorize data including "Not Rated"
    Map<String, int> ratingDistribution = {
      '1 Star': 0,
      '2 Stars': 0,
      '3 Stars': 0,
      '4 Stars': 0,
      '5 Stars': 0,
      'Not Rated': 0,
    };

    for (var driver in _drivers) {
      if (driver.avgRating >= 4.5) {
        ratingDistribution['5 Stars'] = ratingDistribution['5 Stars']! + 1;
      } else if (driver.avgRating >= 3.5) {
        ratingDistribution['4 Stars'] = ratingDistribution['4 Stars']! + 1;
      } else if (driver.avgRating >= 2.5) {
        ratingDistribution['3 Stars'] = ratingDistribution['3 Stars']! + 1;
      } else if (driver.avgRating >= 1.5) {
        ratingDistribution['2 Stars'] = ratingDistribution['2 Stars']! + 1;
      } else if (driver.avgRating > 0) {
        ratingDistribution['1 Star'] = ratingDistribution['1 Star']! + 1;
      } else {
        ratingDistribution['Not Rated'] = ratingDistribution['Not Rated']! + 1;
      }
    }

    // Remove categories with zero count
    ratingDistribution.removeWhere((key, value) => value == 0);

    List<_PieData> pieData = ratingDistribution.entries
        .map((e) => _PieData(e.key, e.value))
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SfCircularChart(
        title: ChartTitle(
          text: 'Ratings Distribution',
          textStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        legend: Legend(
          isVisible: true,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: TextStyle(color: Colors.white),
        ),
        series: <PieSeries<_PieData, String>>[
          PieSeries<_PieData, String>(
            dataSource: pieData,
            xValueMapper: (_PieData data, _) => data.rating,
            yValueMapper: (_PieData data, _) => data.count,
            dataLabelMapper: (_PieData data, _) =>
            '${data.rating}: ${data.count}',
            dataLabelSettings: const DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              connectorLineSettings: ConnectorLineSettings(
                type: ConnectorType.curve,
                length: '10%',
                color: Colors.white,
              ),
              textStyle:
              TextStyle(color: Colors.white, fontSize: 12),
            ),
            enableTooltip: true,
            explode: true,
            explodeIndex: 0,
            explodeAll: false,
            // Use pointColorMapper to assign different colors
            pointColorMapper: (_PieData data, _) {
              switch (data.rating) {
                case '1 Star':
                  return Colors.redAccent;
                case '2 Stars':
                  return Colors.orangeAccent;
                case '3 Stars':
                  return Colors.yellowAccent;
                case '4 Stars':
                  return Colors.greenAccent;
                case '5 Stars':
                  return Colors.blueAccent;
                case 'Not Rated':
                  return Colors.grey;
                default:
                  return Colors.grey;
              }
            },
          )
        ],
      ),
    );
  }

  Widget buildContent() {
    if (_isLoading) {
      return Center(
        child: FadeTransition(
          opacity: _animationController,
          child: CircularProgressIndicator(
            valueColor:
            AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 20),
          // Gradient Background with Average Rating Gauge
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade200, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Text(
                  'Driver Ratings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                buildAverageRatingGauge(),
              ],
            ),
          ),
          SizedBox(height: 30),
          Divider(color: Colors.white54, thickness: 1.5),
          SizedBox(height: 10),
          buildPieChart(),
          SizedBox(height: 30),
          buildHistogramChart(),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Soft Gradient Background for the Page
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Title Bar
              Container(
                width: double.infinity,
                padding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Ratings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black26,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Overview of Driver Ratings',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Data Model for Pie Chart
class _PieData {
  final String rating;
  final int count;

  _PieData(this.rating, this.count);
}
