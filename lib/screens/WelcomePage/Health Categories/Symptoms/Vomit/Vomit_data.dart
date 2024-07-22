import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Vomit/Vomit_details.dart';
import 'package:intl/intl.dart';

class VomitPage extends StatefulWidget {
  const VomitPage({super.key});

  @override
  State<VomitPage> createState() => _VomitPageState();
}

class _VomitPageState extends State<VomitPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  TimeOfDay? _selectedEndTime; // To capture the end time of the vomiting episode
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  String? _selectedType; // Type of vomit (e.g., food, bile)
  String? _selectedSeverity; // Severity of the vomiting episode
  String? _selectedFrequency; // Frequency of vomiting episodes

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _selectedEndTime = TimeOfDay(hour: (_selectedTime!.hour + 1) % 24, minute: _selectedTime!.minute);
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
    if (_selectedType == null || _selectedSeverity == null || _selectedFrequency == null || _selectedDate == null || _selectedTime == null || _selectedEndTime == null) {
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

    Map<String, dynamic> data = {
      'type': _selectedType,
      'severity': _selectedSeverity,
      'frequency': _selectedFrequency,
      'DateTime': fullDateTime,
      'userId': user.uid
    };

    try {
      await FirebaseFirestore.instance.collection('Vomits').doc().set(data);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Details Submitted Successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      // Clear the form fields
      setState(() {
        _selectedType = null;
        _selectedSeverity = null;
        _selectedFrequency = null;
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
        _selectedEndTime = TimeOfDay(hour: (_selectedTime!.hour + 1) % 24, minute: _selectedTime!.minute);
      });

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
      items: <String>['Not Present','Mild', 'Moderate', 'Severe', 'Very Severe']
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
      items: <String>['Food-related', 'Bile', 'Blood-streaked', 'Other']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildFrequencyDropdown() {
    return DropdownButton<String>(
      value: _selectedFrequency,
      onChanged: (String? newValue) {
        setState(() {
          _selectedFrequency = newValue;
        });
      },
      items: <String>['Once', 'Twice', 'Multiple times']
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
              'images/vomit.png'), // Adjusted icon to match vomiting context
        ),
        title: const Text(
          "Vomit",
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
                        builder: (context) => const VomitDetails()),
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
            title: Text("Type:", style: TextStyle(
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
            title: Text("Frequency:", style: TextStyle(
              fontWeight: FontWeight.bold,
            ),),
            trailing: _buildFrequencyDropdown(),
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
                const Text("Time:", style: TextStyle(
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
