import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'Splash_screen.dart';
const String ip ="192.168.1.12";

class BookTaxiPage extends StatefulWidget {
  const BookTaxiPage({Key? key}) : super(key: key);

  @override
  _BookTaxiPageState createState() => _BookTaxiPageState();
}

class _BookTaxiPageState extends State<BookTaxiPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneNumberController =
  TextEditingController();
  String? _startDestination;
  String? _endDestination;
  String _selectedType = 'Single';
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isRecurring = false;
  List<bool> _selectedDays = List.generate(7, (index) => false);
  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
  ];

  final List<String> _allLocations = [
    'راس العين',
    'شركة الكهرباء',
    'التعاون الاوسط',
    'شارع 24',
    'العامرية',
    'حي طيبة',
    'التعاون العلوي',
    'كروم عاشور',
    'شارع 10',
    'حات العامود',
    'مستشفى الهلال الاحمر',
    'نابلس الجديدة',
    'شارع الطور',
    'شارع الحرش',
    'اسكان الكهرباء',
    'شارع كشيكة',
    'شارع المعري',
    'مستشفى الامل',
    'الطور',
    'جبل الطور',
    'عراق بورين',
    'شارع تل',
    'شارع ابو عبيدة',
    'حي النور',
    'شارع المأمون',
    'طلعة علاء الدين',
    'شارع الجرف',
    'نقابة الاتصالات',
    'مفرق البدوي',
    'شارع تونس',
    'طلعة بليبلة',
    'مستشفى رفيديا',
    'الجامعة القديمة',
    'المخفية',
    'المستشفى التخصصي',
    'اسكان المهندسين-رفيديا',
    'شارع النجاح',
    'ضاحية النخيل',
    'اسكان البيدر',
    'عين الصبيان',
    'دخلة ملحيس',
    'شارع كمال جنبلاط',
    'شارع المريج',
    'شارع يافا',
    'شارع 16',
    'شارع 17',
    'شارع 15',
    'شارع عمان ',
    'عبد الرحيم محمود',
    'اسعاد الطفولة',
    'شارع جمال عبد الناصر',
    'المقاطعة',
    'عراق التايه',
    'كلية الروضة',
    'طلعة الماطورات',
    'بلاطة البلد',
    'عسكر البلد',
    'مخيم عسكر القديم',
    'المسلخ',
    'عسكر الجديد',
    'دوار الفارس',
    'دوار الحسبة',
    'شارع القدس',
    'اسكان روجيب',
    'المنطقة الصناعية روجيب',
    'السوق الشرقي',
    'كفر قليل',
    'شارع حلاوة',
    'المساكن',
    'طلعة الزينبيه',
    'شارع سعد صايل',
    'جسر التيتي',
    'الاسكان النمساوي',
    'مستشفى الاتحاد',
    'مستشفى النجاح',
    'خلة الايمان',
    'شارع ابن رشد',
    'شارع عصيرة',
    'شارع مؤته',
    'شارع الحجة عفيفة',
    'طلعة اسو',
    'شارع الرشيد',
    'فطاير جبل فطاير',
    'شارع بيجر',
    'شارع ابو بكر',
    'شارع المنجرة',
    'سما نابلس',
    'طلعة عماد الدين',
    'عصيرة الشمالية',
    'طلعة زبلح',
    'واد التفاح',
    'مفرق زواتا',
    'بيت ايبا',
    'زواتا',
    'مخيم العين',
    'الجنيد',
    'بيت وزن',
    'صرة',
    'حي المسك',
    'دير شرف',
    'منتجع مارينا',
    'منتزه البلدية',
    'وسط البلد',
    'منتزه العائلات',
    'شارع المدارس',
    'شارع البساتين',
    'شارع فيصل',
    'شارع شويتره',
    'حواره',
    'النصاريه',
    'عقربا',
    'بورين',
    'تياسير',
    'جيوس',
    'مستشفى رفيديا'
  ];

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Book Your Taxi Ride!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'To get the ride of your taxi please select from the following:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              // Location Selection Row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _showLocationSelector(
                            context, _allLocations, (selectedLocation) {
                          setState(() {
                            _startDestination = selectedLocation;
                          });
                        });
                      },
                      child: _buildDropdownPlaceholder(
                        _startDestination ?? "Start Destination",
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _showLocationSelector(
                            context, _allLocations, (selectedLocation) {
                          setState(() {
                            _endDestination = selectedLocation;
                          });
                        });
                      },
                      child: _buildDropdownPlaceholder(
                        _endDestination ?? "End Destination",
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Single/Family Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildSelectionButton(
                        'Single', _selectedType == 'Single'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSelectionButton(
                        'Family', _selectedType == 'Family'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Date and Time Selection
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : DateFormat('MMM dd, yyyy').format(
                                  _selectedDate!),
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.calendar_today, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            vertical: 15, horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTime == null
                                  ? 'Select Time'
                                  : _selectedTime!.format(context),
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(Icons.access_time, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Recurring Booking Option
              Row(
                children: [
                  Checkbox(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value ?? false;
                      });
                    },
                  ),
                  Text('Recurring Booking'),
                ],
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 15),
                Container(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_weekDays[index]),
                          selected: _selectedDays[index],
                          onSelected: (bool selected) {
                            setState(() {
                              _selectedDays[index] = selected;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: Colors.yellow,
                          checkmarkColor: Colors.black,
                          labelStyle: TextStyle(
                            color: _selectedDays[index] ? Colors.black : Colors
                                .grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildPhoneNumberRow(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Add Description (Optional)',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignLabelWithHint: true,
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _showConfirmationDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Find a Taxi',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.yellow,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.yellow,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }


  Widget _buildDropdownPlaceholder(String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(Icons.arrow_drop_down, color: Colors.black),
        ],
      ),
    );
  }

  void _showLocationSelector(BuildContext context, List<String> locations,
      Function(String) onSelect) {
    showModalBottomSheet(
      backgroundColor: Colors.grey[50],
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      // Ensures the modal expands properly
      builder: (context) {
        List<String> filteredLocations = List.from(
            locations); // Copy initial list

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle the top bar with the back arrow and title
                  Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 30),


                  Row(
                    children: [
                      // Back arrow button aligned to the left
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(
                              context); // Close the modal when pressed
                        },
                      ),
                      // Center the Text in the middle of the Row


                      Text(
                        "Find a place",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),


                    ],
                  ),

                  const SizedBox(height: 15),
                  // Search TextField for filtering locations
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Search a place",
                      prefixIcon: Icon(Icons.search, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    onChanged: (query) {
                      setState(() {
                        // Filter the list in real-time as the user types
                        filteredLocations = locations
                            .where((location) =>
                            location.toLowerCase().contains(
                                query.toLowerCase()))
                            .toList();
                      });
                    },
                    onSubmitted: (query) {
                      setState(() {
                        // Ensure the filtered list is kept even when the keyboard is dismissed
                        filteredLocations = locations
                            .where((location) =>
                            location.toLowerCase().contains(
                                query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  // List of filtered locations displayed below the search bar
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredLocations.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 18),
                            ),
                            onPressed: () {
                              onSelect(filteredLocations[index]);
                              Navigator.pop(
                                  context); // Close the modal after selection
                            },
                            child: Text(
                              filteredLocations[index],
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildPhoneNumberRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(),
          ),
          child: Row(
            children: [
              const Icon(Icons.phone, color: Colors.black),
              const SizedBox(width: 5),
              const Text(
                '+970',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPhoneNumberField(),
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField() {
    return TextFormField(
      controller: _phoneNumberController,
      decoration: InputDecoration(
        hintText: 'Enter phone number',
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
      keyboardType: TextInputType.phone,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a valid phone number';
        }
        if (!RegExp(r'^\d+$').hasMatch(value)) {
          return 'Phone number can only contain digits';
        }
        return null;
      },
    );
  }

  Widget _buildSelectionButton(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = label;
        });
      },
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog() {
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
                const Text(
                  'Are you sure?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Are you sure you want to book this taxi ride?',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _bookTaxi();
                      },
                      child: const Text('Yes'),
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

  void _showSuccessDialog() {
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
                const Text(
                  'Success',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  "The Taxi Booked Succesfully",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the error dialog
                      },
                      child: const Text('OK'),
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

  void _showErrorDialog(String errorMessage) {
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
                const Text(
                  'Error',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  errorMessage,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the error dialog
                      },
                      child: const Text('OK'),
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

  void _clearFields() {
    setState(() {
      _startDestination = null;
      _endDestination = null;
      _descriptionController.clear();
    });

    _phoneNumberController.clear();
  }

  void _createNotification(String message) async {
    String? token = await storage.read(key: 'jwt_token');

    if (token == null) {
      print('JWT token is null');
      return;
    }

    var notificationDetails = {'message': message};


    final response = await http.post(
      Uri.parse('http://$ip:3000/api/v1/notifications'),
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


  void _bookTaxi() async {
    // Validation checks
    if (_startDestination == _endDestination) {
      _showErrorDialog(
          'Start and end destinations cannot be the same or empty.');
      return;
    }

    if (_phoneNumberController.text.isEmpty) {
      _showErrorDialog('Please enter a valid phone number.');
      return;
    }

    // Add new validation for scheduled booking
    if (_selectedDate != null && _selectedTime == null) {
      _showErrorDialog(
          'Please select both date and time for scheduled booking.');
      return;
    }

    if (_isRecurring && !_selectedDays.contains(true)) {
      _showErrorDialog('Please select at least one day for recurring booking.');
      return;
    }

    // Prepare booking details
    String phoneNumber = _phoneNumberController.text;
    String timeStamp = DateFormat.jm().format(DateTime.now());
    String? description = _descriptionController.text.trim();

    // Create booking details map with new fields
    var bookingDetails = {
      'start_destination': _startDestination,
      'end_destination': _endDestination,
      'reservation_type': _selectedType,
      'phone_number': '+970$phoneNumber',
      'description': description.isNotEmpty ? description : null,

      'scheduled_date': _selectedDate?.toIso8601String(),
      'scheduled_time': _selectedTime != null
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!
          .minute.toString().padLeft(2, '0')}:00'
          : null,
      'is_recurring': _isRecurring,
      'recurring_days': _isRecurring
          ? _weekDays
          .asMap()
          .entries
          .where((entry) => _selectedDays[entry.key])
          .map((entry) => entry.value)
          .toList()

          : null,
    };

    // Send request
    String? token = await storage.read(key: 'jwt_token');
    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://$ip:3000/api/v1/reservation'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bookingDetails),
      );

      if (response.statusCode == 201) {
        _showSuccessDialog();
        _createNotification(
            "Taxi booked from $_startDestination to $_endDestination at $timeStamp."
        );
        _clearFields();
      } else {
        print('Failed to book taxi: ${response.body}');
        _showErrorDialog('Failed to book taxi. Please try again.');
      }
    } catch (e) {
      print('Error booking taxi: $e');
      _showErrorDialog('Network error. Please check your connection.');
    }
  }
}

