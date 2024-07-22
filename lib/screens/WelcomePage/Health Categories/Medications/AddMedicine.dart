import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Medications/CalendarMedicine.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Medications/ListMedications_Card.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMedicationPage extends StatefulWidget {
  const AddMedicationPage({Key? key}) : super(key: key);

  @override
  _AddMedicationPageState createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final List<String> _medicationTypes = ['Tablet', 'Capsule', 'Drops', 'Injection', 'Syrup', 'Cream'];
  String _selectedType = 'Tablet';
  String _reminderTime = 'Once';
  String _duration = '1 Month';
  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _sideNoteController = TextEditingController();
  final TextEditingController _medicineDoseController = TextEditingController();
  DateTime? _startDate;
  bool _isReminderSet = false;
  int _dosageFrequency = 1;
  List<TimeOfDay> reminderTimes = [];
  bool _isExpanded = false;

  // Function to increment dosage frequency
  void _incrementFrequency() {
    setState(() {
      _dosageFrequency++;
    });
  }

  // Function to decrement dosage frequency
  void _decrementFrequency() {
    setState(() {
      if (_dosageFrequency > 1) {
        _dosageFrequency--;
      }
    });
  }

  void _addNewReminder() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() {
        reminderTimes.add(pickedTime);
      });
    }
  }

  void _deleteReminder(int index) {
    setState(() {
      reminderTimes.removeAt(index);
    });
  }

  Future<void> _saveMedication() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('Medication Reminder')
            .doc(user.uid)
            .collection('Medicine')
            .add({
          'medicineName': _medicineNameController.text.trim(), // ensure no leading/trailing whitespace
          'medicineType': _selectedType,
          'dosage': _medicineDoseController.text,
          'dosageFrequency': _dosageFrequency,
          'reminderTime': _reminderTime,
          'duration': _duration,
          'sideNotes': _sideNoteController.text,
          'startDate': _startDate,
          'reminderTimes': reminderTimes.map((time) => {'hour': time.hour, 'minute': time.minute}).toList(),
        });
        // UI feedback for success
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Medication added successfully!',
              style: TextStyle(
                color: Colors.green,
              ),
            ),
          ),
        );
      } catch (e) {
        // UI feedback for error
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding medication: $e'))
        );
      }
    } else {
      // UI feedback for no user logged in
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No user logged in!'))
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100],
        title: const Text(
          'Add Medicine',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarMedicine()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.list_sharp),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ListMedications()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Medicine Type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 5),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _medicationTypes.map((String label) {
                  int idx = _medicationTypes.indexOf(label);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        label,
                        style: TextStyle(
                          fontWeight: idx == _medicationTypes.indexOf(_selectedType)
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: _selectedType == label,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedType = label;
                        });
                      },
                      selectedColor: Colors.lightBlue[500],
                      backgroundColor: Colors.grey[200],
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              shadowColor: Colors.blueAccent.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Medicine Name Section
                    const Text(
                      'Medicine Name',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _medicineNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter the medicine name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple, width: 2.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.medication, color: Colors.purple),
                        filled: true,
                        fillColor: Colors.blue[50],
                        contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                      ),
                      style: TextStyle(fontSize: 16.0),
                      cursorColor: Colors.black54,
                    ),
                    const SizedBox(height: 15),
                    // Medicine Dose Section
                    const Text(
                      'Medicine Dose (mg)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _medicineDoseController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter dose in mg',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.purple, width: 2.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        prefixIcon: Icon(Icons.line_weight, color: Colors.purple),
                        filled: true,
                        fillColor: Colors.lightBlue[50],
                        contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                      ),
                      style: TextStyle(fontSize: 16.0),
                      cursorColor: Colors.black54,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Dosage (per day)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _decrementFrequency,
                              icon: Icon(Icons.remove_circle, color: Colors.purple),
                            ),
                            Text(
                              '$_dosageFrequency',
                              style: TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              onPressed: _incrementFrequency,
                              icon: Icon(Icons.add_circle, color: Colors.purple),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Reminder Toggle with Enhanced Design
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.alarm, color: Colors.redAccent, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Set Reminder',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  Transform.scale(
                    scale: 1.0,
                    child: Switch(
                      value: _isReminderSet,
                      onChanged: (bool value) {
                        setState(() {
                          _isReminderSet = value;
                        });
                      },
                      activeTrackColor: Colors.red[200],
                      activeColor: Colors.red,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),

            // New Card Section
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              shadowColor: Colors.blueAccent.withOpacity(0.5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.only(right: 10), // Adding padding to create space between the text and the dropdown
                            child: const Text('Start Date',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(
                            decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.black)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _startDate == null ? 'Select Date' : DateFormat('dd/MM/yyyy').format(_startDate!),
                                icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                                iconSize: 24,
                                elevation: 16,
                                style: TextStyle(color: Colors.blue[900], fontSize: 16),
                                onChanged: (String? newValue) async {
                                  if (newValue == 'Select Date') {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (pickedDate != null && pickedDate != _startDate) {
                                      setState(() {
                                        _startDate = pickedDate;
                                      });
                                    }
                                  }
                                },
                                items: [
                                  DropdownMenuItem<String>(
                                    value: 'Select Date',
                                    child: Text('Select Date'),
                                  ),
                                  if (_startDate != null)
                                    DropdownMenuItem<String>(
                                      value: DateFormat('dd/MM/yyyy').format(_startDate!),
                                      child: Text(DateFormat('dd/MM/yyyy').format(_startDate!)),
                                    ),
                                ].toList(),
                                isExpanded: true,
                                dropdownColor: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Reminder Times', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black)),
                    SizedBox(height: 10),
                    ...reminderTimes.asMap().entries.map((entry) {
                      int idx = entry.key;
                      TimeOfDay time = entry.value;
                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.black, backgroundColor: Colors.blue[100], // foreground
                              ),
                              child: Text(time.format(context)),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                            onPressed: () => _deleteReminder(idx),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: Colors.blue[300]),
                            onPressed: _addNewReminder,
                          ),
                        ],
                      );
                    }).toList(),
                    if (reminderTimes.isEmpty)
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, color: Colors.blue[300]),
                        onPressed: _addNewReminder,
                      ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _reminderTime,
                      decoration: InputDecoration(
                        labelText: 'Reminder Times',
                        labelStyle: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurple, width: 2.5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        prefixIcon: Icon(Icons.access_time, color: Colors.deepPurple),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _reminderTime = newValue!;
                        });
                      },
                      items: ['Once', 'Twice', 'Thrice', 'Every Hour']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _duration,
                      decoration: InputDecoration(
                        labelText: 'Duration',
                        labelStyle: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurple, width: 2.5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        prefixIcon: Icon(Icons.calendar_today, color: Colors.deepPurple),
                        filled: true,
                        fillColor: Colors.deepPurple.withOpacity(0.05),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      ),
                      onChanged: (String? newValue) {
                        setState(() {
                          _duration = newValue!;
                        });
                      },
                      items: ['10 days','1 Week', '2 Weeks','1 Month', '3 Months', '6 Months']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              shadowColor: Colors.blueAccent.withOpacity(0.5),
              child: Column(
                children: <Widget>[
                  ListTile(
                    title: const Text(
                      'Additional Note?',
                      style: TextStyle(
                        fontSize: 16.0, // Larger font size for better readability
                        fontWeight: FontWeight.bold, // Makes the text bold
                        color: Colors.black54, // Adds a custom color to the title
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        size: 24.0, // Larger icon size for better interaction
                        color: Colors.black, // Icon color matches the theme
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                    ),
                  ),
                  AnimatedSize(
                    duration: Duration(milliseconds: 200), // Smooth transition for the dropdown
                    child: Visibility(
                      visible: _isExpanded,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: _sideNoteController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Type Here',
                            labelStyle: const TextStyle(
                              color: Colors.black54,
                            ),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                color: Colors.black,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                color: Colors.grey,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(
                                color: Colors.purple,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.note,
                              color: Colors.purple,
                            ),
                          ),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Center(
              child: ElevatedButton(
                onPressed: _saveMedication,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 10),
                  elevation: 2,
                ),
                child: const Text(
                  'Add Schedule',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}