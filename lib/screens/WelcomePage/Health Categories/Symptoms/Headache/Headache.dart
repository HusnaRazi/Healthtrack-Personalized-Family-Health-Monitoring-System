import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Headache/Headache_details.dart';
import 'package:intl/intl.dart';

class HeadachePage extends StatefulWidget {
  const HeadachePage({super.key});

  @override
  State<HeadachePage> createState() => _HeadachePageState();
}

class _HeadachePageState extends State<HeadachePage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedEndTime;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  String? _selectedType;
  String? _selectedSeverity;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _selectedEndTime = TimeOfDay(hour: TimeOfDay.now().hour + 1, minute: TimeOfDay.now().minute);
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedEndTime) {
      setState(() {
        _selectedEndTime = picked;
      });
    }
  }

  void _submitDetails() async {
    if (_selectedType == null || _selectedSeverity == null || _selectedDate == null || _selectedTime == null || _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete all fields before submitting.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No user logged in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    if (fullEndTime.isBefore(fullDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('End time cannot be before start time.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Map<String, dynamic> data = {
      'type': _selectedType,
      'severity': _selectedSeverity,
      'startDateTime': fullDateTime,
      'endDateTime': fullEndTime,
      'userId': user.uid
    };

    try {
      await FirebaseFirestore.instance.collection('Headaches').doc().set(data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Details Submitted Successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
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

  Widget _buildSeverityDropdown() {
    return DropdownButton<String>(
      value: _selectedSeverity,
      onChanged: (String? newValue) {
        setState(() {
          _selectedSeverity = newValue;
        });
      },
      items: <String>[
        'Not Present',
        'Mild',
        'Moderate',
        'Severe',
        'Very Severe'
      ]
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButton<String>(
      value: _selectedType,
      onChanged: (String? newValue) {
        setState(() {
          _selectedType = newValue;
        });
      },
      items: <String>['Forehead', 'Temples', 'Back of head', 'Whole head']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.lightBlue[100],
      child: ExpansionTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset(
              'images/dizziness.png'), // Adjusted icon to match headache context
        ),
        title: const Text(
          "Headache",
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: <Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>const HeadacheDetails()),
                  );
                },
                child: const Text(
                  'More Info',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            title: Text("Area:", style: TextStyle(
              fontWeight: FontWeight.bold,
            ),),
            trailing: _buildTypeDropdown(),
          ),
          ListTile(
            title: Text("Severity:", style: TextStyle(
              fontWeight: FontWeight.bold,
            ),),
            trailing: _buildSeverityDropdown(),
          ),
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Date:", style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Text(
                    _dateFormat.format(_selectedDate!),
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Start Time:", style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),),
                InkWell(
                  onTap: () => _selectTime(context),
                  child: Text(
                    _timeFormat.format(DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedTime!.hour,
                      _selectedTime!.minute,
                    )),
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("End Time:", style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),),
                InkWell(
                  onTap: () => _selectEndTime(context),
                  child: Text(
                    _timeFormat.format(DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                      _selectedEndTime!.hour,
                      _selectedEndTime!.minute,
                    )),
                    style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  ),
                ),
              ],
            ),
          ),
          _actionButtonsRow(),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _actionButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end, // Keeps button to the right
      children: [
        Spacer(), // Adds a spacer that takes up available space
        ElevatedButton(
          onPressed: _submitDetails,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[700],
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
          ),
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 36, minWidth: 100),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
            child: const Text(
              'Submit',
              style: TextStyle(fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ),
        SizedBox(width: 12),
      ],
    );
  }
}
