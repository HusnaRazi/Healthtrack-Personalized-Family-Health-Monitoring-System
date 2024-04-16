import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:intl/intl.dart';

class ChestPainPage extends StatefulWidget {
  const ChestPainPage({Key? key}) : super(key: key);

  @override
  State<ChestPainPage> createState() => _ChestPainPageState();
}

class _ChestPainPageState extends State<ChestPainPage> {
  DateTime? _selectedTime;
  final DateFormat _dateFormat = DateFormat('dd-MM-yyyy HH:mm');
  String? _selectedCondition;

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(picked),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedTime = DateTime(picked.year, picked.month, picked.day, pickedTime.hour, pickedTime.minute);
        });
      }
    }
  }

  void _submitDetails() {
    // Handle the submission logic here
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details Submitted Successfully')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        margin: const EdgeInsets.all(12),
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        color: Colors.lightBlue[100],
        child: ExpansionTile(
          leading: Icon(LineAwesomeIcons.heartbeat, color: Colors.red[700], size: 30),
          title: const Text("Chest Pain", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _conditionDropdown(),
                  const SizedBox(height: 10),
                  _dateTimeSelection(),
                  _actionButtonsRow(),
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _conditionDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Condition',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
      ),
      value: _selectedCondition,
      items: <String>['Not Present', 'Present', 'Mild', 'Moderate', 'Severe']
          .map<DropdownMenuItem<String>>((String value) => DropdownMenuItem(value: value, child: Text(value)))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCondition = value;
        });
      },
    );
  }

  Widget _dateTimeSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(_selectedTime == null ? 'No time selected' : 'Time: ${_dateFormat.format(_selectedTime!)}'),
        TextButton(onPressed: () => _selectDateTime(context), child: const Text('Select Time')),
      ],
    );
  }

  Widget _actionButtonsRow() {
    ThemeData theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              // Navigate to detailed view or show more information
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8), // Provides padding for easier tapping
              child: Text(
                'Full Details',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline, // Underline to signify it is clickable
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton(
            onPressed: _submitDetails,
            style: ElevatedButton.styleFrom(
              foregroundColor: theme.primaryColorLight,
              backgroundColor: theme.primaryColor,
              elevation: 0,
            ).copyWith(elevation: ButtonStyleButton.allOrNull(0.0)),
            child: const Text('Submit'),
          ),
        ),
      ],
    );
  }
}
