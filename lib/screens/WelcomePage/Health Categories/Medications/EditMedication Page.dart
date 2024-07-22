import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EditMedicationPage extends StatefulWidget {
  final String medicationId;

  const EditMedicationPage({Key? key, required this.medicationId}) : super(key: key);

  @override
  _EditMedicationPageState createState() => _EditMedicationPageState();
}

class _EditMedicationPageState extends State<EditMedicationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _medicineTypeController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _dosageFrequencyController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _sideNotesController = TextEditingController();
  DateTime _startDate = DateTime.now();
  List<TimeOfDay> _reminderTimes = [TimeOfDay.now()];

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMedicationDetails();
  }

  void addReminder() => setState(() => _reminderTimes.add(TimeOfDay.now()));

  void removeReminder(int index) =>
      setState(() => _reminderTimes.removeAt(index));

  Future<void> fetchMedicationDetails() async {
    setState(() {
      isLoading = true;
    });
    try {
      DocumentSnapshot medicationDoc = await FirebaseFirestore.instance
          .collection('Medication Reminder')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('Medicine')
          .doc(widget.medicationId)
          .get();

      if (medicationDoc.exists) {
        Map<String, dynamic> data = medicationDoc.data() as Map<String,
            dynamic>;
        _medicineNameController.text = data['medicineName'];
        _medicineTypeController.text = data['medicineType'];
        _dosageController.text = data['dosage'];
        _dosageFrequencyController.text = data['dosageFrequency'].toString();
        _durationController.text = data['duration'];
        _sideNotesController.text = data['sideNotes'] ?? '';
        _startDate = (data['startDate'] as Timestamp).toDate();
        _reminderTimes = (data['reminderTimes'] as List).map((t) =>
            TimeOfDay(hour: t['hour'], minute: t['minute'])).toList();
      }
    } catch (e) {
      print("Error fetching data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateMedicationDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('Medication Reminder')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('Medicine')
          .doc(widget.medicationId)
          .update({
        'medicineName': _medicineNameController.text.trim(),
        'medicineType': _medicineTypeController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'dosageFrequency': _dosageFrequencyController.text.trim(),
        'duration': _durationController.text.trim(),
        'sideNotes': _sideNotesController.text.trim(),
        'startDate': Timestamp.fromDate(_startDate),
        'reminderTimes': _reminderTimes.map((t) =>
        {
          'hour': t.hour,
          'minute': t.minute
        }).toList(),
      });
      Navigator.pop(context, true);
    } catch (e) {
      print("Error updating details: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating medication details.')));
    }
  }

  void refreshMedicationDetails() {
    fetchMedicationDetails(); // Calls fetchMedicationDetails again to refresh data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Medication',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.lightBlue[100],
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black87),
            onPressed: refreshMedicationDetails, // Refresh button action
            tooltip: 'Refresh Details',
          )
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : buildForm(),
      backgroundColor: Colors.lightBlue[100], // Set the background color here
    );
  }

  Widget buildForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildTextField(_medicineNameController, 'Medicine Name',
                Icons.medical_services),
            SizedBox(height: 20),
            buildTextField(
                _medicineTypeController, 'Medicine Type', Icons.healing),
            SizedBox(height: 20),
            buildTextField(_dosageController, 'Dosage', Icons.exposure_plus_1),
            SizedBox(height: 20),
            buildTextField(
                _dosageFrequencyController, 'Dosage Frequency', Icons.repeat),
            SizedBox(height: 20),
            buildTextField(_durationController, 'Duration', Icons.timer),
            SizedBox(height: 20),
            buildTextField(_sideNotesController, 'Side Note', Icons.note_alt_outlined),
            SizedBox(height: 20),
            DatePickerField(
                label: 'Start Date',
                initialDate: _startDate,
                onDateSelected: (newDate) => setState(() => _startDate = newDate)),
            SizedBox(height: 20),  // Spacing between DatePicker and TimePicker
            ..._reminderTimes.asMap().entries.map((entry) {
              int idx = entry.key;
              TimeOfDay time = entry.value;
              return TimePickerField(
                label: 'Reminder ${idx + 1}',
                initialTime: time,
                onTimeSelected: (newTime) => setState(() => _reminderTimes[idx] = newTime),
                onDelete: () => removeReminder(idx),
                onAdd: addReminder,
              );
            }).toList(),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: updateMedicationDetails,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 10)),
              child: const Text('Update Details',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[800], // Adjust the color to match your theme
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        filled: true, // Enable the fill color for the text field
        fillColor: Colors.lightBlue[50], // A very light blue, similar to your example
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15), // More rounded corners
          borderSide: BorderSide(color: Colors.black54, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.black54, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.black54, width: 2.0),
        ),
        prefixIcon: Icon(icon, color: Colors.purple[300], size: 20), // Adjust color and size
      ),
      style: TextStyle(
        color: Colors.black, // Text color in the TextField
        fontSize: 16, // Text size
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}

class DatePickerField extends StatelessWidget {
  final String label;
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const DatePickerField({Key? key, required this.label, required this.initialDate, required this.onDateSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        DateTime? newDate = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.lightBlue, // header background color
                  onPrimary: Colors.white, // header text color
                  onSurface: Colors.black, // body text color
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.lightBlue[800], // button text color
                  ),
                ),
              ),
              child: child!,
            );
          },
        );
        if (newDate != null) {
          onDateSelected(newDate);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.lightBlue[100]!, Colors.lightBlue[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 6,
              offset: Offset(0, 2), // changes position of shadow
            ),
          ],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label: ${DateFormat('dd-MM-yyyy').format(initialDate)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Icon(Icons.event, color: Colors.purpleAccent, size: 24),
          ],
        ),
      ),
    );
  }
}

class TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeSelected;
  final VoidCallback onDelete;
  final VoidCallback onAdd;

  const TimePickerField({
    Key? key,
    required this.label,
    required this.initialTime,
    required this.onTimeSelected,
    required this.onDelete,
    required this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding( // Padding wrapper for margin control
      padding: EdgeInsets.only(bottom: 10), // Adds space between each TimePickerField instance
      child: InkWell(
        onTap: () async {
          TimeOfDay? newTime = await showTimePicker(
            context: context,
            initialTime: initialTime,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.lightBlue, // active color (header)
                    onPrimary: Colors.white, // text color on the active area
                    onSurface: Colors.black, // body text color
                  ),
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.lightBlue[800], // buttons text color
                    ),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (newTime != null) {
            onTimeSelected(newTime);
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Reduced padding
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.lightBlue[100]!, Colors.lightBlue[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 0,
                blurRadius: 4,
                offset: Offset(0, 1), // Reduced shadow effect
              ),
            ],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black, width: 1.0), // Thinner border
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$label: ${initialTime.format(context)}',
                  style: TextStyle(
                    fontSize: 16, // Smaller font size
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Wrap(
                spacing: 4, // Reduced spacing between icons
                children: [
                  IconButton(
                    icon: Icon(Icons.delete, size: 20, color: Colors.red), // Smaller icon size
                    onPressed: onDelete,
                    tooltip: 'Delete Reminder',
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 20, color: Colors.green), // Smaller icon size
                    onPressed: onAdd,
                    tooltip: 'Add New Reminder',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

