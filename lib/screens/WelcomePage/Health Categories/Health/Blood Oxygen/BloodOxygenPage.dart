import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Blood%20Oxygen/BloodOxygen_details.dart';

class BloodOxygen extends StatefulWidget {
  const BloodOxygen({Key? key}) : super(key: key);

  @override
  _BloodOxygenState createState() => _BloodOxygenState();
}

class _BloodOxygenState extends State<BloodOxygen> {
  final TextEditingController _oxygenController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _dateController.text =
        DateFormat('dd/MM/yyyy').format(_selectedDate); // Updated date format
    _timeController.text = DateFormat('hh:mm a').format(
        _selectedDate); // Updated time format to 12 hours
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day,
            _selectedDate.hour, _selectedDate.minute);
        _dateController.text = DateFormat('dd/MM/yyyy').format(
            _selectedDate); // Updated date format
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDate =
            DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
                picked.hour, picked.minute);
        _timeController.text = DateFormat('hh:mm a').format(
            _selectedDate); // Updated time format to 12 hours
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
    final oxygen = int.tryParse(_oxygenController.text) ?? 0;
    if (oxygen <= 0 || oxygen > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(
            'Please enter a valid Oxygen Saturation between 1-100%.')),
      );
      return;
    }

    // Update _selectedDate with current time
    _selectedDate = DateTime.now();
    _timeController.text =
        DateFormat('hh:mm a').format(_selectedDate); // Update time field

    try {
      await FirebaseFirestore.instance.collection('Blood Oxygen').add({
        'userId': user.uid,
        'saturation': oxygen,
        'timestamp': Timestamp.fromDate(_selectedDate),
        // Use selected date and time
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Blood Oxygen Saturation: $oxygen% submitted successfully.'),
        ),
      );

      _oxygenController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting blood oxygen saturation: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _oxygenController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25), // Adjust border radius here
      ),
      color: Colors.lightBlue[100],
      child: ExpansionTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/blood oxygen.png'),
        ),
        title: const Text(
          "Blood Oxygen",
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
                      MaterialPageRoute(
                          builder: (context) => const BloodOxygenDetails()),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Column(
              children: [
                TextFormField(
                  controller: _oxygenController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Oxygen Saturation (%)',
                    hintText: 'e.g., 98',
                    icon: Icon(Icons.percent, color: theme.primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _dateController,
                        readOnly: true,
                        onTap: () => _pickDate(context),
                        decoration: InputDecoration(
                          labelText: 'Select Date',
                          icon: Icon(Icons.calendar_today, color: theme
                              .primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _timeController,
                        readOnly: true,
                        onTap: () => _pickTime(context),
                        decoration: InputDecoration(
                          labelText: 'Select Time',
                          icon: Icon(Icons.access_time, color: theme
                              .primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    // Background color
                    padding: EdgeInsets.symmetric(horizontal: 25),
                    // Increase padding to make the button taller
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20) // Rounded corners for the button
                    ),
                  ),
                  onPressed: _submitData,
                  child: const Text("Submit",
                    style: TextStyle(
                      fontSize: 14, // Optional: Adjust font size
                      color: Colors.white,
                    ),
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
