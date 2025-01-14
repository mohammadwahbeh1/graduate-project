import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'adminPage.dart';

class DriversRequestsPage extends StatefulWidget {
  const DriversRequestsPage({Key? key}) : super(key: key);

  @override
  State<DriversRequestsPage> createState() => _DriversRequestsPageState();
}

class _DriversRequestsPageState extends State<DriversRequestsPage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String ip = "192.168.1.12";

  String? token;
  Future<List<dynamic>>? _driverRequestsFuture;

  @override
  void initState() {
    super.initState();
    _initTokenAndFetch();
  }

  Future<void> _initTokenAndFetch() async {
    String? storedToken = await _storage.read(key: 'jwt_token');
    setState(() {
      token = storedToken;
      if (token != null) {
        _driverRequestsFuture = fetchDriverRequests();
      } else {
        _driverRequestsFuture =
            Future.error("No token found in secure storage.");
      }
    });
  }

  Future<List<dynamic>> fetchDriverRequests() async {
    final url = Uri.parse("http://$ip:3000/api/driversQue/");
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to fetch driver requests");
    }
  }

  Future<void> acceptDriver(int userId) async {
    final url = Uri.parse("http://$ip:3000/api/driversQue/accept-driver/$userId");
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      setState(() {
        _driverRequestsFuture = fetchDriverRequests();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver accepted successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error accepting driver.")),
      );
    }
  }

  Future<void> deleteDriver(int userId) async {
    final url = Uri.parse("http://$ip:3000/api/driversQue/$userId");
    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _driverRequestsFuture = fetchDriverRequests();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Driver deleted successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting driver.")),
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _driverRequestsFuture = fetchDriverRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_driverRequestsFuture == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Drivers Requests",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ManagerPage()),
            );
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade300,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: Colors.blue,
          child: FutureBuilder<List<dynamic>>(
            future: _driverRequestsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(
                  child: Text("Error: ${snapshot.error}"),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text("No driver requests found."),
                );
              }

              final driverRequests = snapshot.data!;
              return ListView.builder(
                itemCount: driverRequests.length,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemBuilder: (context, index) {
                  final driver = driverRequests[index];
                  final int userId = driver['user_id'];
                  final String username = driver['username'] ?? '';
                  final String email = driver['email'] ?? '';
                  final String phone = driver['phone_number'] ?? '';
                  final String address = driver['address'] ?? '';
                  final String dob = driver['date_of_birth'] ?? '';
                  final String gender = driver['gender'] ?? '';
                  final String licensePath = driver['license_image_path'] ?? '';

                  final String fixedLicensePath = licensePath.replaceAll('\\', '/');
                  final String imageUrl = "http://$ip:3000/$fixedLicensePath";

                  return _buildDriverCard(
                    userId: userId,
                    username: username,
                    email: email,
                    phone: phone,
                    address: address,
                    dob: dob,
                    gender: gender,
                    imageUrl: imageUrl,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCard({
    required int userId,
    required String username,
    required String email,
    required String phone,
    required String address,
    required String dob,
    required String gender,
    required String imageUrl,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Stack(
            children: [
              Ink(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                ),
                child: Ink.image(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username.isNotEmpty ? username : 'No Name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 6),
                _infoRow(icon: Icons.email, value: email),
                _infoRow(icon: Icons.phone, value: phone),
                _infoRow(icon: Icons.location_on, value: address),
                _infoRow(icon: Icons.calendar_month, value: dob),
                _infoRow(icon: Icons.person, value: gender),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => acceptDriver(userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text("Accept"),
                    ),
                    const SizedBox(width: 12),
                    // زر Delete
                    ElevatedButton.icon(
                      onPressed: () => deleteDriver(userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text("Delete"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
