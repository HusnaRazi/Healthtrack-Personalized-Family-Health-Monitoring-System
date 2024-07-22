import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Add%20Other%20Symptom/List_otherSymptoms.dart';
import 'package:intl/intl.dart';

class AddOthersymptoms extends StatefulWidget {
  const AddOthersymptoms({Key? key}) : super(key: key);

  @override
  State<AddOthersymptoms> createState() => _AddOthersymptomsState();
}

class _AddOthersymptomsState extends State<AddOthersymptoms> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late TextEditingController _symptomController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _symptomController = TextEditingController();
    _dateController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
    _timeController = TextEditingController(
        text: DateFormat('hh:mm a').format(DateTime.now()));
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _symptomController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _timeController.text = DateFormat('hh:mm a').format(
            DateTime(2022, 6, 1, picked.hour, picked.minute));
      });
    }
  }

  void _submitDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    DateTime? selectedDate =
    DateFormat('dd/MM/yyyy').parse(_dateController.text);
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
        DateFormat('hh:mm a').parse(_timeController.text)!);
    DateTime fullDateTime = DateTime(
        selectedDate!.year, selectedDate.month, selectedDate.day,
        selectedTime.hour, selectedTime.minute);

    // Get current user
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

    // Prepare data
    Map<String, dynamic> data = {
      'symptom': _symptomController.text,
      'date': _dateController.text,
      'time': _timeController.text,
      'description': _descriptionController.text,
      'userId': user.uid, // Associate with user ID
      'timestamp': Timestamp.now(), // Add timestamp
    };

    try {
      // Save data to Firestore
      await FirebaseFirestore.instance.collection('symptoms').add(data);

      // Clear inputs after submission
      _symptomController.clear();
      _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
      _timeController.text = DateFormat('hh:mm a').format(DateTime.now());
      _descriptionController.clear();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Details Submitted Successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print("Error submitting details: $e");

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.lightBlue[100],
      child: ExpansionTile(
        leading: Icon(Icons.add_circle_outline, color: Colors.blue),
        title: const Text("Add New Symptom",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                        builder: (context) => ListOthersymptoms()),
                  );
                },
                child: const Text(
                  'More Data',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _symptomController,
                    decoration: InputDecoration(
                      labelText: 'Symptom',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Symptom cannot be empty';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateController,
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          onTap: () => _selectDate(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Date cannot be empty';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _timeController,
                          decoration: InputDecoration(
                            labelText: 'Time',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          onTap: () => _selectTime(context),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Time cannot be empty';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          _actionButtonsRow(), // Moved the _actionButtonsRow here
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _actionButtonsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end, // Keeps button to the right
      children: [
        const Spacer(), // Adds a spacer that takes up available space
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
        const SizedBox(width: 12),
      ],
    );
  }
}
