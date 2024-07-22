import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Chest%20Pain/ChestPain_details.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChestPainPage extends StatefulWidget {
  const ChestPainPage({Key? key}) : super(key: key);

  @override
  State<ChestPainPage> createState() => _ChestPainPageState();
}

class _ChestPainPageState extends State<ChestPainPage> with SingleTickerProviderStateMixin {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedEndTime;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  String? _selectedCondition;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();

    // Set current date and time
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.fromDateTime(DateTime.now());
    _selectedEndTime = TimeOfDay.fromDateTime(DateTime.now().add(Duration(hours: 1)));

  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _submitDetails() async {
    if (_selectedCondition == null || _selectedDate == null || _selectedTime == null || _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields before submitting.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get the current user
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No user logged in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Prepare data for Firestore
    DateTime fullDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    DateTime fullEndTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedEndTime!.hour,
      _selectedEndTime!.minute,
    );

    Map<String, dynamic> data = {
      'condition': _selectedCondition,
      'startDateTime': fullDateTime,
      'endDateTime': fullEndTime,
      'userId': user.uid
    };


    try {
      await FirebaseFirestore.instance.collection('Chest Pain').doc().set(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Details Submitted Successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error writing document: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedEndTime = picked);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.lightBlue[100],
      child: SizeTransition(
        sizeFactor: _animationController,
        axisAlignment: 0.0,
        child: ExpansionTile(
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset('images/chest pain.png'),
          ),
          title: const Text("Chest Pain", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const ChestPainDetails()),
                            );
                          },
                          child: const Text(
                            'More Info',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _conditionDropdown(),
                  const SizedBox(height: 10),
                  _dateSelection(),
                  _timeSelection(),
                  _endTimeSelection(),
                  _actionButtonsRow(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conditionDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Condition',
        labelStyle: TextStyle(fontSize: 16, color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.blue[200]!, width: 2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.blue[200]!, width: 2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.blue[500]!, width: 2)),
        filled: true,
        fillColor: Colors.blue[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      value: _selectedCondition,
      items: <String>['Not Present', 'Mild', 'Moderate', 'Severe', 'Very Severe']
          .map((String value) => DropdownMenuItem(
        value: value,
        child: Text(value, style: TextStyle(fontSize: 16, color: Colors.black, fontWeight: FontWeight.bold)),
      ))
          .toList(),
      onChanged: (value) => setState(() => _selectedCondition = value),
      icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
      dropdownColor: Colors.blue[50],
      isExpanded: true,
      hint: const Text('Select a condition', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  Widget _dateSelection() {
    DateTime currentDate = _selectedDate ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Date: ${_dateFormat.format(currentDate)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => _selectDate(context),
            child: const Text('Select Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _timeSelection() {
    TimeOfDay currentTime = _selectedTime ?? TimeOfDay.now();
    DateTime tempDateTime = DateTime(2000, 1, 1, currentTime.hour, currentTime.minute);
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Start Time: ${_timeFormat.format(tempDateTime)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => _selectTime(context),
            child: const Text('Select Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _endTimeSelection() {
    TimeOfDay currentTime = _selectedEndTime ?? TimeOfDay.now();
    DateTime tempDateTime = DateTime(2000, 1, 1, currentTime.hour, currentTime.minute);
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('End Time: ${_timeFormat.format(tempDateTime)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => _selectEndTime(context),
            child: const Text('Select Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _actionButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton(
          onPressed: _submitDetails,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            elevation: 5,
            shadowColor: Colors.black.withOpacity(0.2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.teal[700],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 36, minWidth: 100),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 50),
              child: const Text(
                'Submit',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
