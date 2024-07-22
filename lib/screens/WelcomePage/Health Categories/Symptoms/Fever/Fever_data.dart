import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Fever/Fever_Details.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class FeverPage extends StatefulWidget {
  const FeverPage({super.key});

  @override
  State<FeverPage> createState() => _FeverPageState();
}

class _FeverPageState extends State<FeverPage> with SingleTickerProviderStateMixin {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  double? _temperature;
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _timeFormat = DateFormat('hh:mm a');
  late AnimationController _animationController;
  double _currentTemperature = 36.5;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _submitDetails() async {
    // Check if the necessary fields are filled
    if (_currentTemperature == null || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields before submitting.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

    // Combining selected date and time into one DateTime object
    DateTime fullDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // Round the temperature to two decimal places
    double roundedTemperature = double.parse(_currentTemperature.toStringAsFixed(1));

    // Data to be uploaded
    Map<String, dynamic> data = {
      'temperature': roundedTemperature,
      'dateTime': fullDateTime,
      'userId': user.uid
    };

    // Attempt to submit the data to Firestore
    try {
      await FirebaseFirestore.instance.collection('Fever').add(data);
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.lightBlue[100],
      child: SizeTransition(
        sizeFactor: _animationController,
        axisAlignment: 0.0,
        child: ExpansionTile(
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset('images/fever.png'),
          ),
        title: const Text(
          "Fever",
          style: TextStyle(
            fontSize: 19,
            color: Colors.black,
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
                        builder: (context) =>const FeverDetails()),
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
          const SizedBox(height: 5),
          _temperatureSlider(),
          _dateSelection(),
          _timeSelection(),
          const SizedBox(height: 5),
          _actionButtonsRow(),
          const SizedBox(height: 10),
        ],
        ),
      ),
    );
  }

  Widget _temperatureSlider() {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Temperature (°C): ${_currentTemperature.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.red[700],
            inactiveTrackColor: Colors.red[100],
            trackShape: RoundedRectSliderTrackShape(),
            trackHeight: 4.0,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
            thumbColor: Colors.redAccent,
            overlayColor: Colors.red.withAlpha(32),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 28.0),
            tickMarkShape: RoundSliderTickMarkShape(),
            activeTickMarkColor: Colors.red[700],
            inactiveTickMarkColor: Colors.red[100],
            valueIndicatorShape: PaddleSliderValueIndicatorShape(),
            valueIndicatorColor: Colors.redAccent,
            valueIndicatorTextStyle: TextStyle(
              color: Colors.white,
            ),
          ),
          child: Slider(
            value: _currentTemperature,
            min: 32.0,
            max: 42.0,
            divisions: 100,
            label: _currentTemperature.toStringAsFixed(1),
            onChanged: (double value) {
              setState(() {
                _currentTemperature = value;
              });
            },
          ),
        ),
      ],
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
          Text('Time: ${_timeFormat.format(tempDateTime)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton(
            onPressed: () => _selectTime(context),
            child: const Text('Select Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Container(
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 36, minWidth: 100),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
            child: const Text(
              'Submit',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        SizedBox(width: 12), // Adds some spacing to the right of the button
      ],
    );
  }

}