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
  const DriversRatingPage({super.key});

  @override
  _DriversRatingPageState createState() => _DriversRatingPageState();
}

class _DriversRatingPageState extends State<DriversRatingPage>
    with SingleTickerProviderStateMixin {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  List<DriverRating> _drivers = [];
  bool _isLoading = true;
  String? _errorMessage;
  double averageRating = 0.0;
  int totalDrivers = 0;

  // عدّل الـ IP أو اجلبه من إعداداتك
  final String ip = "192.168.1.7";

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
            totalDrivers = _drivers.length;
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
    List<DriverRating> ratedDrivers =
    _drivers.where((driver) => driver.avgRating > 0).toList();

    if (ratedDrivers.isEmpty) return 0.0;

    double total =
    ratedDrivers.fold(0.0, (sum, driver) => sum + driver.avgRating);
    return total / ratedDrivers.length;
  }

  Widget buildDonutChart(double width) {
    if (_drivers.isEmpty) {
      return const Center(
        child: Text(
          "No data to display.",
          style: TextStyle(color: Colors.black87),
        ),
      );
    }

    Map<String, int> ratingDistribution = {
      '1 Star': 0,
      '2 Stars': 0,
      '3 Stars': 0,
      '4 Stars': 0,
      '5 Stars': 0,
      'Uncategorized': 0,
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
        ratingDistribution['Uncategorized'] =
            ratingDistribution['Uncategorized']! + 1;
      }
    }

    // أزل التصنيفات التي قيمتها 0 لتجنب ظهورها في المخطط
    ratingDistribution.removeWhere((key, value) => value == 0);

    List<_PieData> pieData = ratingDistribution.entries
        .map((e) => _PieData(e.key, e.value))
        .toList();

    return SfCircularChart(
      title: ChartTitle(
        text: 'Rating Distribution',
        textStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      legend: Legend(
        isVisible: true,
        overflowMode: LegendItemOverflowMode.wrap,
        textStyle: const TextStyle(color: Colors.black87),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      series: <CircularSeries>[
        DoughnutSeries<_PieData, String>(
          dataSource: pieData,
          xValueMapper: (_PieData data, _) => data.rating,
          yValueMapper: (_PieData data, _) => data.count,
          dataLabelMapper: (_PieData data, _) => '${data.rating}: ${data.count}',
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            connectorLineSettings: ConnectorLineSettings(
              type: ConnectorType.curve,
              length: '15%',
              color: Colors.black87,
            ),
            textStyle: TextStyle(color: Colors.black87, fontSize: 12),
          ),
          enableTooltip: true,
          explode: true,
          explodeIndex: 0,
          explodeAll: false,
          pointColorMapper: (_PieData data, _) {
            switch (data.rating) {
              case '1 Star':
                return Colors.redAccent;
              case '2 Stars':
                return Colors.orangeAccent;
              case '3 Stars':
                return Colors.amber;
              case '4 Stars':
                return Colors.lightGreen;
              case '5 Stars':
                return Colors.green;
              case 'Uncategorized':
                return Colors.grey;
              default:
                return Colors.grey;
            }
          },
        ),
      ],
      backgroundColor: Colors.white,
    );
  }

  Widget buildBarChart(double width) {
    if (_drivers.isEmpty) {
      return const Center(
        child: Text(
          "No data to display.",
          style: TextStyle(color: Colors.black87),
        ),
      );
    }

    return SfCartesianChart(
      title: ChartTitle(
        text: 'Drivers Ratings',
        textStyle: const TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      tooltipBehavior: TooltipBehavior(enable: true),
      primaryXAxis: CategoryAxis(
        labelRotation: 45,
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: const TextStyle(color: Colors.black87, fontSize: 10),
        axisLine: const AxisLine(color: Colors.grey),
      ),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: 5,
        interval: 1,
        majorGridLines:
        const MajorGridLines(width: 0.5, color: Colors.grey),
        labelStyle: const TextStyle(color: Colors.black87, fontSize: 10),
        axisLine: const AxisLine(color: Colors.grey),
      ),
      backgroundColor: Colors.white,
      plotAreaBorderWidth: 0,
      series: <ChartSeries>[
        ColumnSeries<DriverRating, String>(
          dataSource: _drivers,
          xValueMapper: (DriverRating driver, _) => driver.driverName,
          yValueMapper: (DriverRating driver, _) => driver.avgRating,
          name: 'Ratings',
          color: Colors.teal,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            textStyle: TextStyle(
              fontSize: 10,
              color: Colors.white,
            ),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget buildSummarySection(double width) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Colors.white,
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // تحديد عدد الأعمدة بناءً على عرض الشاشة
            int crossAxisCount = constraints.maxWidth < 600 ? 2 : 4;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSummaryItem(
                  icon: Icons.star,
                  title: 'Average Rating',
                  value: averageRating.toStringAsFixed(1),
                ),
                _buildSummaryItem(
                  icon: Icons.people,
                  title: 'Total Drivers',
                  value: totalDrivers.toString(),
                ),
                _buildSummaryItem(
                  icon: Icons.thumb_up,
                  title: 'Highest Rating',
                  value: _getHighestRatedDriver(),
                ),
                _buildSummaryItem(
                  icon: Icons.thumb_down,
                  title: 'Lowest Rating',
                  value: _getLowestRatedDriver(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.teal, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  String _getHighestRatedDriver() {
    if (_drivers.isEmpty) return "N/A";
    // لا تقم بتعديل قائمة السائقين مباشرةً لأن ذلك سيؤثر على ترتيب البيانات الأصلية
    List<DriverRating> sortedDrivers = List.from(_drivers);
    sortedDrivers.sort((a, b) => b.avgRating.compareTo(a.avgRating));
    return "${sortedDrivers.first.driverName} (${sortedDrivers.first.avgRating})";
  }

  String _getLowestRatedDriver() {
    if (_drivers.isEmpty) return "N/A";
    // لا تقم بتعديل قائمة السائقين مباشرةً لأن ذلك سيؤثر على ترتيب البيانات الأصلية
    List<DriverRating> sortedDrivers = List.from(_drivers);
    sortedDrivers.sort((a, b) => a.avgRating.compareTo(b.avgRating));
    return "${sortedDrivers.first.driverName} (${sortedDrivers.first.avgRating})";
  }

  Widget buildLoading() {
    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
        ),
      ),
    );
  }

  Widget buildError() {
    return Center(
      child: Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.red, fontSize: 16),
      ),
    );
  }

  Widget buildContent(BuildContext context) {
    if (_isLoading) {
      return buildLoading();
    }

    if (_errorMessage != null) {
      return buildError();
    }

    // الحصول على حجم الشاشة
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            buildSummarySection(width),
            const SizedBox(height: 30),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: buildDonutChart(width),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: buildBarChart(width),
              ),
            ),
            // إزالة بطاقة الـ Average Rating Gauge
            // const SizedBox(height: 30),
            // Card(
            //   elevation: 4,
            //   shape: RoundedRectangleBorder(
            //     borderRadius: BorderRadius.circular(20),
            //   ),
            //   color: Colors.white,
            //   child: Padding(
            //     padding: const EdgeInsets.all(16.0),
            //     child: buildAverageRatingGauge(width),
            //   ),
            // ),
            // const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget buildAppBar() {
    return AppBar(
      backgroundColor: Colors.teal.shade400,
      elevation: 0,
      title: const Text(
        'Drivers Ratings',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade100, Colors.teal.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: buildAppBar(),
      body: SafeArea(
        child: buildContent(context),
      ),
    );
  }
}

class _PieData {
  final String rating;
  final int count;

  _PieData(this.rating, this.count);
}
