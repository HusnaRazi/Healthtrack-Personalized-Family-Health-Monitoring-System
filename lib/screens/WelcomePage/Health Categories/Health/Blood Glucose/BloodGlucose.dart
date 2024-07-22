import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Blood%20Glucose/BloodGlucose_details.dart';

class BloodGlucose extends StatefulWidget {
  const BloodGlucose({Key? key}) : super(key: key);

  @override
  _BloodGlucoseState createState() => _BloodGlucoseState();
}

class _BloodGlucoseState extends State<BloodGlucose> {
  final TextEditingController _glucoseController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now(); // Use system's local time
    _selectedDate = now;
    _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);

    // Set initial values for date and time controllers
    _dateController.text = DateFormat('dd/MM/yyyy').format(now);
    _timeController.text = DateFormat.jm().format(DateTime.now());
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.fromDateTime(DateTime.now())
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
        // Format time in 12-hour format
        _timeController.text = pickedTime.format(context);
      });
    }
  }

  Future<void> _submitData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user found, please login first.')),
      );
      return;
    }
    final glucose = int.tryParse(_glucoseController.text) ?? 0;
    if (glucose <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid glucose level.')),
      );
      return;
    }

    final dateTimeNow = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    try {
      await FirebaseFirestore.instance.collection('Blood Glucose').add({
        'userId': user.uid,
        'glucose': glucose,
        'timestamp': Timestamp.fromDate(dateTimeNow)
        // Using the exact datetime selected
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Blood Glucose: $glucose mg/dL submitted successfully.'),
        ),
      );

      // Resetting fields after submission
      _glucoseController.clear();
      DateTime now = DateTime.now();
      _selectedDate = now;
      _selectedTime = TimeOfDay(hour: now.hour, minute: now.minute);
      _dateController.text = DateFormat.yMd().format(now);
      _timeController.text = MaterialLocalizations.of(context).formatTimeOfDay(
          _selectedTime!, alwaysUse24HourFormat: false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting blood glucose level: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      color: Colors.lightBlue[100],
      child: ExpansionTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/sugar-level.png'),
        ),
        title: const Text(
          "Blood Glucose",
          style: TextStyle(
            fontSize: 19,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BloodGlucoseDetails()),
                    );
                  },
                  child: const Text(
                    'Details Here',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 50,
                  child: TextFormField(
                    controller: _glucoseController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Glucose Level (mg/dL)',
                      hintText: 'Enter glucose level',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            icon: Icon(Icons.calendar_month_rounded, color: theme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _dateController.text,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Time',
                            icon: Icon(Icons.access_time, color: theme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _timeController.text,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor, // Background color
            ),
            onPressed: _submitData,
            child: const Text(
              "Submit",
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _glucoseController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}