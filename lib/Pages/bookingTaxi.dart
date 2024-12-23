import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'Splash_screen.dart';

const String ip = "192.168.1.3";

class BookTaxiPage extends StatefulWidget {
  const BookTaxiPage({Key? key}) : super(key: key);

  @override
  _BookTaxiPageState createState() => _BookTaxiPageState();
}

class _BookTaxiPageState extends State<BookTaxiPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _phoneNumberController = TextEditingController();
  String? _startDestination;
  String? _endDestination;
  // String _selectedType = 'Single';
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

  String? _selectedRecurrencePattern;
  DateTime? _recurrenceEndDate;

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

  @override
  void initState() {
    super.initState();
    _selectedRecurrencePattern = null;
  }

  @override
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
                'To get a taxi ride, please choose from the following options:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              // Select destinations
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
                        _startDestination ?? "Start Location",
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
                        _endDestination ?? "End Location",
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Removed "Single/Family" booking type section
              /*
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildSelectionButton('Single', _selectedType == 'Single'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSelectionButton('Family', _selectedType == 'Family'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            */
              // Select date and time
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
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
                                  : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.calendar_today, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding:
                        const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
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
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Icon(Icons.access_time, color: Colors.black),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Recurring booking option
              Row(
                children: [
                  Checkbox(
                    value: _isRecurring,
                    onChanged: (value) {
                      setState(() {
                        _isRecurring = value ?? false;
                        if (!_isRecurring) {
                          _selectedRecurrencePattern = null;
                          _selectedDays = List.generate(7, (index) => false);
                          _recurrenceEndDate = null;
                        }
                      });
                    },
                  ),
                  const Text('Recurring Booking'),
                ],
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 15),
                // Select recurrence pattern (weekly or monthly)
                _buildRecurrencePatternSelector(),
                const SizedBox(height: 15),
                // Display days selection if the pattern is Weekly
                if (_selectedRecurrencePattern == 'Weekly') ...[
                  Container(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
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
                              color: _selectedDays[index] ? Colors.black : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 15),
                // Select recurrence end date
                GestureDetector(
                  onTap: () => _selectRecurrenceEndDate(context),
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _recurrenceEndDate == null
                              ? 'Select Recurrence End Date'
                              : DateFormat('MMM dd, yyyy').format(_recurrenceEndDate!),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Icon(Icons.calendar_today, color: Colors.black),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Phone number
              _buildPhoneNumberRow(),
              const SizedBox(height: 20),
              // Additional description (optional)
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
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              // Book button
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
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
            colorScheme: const ColorScheme.light(
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
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
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
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.black),
        ],
      ),
    );
  }

  void _showLocationSelector(BuildContext context, List<String> locations,
      Function(String) onSelect) {
    showModalBottomSheet(
      backgroundColor: Colors.grey[50],
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        List<String> filteredLocations = List.from(
            locations);

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // عنوان النافذة
                  Row(
                    children: [
                      // زر العودة
                      IconButton(
                        icon:
                        const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(
                              context);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "Find a place",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // للحفاظ على توازن العناصر في الصف
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 15),
                  // حقل البحث لتصفية المواقع
                  TextField(
                    decoration: InputDecoration(
                      hintText: "Find a place",
                      prefixIcon: const Icon(Icons.search, color: Colors.black),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: Colors.black, width: 2),
                      ),
                    ),
                    onChanged: (query) {
                      setState(() {
                        filteredLocations = locations
                            .where((location) => location
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                    onSubmitted: (query) {
                      setState(() {
                        filteredLocations = locations
                            .where((location) => location
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    height: 400,
                    child: ListView.builder(
                      itemCount: filteredLocations.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding:
                              const EdgeInsets.symmetric(vertical: 18),
                            ),
                            onPressed: () {
                              onSelect(filteredLocations[index]);
                              Navigator.pop(
                                  context); // إغلاق النافذة بعد الاختيار
                            },
                            child: Text(
                              filteredLocations[index],
                              style: const TextStyle(
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
          padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(),
          ),
          child: Row(
            children: const [
              Icon(Icons.phone, color: Colors.black),
              SizedBox(width: 5),
              Text(
                '+970',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
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
          return 'Phone number must contain only numbers';
        }
        return null;
      },
    );
  }


  Widget _buildRecurrencePatternSelector() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Recurrence Pattern',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      value: _selectedRecurrencePattern,
      items: ['Weekly', 'Monthly']
          .map((pattern) => DropdownMenuItem(
        value: pattern,
        child: Text(pattern == 'Weekly' ? 'Weekly' : 'Monthly'),
      ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedRecurrencePattern = value;
          if (value != 'Weekly') {
            _selectedDays = List.generate(7, (index) => false);
          }
        });
      },
      validator: (value) {
        if (_isRecurring && value == null) {
          return 'Please select a recurrence pattern';
        }
        return null;
      },
    );
  }

  Future<void> _selectRecurrenceEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ??
          DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.yellow,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _recurrenceEndDate) {
      setState(() {
        _recurrenceEndDate = picked;
      });
    }
  }


  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
                const Text(
                  "The taxi has been successfully booked",
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
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
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
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
      _selectedDate = null;
      _selectedTime = null;
      _isRecurring = false;
      _selectedRecurrencePattern = null;
      _recurrenceEndDate = null;
      _selectedDays = List.generate(7, (index) => false);
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
    // Validation
    if (_startDestination == _endDestination) {
      _showErrorDialog('Start and end destinations cannot be the same or empty.');
      return;
    }

    if (_phoneNumberController.text.isEmpty) {
      _showErrorDialog('Please enter a valid phone number.');
      return;
    }

    // Scheduled booking validation
    if (_selectedDate != null && _selectedTime == null) {
      _showErrorDialog('Please select both date and time for a scheduled booking.');
      return;
    }

    if (_isRecurring) {
      if (_selectedRecurrencePattern == null) {
        _showErrorDialog('Please select a recurrence pattern.');
        return;
      }
      if (_selectedRecurrencePattern == 'Weekly' && !_selectedDays.contains(true)) {
        _showErrorDialog('Please select at least one day for the weekly recurring booking.');
        return;
      }
      if (_recurrenceEndDate == null) {
        _showErrorDialog('Please select a recurrence end date.');
        return;
      }
    }

    // Prepare booking details
    String phoneNumber = _phoneNumberController.text;
    String timeStamp = DateFormat.jm().format(DateTime.now());
    String? description = _descriptionController.text.trim();

    // Prepare recurring_days as a string (comma-separated values)
    String recurringDays = '';
    if (_isRecurring && _selectedRecurrencePattern == 'Weekly') {
      recurringDays = _weekDays
          .asMap()
          .entries
          .where((entry) => _selectedDays[entry.key])
          .map((entry) => entry.value)
          .join(', ');
    }

    // Create booking details map with new fields
    var bookingDetails = {
      'start_destination': _startDestination,
      'end_destination': _endDestination,
      'phone_number': '+970$phoneNumber',
      'description': description.isNotEmpty ? description : null,
      'scheduled_date': _selectedDate?.toIso8601String(),
      'scheduled_time': _selectedTime != null
          ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}:00'
          : null,
      'is_recurring': _isRecurring,
      'recurrence_pattern': _isRecurring ? _selectedRecurrencePattern : null,
      'recurrence_interval': _isRecurring ? 1 : null, // This can be made adjustable later
      'recurrence_end_date': _isRecurring ? _recurrenceEndDate?.toIso8601String() : null,
      'recurring_days': recurringDays.isNotEmpty ? recurringDays : null, // Send as a string
    };

    // Send booking request
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
        print('Failed to book the taxi: ${response.body}');
        _showErrorDialog('Failed to book the taxi. Please try again.');
      }
    } catch (e) {
      print('Error in booking the taxi: $e');
      _showErrorDialog('Network error. Please check your internet connection.');
    }
  }

}
