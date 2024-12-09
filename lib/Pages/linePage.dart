import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

// تأكد من إضافة التخزين الآمن أو تعريف `storage` بشكل مناسب
import 'Splash_screen.dart';

const String baseUrl = 'http://192.168.1.8:3000/api/v1/line';
const String managerUrl = 'http://192.168.1.8:3000/api/v1/admin/line-managers';

class LinePage extends StatefulWidget {
  const LinePage({Key? key}) : super(key: key);

  @override
  _LinePageState createState() => _LinePageState();
}

class _LinePageState extends State<LinePage> {
  final storage = FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  List<dynamic> lines = [];
  List<dynamic> lineManagers = [];
  late TextEditingController lineNameController;
  late TextEditingController latitudeController;
  late TextEditingController longitudeController;
  String? selectedManagerId;
  String? selectedLineId;

  String searchQuery = "";
  List<dynamic> filteredLines = [];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    lineNameController = TextEditingController();
    latitudeController = TextEditingController();
    longitudeController = TextEditingController();
    fetchLines();
    fetchLineManagers();
    searchController.addListener(_filterLines);
  }

  @override
  void dispose() {
    lineNameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchLines() async {
    setState(() {
      isLoading = true;
    });
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Authentication token is missing or invalid.');
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/term/line'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'] as List;
        setState(() {
          lines = data.cast<Map<String, dynamic>>();
          filteredLines = List.from(lines);
          isLoading = false;
        });
      } else {
        _showErrorSnackbar('Failed to fetch lines');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching lines: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchLineManagers() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Authentication token is missing or invalid.');
        return;
      }

      final response = await http.get(
        Uri.parse(managerUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        setState(() {
          lineManagers = data;
        });
      } else {
        _showErrorSnackbar('Failed to fetch line managers');
      }
    } catch (e) {
      _showErrorSnackbar('Error fetching line managers: $e');
    }
  }

  Future<void> createOrUpdateLine({String? lineId}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Authentication token is missing or invalid.');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = lineId == null
          ? await http.post(
        Uri.parse('$baseUrl/create'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'line_manager_id': selectedManagerId,
          'line_name': lineNameController.text,
          'lat': latitudeController.text,
          'long': longitudeController.text,
        }),
      )
          : await http.put(
        Uri.parse('$baseUrl/update/$lineId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'line_manager_id': selectedManagerId,
          'line_name': lineNameController.text,
          'lat': latitudeController.text,
          'long': longitudeController.text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessSnackbar(lineId == null
            ? 'Line created successfully'
            : 'Line updated successfully');
        fetchLines();
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Failed to save line';
        _showErrorSnackbar('Failed to save line: $errorMessage');
      }
    } catch (e) {
      _showErrorSnackbar('Error saving line: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> deleteLine(String lineId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.red)),
        content: const Text('Are you sure you want to delete this line?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red, // لون الخلفية الأحمر
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white), // النص أبيض
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isLoading = true;
    });

    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null || token.isEmpty) {
        _showErrorSnackbar('Authentication token is missing or invalid.');
        setState(() {
          isLoading = false;
        });
        return;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$lineId'),
        headers: {
          'Authorization': 'Bearer $token',
          'accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _showSuccessSnackbar('Line deleted successfully');
        fetchLines();
      } else {
        final errorMessage =
            json.decode(response.body)['message'] ?? 'Failed to delete line';
        _showErrorSnackbar('Failed to delete line: $errorMessage');
      }
    } catch (e) {
      _showErrorSnackbar('Error deleting line: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterLines() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredLines = lines.where((line) {
        final lineName = line['line_name'].toString().toLowerCase();
        final manager = lineManagers.firstWhere(
              (manager) => manager['user_id'].toString() == line['line_manager_id'].toString(),
          orElse: () => {'username': 'Unknown Manager'},
        )['username'].toString().toLowerCase();
        return lineName.contains(query) || manager.contains(query);
      }).toList();
    });
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _openFormDialog({bool isEdit = false, String? lineId}) {
    if (isEdit && lineId != null) {
      final line = lines.firstWhere((element) => element['line_id'].toString() == lineId);
      lineNameController.text = line['line_name'];
      latitudeController.text = line['lat'].toString();
      longitudeController.text = line['long'].toString();
      selectedManagerId = line['line_manager_id'].toString();
    } else {
      lineNameController.clear();
      latitudeController.clear();
      longitudeController.clear();
      selectedManagerId = lineManagers.isNotEmpty ? lineManagers[0]['user_id'].toString() : '';
    }

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView( // لضمان ظهور المحتوى بشكل صحيح على الشاشات الصغيرة
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isEdit ? 'Edit Line' : 'Add Line',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Line Name
                      TextFormField(
                        controller: lineNameController,
                        decoration: InputDecoration(
                          labelText: 'Line Name',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Please enter a line name' : null,
                      ),
                      const SizedBox(height: 15),
                      // Line Manager
                      DropdownButtonFormField<String>(
                        value: selectedManagerId!.isEmpty ? null : selectedManagerId,
                        decoration: InputDecoration(
                          labelText: 'Line Manager',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: lineManagers.map((manager) {
                          return DropdownMenuItem<String>(
                            value: manager['user_id'].toString(),
                            child: Text(manager['username']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedManagerId = value!;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a manager' : null,
                      ),
                      const SizedBox(height: 15),
                      // Latitude
                      TextFormField(
                        controller: latitudeController,
                        decoration: InputDecoration(
                          labelText: 'Latitude',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Please enter latitude' : null,
                      ),
                      const SizedBox(height: 15),
                      // Longitude
                      TextFormField(
                        controller: longitudeController,
                        decoration: InputDecoration(
                          labelText: 'Longitude',
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Please enter longitude' : null,
                      ),
                      const SizedBox(height: 20),
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                createOrUpdateLine(lineId: lineId);
                                Navigator.pop(context);
                              } else {
                                _showErrorSnackbar('Please fill in all fields.');
                              }
                            },
                            child: Text(isEdit ? 'Update' : 'Create',
                                style: const TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineCard(Map<String, dynamic> line) {
    final manager = lineManagers.firstWhere(
          (manager) => manager['user_id'].toString() == line['line_manager_id'].toString(),
      orElse: () => {'username': 'Unknown Manager'},
    )['username']
        .toString();

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      shadowColor: Colors.blue.withOpacity(0.2),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.blue.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Line Icon
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF00B4DB),
              child: const Icon(
                Icons.directions_bus,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 20),
            // Line Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line['line_name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF0083B0),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Manager: $manager',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Latitude: ${line['lat']}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Longitude: ${line['long']}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _openFormDialog(isEdit: true, lineId: line['line_id'].toString()),
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteLine(line['line_id'].toString()),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineList(bool isWeb) {
    if (filteredLines.isEmpty) {
      return Center(
        child: Text(
          'No lines available.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
        ),
      );
    }

    if (isWeb) {
      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 3,
        ),
        itemCount: filteredLines.length,
        itemBuilder: (context, index) {
          return _buildLineCard(filteredLines[index]);
        },
      );
    } else {
      return ListView.builder(
        itemCount: filteredLines.length,
        itemBuilder: (context, index) {
          return _buildLineCard(filteredLines[index]);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // استخدام AppBar بتدرج لوني متناسق
      appBar: AppBar(
        title: const Text('Line Management'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isWeb = constraints.maxWidth > 800; // تحديد حجم الشاشة

          return isLoading
              ? Center(
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B4DB)),
            ),
          )
              : Padding(
            padding: isWeb
                ? const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0) // حشوة أكبر للويب
                : const EdgeInsets.all(16.0), // حشوة أصغر للموبايل
            child: Column(
              children: [
                // شريط البحث
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by Line Name or Manager',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF0083B0)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Color(0xFF0083B0)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // يمكنك إضافة فلتر إضافي هنا إذا لزم الأمر
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // قائمة الخطوط
                Expanded(child: _buildLineList(isWeb)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openFormDialog(isEdit: false),
        backgroundColor: const Color(0xFF0083B0),
        tooltip: 'Add Line',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
