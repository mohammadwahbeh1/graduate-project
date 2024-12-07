import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  late String selectedManagerId;
  String? selectedLineId;

  String searchQuery = "";
  List<dynamic> filteredLines = [];

  @override
  void initState() {
    super.initState();
    lineNameController = TextEditingController();
    latitudeController = TextEditingController();
    longitudeController = TextEditingController();
    fetchLines();
    fetchLineManagers();
  }


  void updateSearchResults(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredLines = lines.where((line) {
        final lineName = line['line_name'].toString().toLowerCase();
        final manager = lineManagers.firstWhere(
              (manager) => manager['user_id'].toString() == line['line_manager_id'].toString(),
          orElse: () => {'username': 'Unknown Manager'},
        )['username'].toString().toLowerCase();

        return lineName.contains(searchQuery) || manager.contains(searchQuery);
      }).toList();
    });
  }  @override
  void dispose() {
    lineNameController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  Future<void> fetchLines() async {
    setState(() {
      isLoading = true;
    });
    String? token = await storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      _showErrorDialog('Token is missing or invalid');
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
      final data = jsonDecode(response.body);
      setState(() {
        lines = data['data'];
        filteredLines = List.from(lines);
        isLoading = false;
      });
    } else {
      _showErrorDialog('Failed to fetch lines');
      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> fetchLineManagers() async {
    String? token = await storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      _showErrorDialog('Token is missing or invalid');
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
      final data = jsonDecode(response.body);
      setState(() {
        lineManagers = data['data'];
      });
    } else {
      _showErrorDialog('Failed to fetch line managers');
    }
  }

  Future<void> createOrUpdateLine({String? lineId}) async {
    if (!_formKey.currentState!.validate()) return;

    String? token = await storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      _showErrorDialog('Token is missing or invalid');
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
      _showSuccessDialog(lineId == null
          ? 'Line created successfully'
          : 'Line updated successfully');
      fetchLines();
    } else {
      _showErrorDialog('Failed to save line');
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
              backgroundColor: Colors.red, // إضافة لون الخلفية الأحمر
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.white), // تأكيد أن النص أبيض
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    String? token = await storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      _showErrorDialog('Token is missing or invalid');
      return;
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/delete/$lineId'),
      headers: {
        'Authorization': 'Bearer $token',
        'accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      _showSuccessDialog('Line deleted successfully');
      fetchLines();
    } else {
      _showErrorDialog('Failed to delete line');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success', style: TextStyle(color: Colors.green)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Colors.green)),
          ),
        ],
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
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 16,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isEdit ? 'Edit Line' : 'Add Line', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
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
                    DropdownButtonFormField<String>(
                      value: selectedManagerId.isEmpty ? null : selectedManagerId,
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
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: latitudeController,
                      decoration: InputDecoration(
                        labelText: 'Latitude',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter latitude' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: longitudeController,
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value!.isEmpty ? 'Please enter longitude' : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel', style: TextStyle(color: Colors.red)),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            createOrUpdateLine(lineId: lineId);
                            Navigator.pop(context);
                          },
                          child: Text(isEdit ? 'Update' : 'Create' ,style: TextStyle(color: Colors.white),),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Line Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              onChanged: updateSearchResults, // استدعاء التصفية عند تغيير النص
              decoration: InputDecoration(
                hintText: 'Search by Line Name or Manager',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.deepPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredLines.isEmpty
          ? const Center(child: Text('No results found'))
          : ListView.builder(
        itemCount: filteredLines.length,
        itemBuilder: (context, index) {
          final line = filteredLines[index];
          final manager = lineManagers.firstWhere(
                (manager) =>
            manager['user_id'].toString() == line['line_manager_id'].toString(),
            orElse: () => {'username': 'Unknown Manager'},
          );
          return GestureDetector(
            onTap: () => print("Card tapped"), // يمكن إضافة وظيفة تفاعلية عند الضغط على الكارد
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              elevation: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              shadowColor: Colors.deepPurple.withOpacity(0.7),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade500,
                        Colors.deepPurple.shade800,
                        Colors.purple.shade900,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.2, 0.5, 0.8],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        offset: Offset(5, 10),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                    title: Text(
                      line['line_name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    subtitle: Text(
                      'Manager: ${manager['username']}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _openFormDialog(isEdit: true, lineId: line['line_id'].toString()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => deleteLine(line['line_id'].toString()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _openFormDialog(isEdit: false),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

