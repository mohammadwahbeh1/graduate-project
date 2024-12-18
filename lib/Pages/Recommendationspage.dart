import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:untitled/Pages/profilePage.dart';
import 'dart:math' as math;

const String ip = "192.168.1.8";
final storage = FlutterSecureStorage();

class Recommendationspage extends StatefulWidget {
  const Recommendationspage({super.key});

  @override
  _RecommendationspageState createState() => _RecommendationspageState();
}

class _RecommendationspageState extends State<Recommendationspage> {
  List<dynamic> pendingReservations = [];
  List<dynamic> filteredPendingReservations = [];
  bool isLoading = true;
  String searchQuery = '';
  String username = '';
  Position? _currentPosition;
  final double _maxDistance = 1;
  final Map<String, Map<String, double>> nablusCoordinates = {
    'راس العين': {'latitude': 32.2230, 'longitude': 35.2590},
    'شركة الكهرباء': {'latitude': 32.2220, 'longitude': 35.2544},
    'التعاون الاوسط': {'latitude': 32.2238, 'longitude': 35.2631},
    'شارع 24': {'latitude': 32.2230, 'longitude': 35.2570},
    'العامرية': {'latitude': 32.2235, 'longitude': 35.2585},
    'حي طيبة': {'latitude': 32.2240, 'longitude': 35.2595},
    'التعاون العلوي': {'latitude': 32.2242, 'longitude': 35.2625},
    'كروم عاشور': {'latitude': 32.2228, 'longitude': 35.2575},
    'شارع 10': {'latitude': 32.2233, 'longitude': 35.2580},
    'حات العامود': {'latitude': 32.2227, 'longitude': 35.2595},
    'مستشفى الهلال الاحمر': {'latitude': 32.2225, 'longitude': 35.2565},
    'نابلس الجديدة': {'latitude': 32.2245, 'longitude': 35.2600},
    'شارع الطور': {'latitude': 32.2250, 'longitude': 35.2610},
    'شارع الحرش': {'latitude': 32.2255, 'longitude': 35.2620},
    'اسكان الكهرباء': {'latitude': 32.2218, 'longitude': 35.2542},
    'شارع كشيكة': {'latitude': 32.2235, 'longitude': 35.2605},
    'شارع المعري': {'latitude': 32.2240, 'longitude': 35.2615},
    'مستشفى الامل': {'latitude': 32.2230, 'longitude': 35.2550},
    'الطور': {'latitude': 32.2248, 'longitude': 35.2608},
    'جبل الطور': {'latitude': 32.2252, 'longitude': 35.2612},
    'عراق بورين': {'latitude': 32.1965, 'longitude': 35.2030},
    'شارع تل': {'latitude': 32.2225, 'longitude': 35.2575},
    'شارع ابو عبيدة': {'latitude': 32.2235, 'longitude': 35.2585},
    'حي النور': {'latitude': 32.2245, 'longitude': 35.2595},
    'شارع المأمون': {'latitude': 32.2230, 'longitude': 35.2580},
    'طلعة علاء الدين': {'latitude': 32.2240, 'longitude': 35.2590},
    'شارع الجرف': {'latitude': 32.2235, 'longitude': 35.2600},
    'نقابة الاتصالات': {'latitude': 32.2225, 'longitude': 35.2570},
    'مفرق البدوي': {'latitude': 32.2215, 'longitude': 35.2560},
    'شارع تونس': {'latitude': 32.2230, 'longitude': 35.2585},
    'طلعة بليبلة': {'latitude': 32.2245, 'longitude': 35.2605},
    'مستشفى رفيديا': {'latitude': 32.2236, 'longitude': 35.2335},
    'الجامعة القديمة': {'latitude': 32.2230, 'longitude': 35.2413},
    'المخفية': {'latitude': 32.2245, 'longitude': 35.2420},
    'المستشفى التخصصي': {'latitude': 32.2238, 'longitude': 35.2340},
    'اسكان المهندسين-رفيديا': {'latitude': 32.2242, 'longitude': 35.2338},
    'شارع النجاح': {'latitude': 32.2235, 'longitude': 35.2375},
    'ضاحية النخيل': {'latitude': 32.2250, 'longitude': 35.2380},
    'اسكان البيدر': {'latitude': 32.2240, 'longitude': 35.2385},
    'عين الصبيان': {'latitude': 32.2230, 'longitude': 35.2390},
    'دخلة ملحيس': {'latitude': 32.2235, 'longitude': 35.2395},
    'شارع كمال جنبلاط': {'latitude': 32.2240, 'longitude': 35.2400},
    'شارع المريج': {'latitude': 32.2245, 'longitude': 35.2405},
    'شارع يافا': {'latitude': 32.2220, 'longitude': 35.2610},
    'شارع 16': {'latitude': 32.2225, 'longitude': 35.2615},
    'شارع 17': {'latitude': 32.2230, 'longitude': 35.2620},
    'شارع 15': {'latitude': 32.2235, 'longitude': 35.2625},
    'شارع عمان': {'latitude': 32.21547, 'longitude': 35.27505},
    'عبد الرحيم محمود': {'latitude': 32.2245, 'longitude': 35.2635},
    'اسعاد الطفولة': {'latitude': 32.2250, 'longitude': 35.2640},
    'شارع جمال عبد الناصر': {'latitude': 32.2215, 'longitude': 35.2645},
    'المقاطعة': {'latitude': 32.2220, 'longitude': 35.2650},
    'عراق التايه': {'latitude': 32.2225, 'longitude': 35.2655},
    'كلية الروضة': {'latitude': 32.2230, 'longitude': 35.2660},
    'طلعة الماطورات': {'latitude': 32.2235, 'longitude': 35.2665},
    'بلاطة البلد': {'latitude': 32.2205, 'longitude': 35.2855},
    'عسكر البلد': {'latitude': 32.2195, 'longitude': 35.2890},
    'مخيم عسكر القديم': {'latitude': 32.2190, 'longitude': 35.2885},
    'المسلخ': {'latitude': 32.2200, 'longitude': 35.2880},
    'عسكر الجديد': {'latitude': 32.2185, 'longitude': 35.2895},
    'دوار الفارس': {'latitude': 32.2210, 'longitude': 35.2640},
    'دوار الحسبة': {'latitude': 32.2215, 'longitude': 35.2645},
    'شارع القدس': {'latitude': 32.2210, 'longitude': 35.2585},
    'اسكان روجيب': {'latitude': 32.2280, 'longitude': 35.2950},
    'المنطقة الصناعية روجيب': {'latitude': 32.2285, 'longitude': 35.2955},
    'السوق الشرقي': {'latitude': 32.2220, 'longitude': 35.2620},
    'كفر قليل': {'latitude': 32.2150, 'longitude': 35.2870},
    'شارع حلاوة': {'latitude': 32.2225, 'longitude': 35.2625},
    'المساكن': {'latitude': 32.2230, 'longitude': 35.2630},
    'طلعة الزينبيه': {'latitude': 32.2235, 'longitude': 35.2635},
    'شارع سعد صايل': {'latitude': 32.2240, 'longitude': 35.2640},
    'جسر التيتي': {'latitude': 32.2245, 'longitude': 35.2645},
    'الاسكان النمساوي': {'latitude': 32.2250, 'longitude': 35.2650},
    'مستشفى الاتحاد': {'latitude': 32.2234, 'longitude': 35.2338},
    'مستشفى النجاح': {'latitude': 32.2232, 'longitude': 35.2440},
    'خلة الايمان': {'latitude': 32.2260, 'longitude': 35.2660},
    'شارع ابن رشد': {'latitude': 32.2265, 'longitude': 35.2665},
    'شارع عصيرة': {'latitude': 32.2270, 'longitude': 35.2670},
    'شارع مؤته': {'latitude': 32.2275, 'longitude': 35.2675},
    'شارع الحجة عفيفة': {'latitude': 32.2280, 'longitude': 35.2680},
    'طلعة اسو': {'latitude': 32.2285, 'longitude': 35.2685},
    'شارع الرشيد': {'latitude': 32.2290, 'longitude': 35.2690},
    'فطاير جبل فطاير': {'latitude': 32.2295, 'longitude': 35.2695},
    'شارع بيجر': {'latitude': 32.2300, 'longitude': 35.2700},
    'شارع ابو بكر': {'latitude': 32.2305, 'longitude': 35.2705},
    'شارع المنجرة': {'latitude': 32.2310, 'longitude': 35.2710},
    'سما نابلس': {'latitude': 32.2315, 'longitude': 35.2715},
    'طلعة عماد الدين': {'latitude': 32.2320, 'longitude': 35.2720},
    'عصيرة الشمالية': {'latitude': 32.2505, 'longitude': 35.2870},
    'طلعة زبلح': {'latitude': 32.2330, 'longitude': 35.2730},
    'واد التفاح': {'latitude': 32.2335, 'longitude': 35.2735},
    'مفرق زواتا': {'latitude': 32.2392, 'longitude': 35.2292},
    'بيت ايبا': {'latitude': 32.2290, 'longitude': 35.2145},
    'زواتا': {'latitude': 32.2397, 'longitude': 35.2297},
    'مخيم العين': {'latitude': 32.2345, 'longitude': 35.2745},
    'الجنيد': {'latitude': 32.2290, 'longitude': 35.2150},
    'بيت وزن': {'latitude': 32.2286, 'longitude': 35.2139},
    'صرة': {'latitude': 32.2355, 'longitude': 35.2755},
    'حي المسك': {'latitude': 32.2360, 'longitude': 35.2760},
    'دير شرف': {'latitude': 32.2365, 'longitude': 35.2765},
    'منتجع مارينا': {'latitude': 32.2370, 'longitude': 35.2770},
    'منتزه البلدية': {'latitude': 32.2375, 'longitude': 35.2775},
    'وسط البلد': {'latitude': 32.2225, 'longitude': 35.2605},
    'منتزه العائلات': {'latitude': 32.2385, 'longitude': 35.2785},
    'شارع المدارس': {'latitude': 32.2390, 'longitude': 35.2790},
    'شارع البساتين': {'latitude': 32.2395, 'longitude': 35.2795},
    'شارع فيصل': {'latitude': 32.2225, 'longitude': 35.2615},
    'شارع شويتره': {'latitude': 32.2405, 'longitude': 35.2805},
    'حواره': {'latitude': 32.1525, 'longitude': 35.2561},
    'النصاريه': {'latitude': 32.2415, 'longitude': 35.2815},
    'عقربا': {'latitude': 32.1245, 'longitude': 35.3445},
    'بورين': {'latitude': 32.1961, 'longitude': 35.2026},
    'تياسير': {'latitude': 32.3228, 'longitude': 35.3870},
    'جيوس': {'latitude': 32.1922, 'longitude': 35.0875}
  };

  @override
  void initState() {
    super.initState();

    _fetchPendingReservations();
    fetchUserProfile();
  }


  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) * math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * math.pi / 180;
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      _currentPosition = position;
      print("The current position is: $_currentPosition");

    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _calculateTheDes() {
    if (_currentPosition != null) {
      setState(() {
        List<dynamic> nearbyReservations = pendingReservations.where((reservation) {
          String startDest = reservation['start_destination'].toString().trim();  // Add trim() here
          if (nablusCoordinates.containsKey(startDest)) {
            double reservationLat = nablusCoordinates[startDest]!['latitude']!;
            double reservationLon = nablusCoordinates[startDest]!['longitude']!;

            double distance = calculateDistance(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                reservationLat,
                reservationLon
            );

            print("\nThe distance is $distance km for reservation: $startDest");
            return distance <= _maxDistance;
          }
          print("\nLocation not found in coordinates: '$startDest'");
          return false;
        }).toList();

        pendingReservations = nearbyReservations;
        filteredPendingReservations = nearbyReservations;

        print("Filtered reservations count: ${filteredPendingReservations.length}");
      });
    }
  }



  void _filterReservations() {
    setState(() {
      List<dynamic> filteredList = pendingReservations.where((reservation) {
        String username = reservation['User'] != null
            ? reservation['User']['username'] ?? ''
            : '';
        return username.toLowerCase().contains(searchQuery.toLowerCase()) ||
            (reservation['phone_number'] != null &&
                reservation['phone_number']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())) ||
            (reservation['start_destination'] != null &&
                reservation['start_destination']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())) ||
            (reservation['end_destination'] != null &&
                reservation['end_destination']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())) ||
            (reservation['created_at'] != null &&
                reservation['created_at']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())) ||
            (reservation['recurrence_pattern'] != null &&
                reservation['recurrence_pattern']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase())) ||
            (reservation['recurring_days'] != null &&
                reservation['recurring_days']
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()));
      }).toList();

      filteredPendingReservations = filteredList;
    });
  }


  Future<void> fetchUserProfile() async {
    String? token = await storage.read(key: 'jwt_token');
    if (token == null) {
      setState(() {
        username = "No Token Found";
      });
      return;
    }

    final url = Uri.parse("http://$ip:3000/api/v1/users/Profile");
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          username = data['data']['username'];
        });
      } else {
        setState(() {
          username = "Failed to load";
        });
      }
    } catch (e) {
      setState(() {
        username = "Error";
      });
      print("Error fetching user profile: $e");
    }
  }

  Future<void> _fetchPendingReservations() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token != null) {
        final pendingResponse = await http.get(
          Uri.parse('http://$ip:3000/api/v1/reservation/pending/all'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (pendingResponse.statusCode == 200) {

            pendingReservations = json.decode(pendingResponse.body)['data'];

            isLoading = false;

          await _getCurrentLocation();
          _calculateTheDes();
        } else {
          setState(() {
            isLoading = false;
          });
          _showErrorDialog('Failed to load pending reservations.');
        }

      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching pending reservations: $error");
      _showErrorDialog('Error fetching pending reservations.');
    }
  }

  Future<void> _acceptReservation(int reservationId, String userId) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      final response = await http.patch(
        Uri.parse('http://$ip:3000/api/v1/reservation/accept/$reservationId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['data'] != null) {
          final driverInfo = responseData['data'];
          String driverName = driverInfo['driver_id'].toString() ?? 'Unknown';
          String driverPhone = driverInfo['phone_number'].toString() ?? 'N/A';

          _createNotification(
            userId,
            'Your taxi has been booked successfully by $driverName. Contact: $driverPhone.',
          );
        } else {
          _showErrorDialog('Driver information not found.');
        }

        _fetchPendingReservations();
        _showSuccessDialog('Reservation accepted successfully');
        setState(() {
          filteredPendingReservations.removeWhere(
                  (reservation) => reservation['reservation_id'] == reservationId);
        });
      } else {
        _showErrorDialog('Error accepting reservation');
      }
    } catch (e) {
      _showErrorDialog('Error accepting reservation: $e');
    }
  }

  void _createNotification(String userId, String message) async {
    String? token = await storage.read(key: 'jwt_token');
    if (token == null) return;

    var notificationDetails = {
      'userId': userId,
      'message': message,
    };

    final response = await http.post(
      Uri.parse('http://$ip:3000/api/v1/notifications/$userId/driver'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(notificationDetails),
    );

    if (response.statusCode == 200) {
      print('Notification created successfully');
    } else {
      print('Failed to create notification: ${response.body}');
    }
  }

  Widget _buildReservationCard({
    required Map<String, dynamic> reservation,
    required bool isPending,
    required VoidCallback onAction,
  }) {
    String username =
    reservation['User'] != null ? reservation['User']['username'] ?? 'Unknown' : 'Unknown';
    String phoneNumber = reservation['phone_number'] ?? 'N/A';

    return Card(
      color: Colors.white,
      elevation: 8,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Ride #${reservation['reservation_id']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Created At: ${reservation['created_at']}",
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 20, color: Colors.grey),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5CF24),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFCF3C2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.my_location_outlined,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Pick Up: ${reservation['start_destination']}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5CF24),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFCF3C2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.black,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Drop Off: ${reservation['end_destination']}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Start_date: ${reservation['scheduled_date']}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  child: Text(
                    "at: ${reservation['scheduled_time']}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Description: ${reservation['description'] ?? 'No description provided.'}",
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
            const SizedBox(height: 8),
            if (reservation['is_recurring'] == true) ...[
              const Text(
                "Recurring: Yes",
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                "Pattern: ${reservation['recurrence_pattern'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                "Interval: ${reservation['recurrence_interval'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              Text(
                "End Date: ${reservation['recurrence_end_date'] ?? 'N/A'}",
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              if (reservation['recurring_days'] != null)
                Text(
                  "Days: ${reservation['recurring_days']}",
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                isPending ? const Color(0xFFF5CF24) : const Color(0xFFF2643A),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(
                isPending ? 'Accept' : 'Reject',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
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

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    required String confirmText,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onConfirm();
                      },
                      child: Text(confirmText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: const Text(
        "Recommendations",
        style: TextStyle(fontWeight: FontWeight.w500),
    ),
    backgroundColor: const Color(0xFFF5CF24),
    centerTitle: true,
    actions: [
    IconButton(
    icon: const Icon(
    Icons.person,
    size: 30,
    color: Colors.black,
    ),
    onPressed: () {
      _showProfileOptions(context);
    },
    ),
    ],
    ),
    body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Search',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            prefixIcon: Icon(Icons.search),
            fillColor: Colors.white,
            filled: true,
          ),
          onChanged: (value) {
            setState(() {
              searchQuery = value;
              _filterReservations();
            });
          },
        ),
      ),
      Expanded(
        child: ListView(
          children: [
            if (filteredPendingReservations.isNotEmpty) ...[
              for (var reservation in filteredPendingReservations)
                _buildReservationCard(
                  reservation: reservation,
                  isPending: true,
                  onAction: () {
                    _showConfirmationDialog(
                      context: context,
                      title: 'Accept Reservation',
                      message:
                      'Are you sure you want to accept this reservation?',
                      onConfirm: () {
                        _acceptReservation(
                          reservation['reservation_id'],
                          reservation['user_id'].toString(),
                        );
                      },
                      confirmText: 'Accept',
                    );
                  },
                ),
            ],
            if (filteredPendingReservations.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(
                  child: Text("No pending reservations."),
                ),
              ),
          ],
        ),
      ),
    ],
    ),
    );
  }
}
void _showProfileOptions(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Profile Options'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfilePage()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
