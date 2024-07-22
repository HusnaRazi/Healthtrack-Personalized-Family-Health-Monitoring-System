import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class FeverAllData extends StatefulWidget {
  const FeverAllData({super.key});

  @override
  State<FeverAllData> createState() => _FeverAllDataState();
}

class _FeverAllDataState extends State<FeverAllData> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    // Set selectedDate to null to load all data initially
    selectedDate = null;
  }

  Stream<List<FeverData>> getFeverDataStream() {
    Query<Map<String, dynamic>> query = _firestore.collection('Fever');

    // Apply date filter only if selectedDate is not null
    if (selectedDate != null) {
      DateTime startOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
      DateTime endOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 23, 59, 59);
      query = query
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return FeverData.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _updateFeverData(String id, double newTemperature, DateTime newDateTime) async {
    try {
      await _firestore.collection('Fever').doc(id).update({
        'temperature': newTemperature,
        'dateTime': Timestamp.fromDate(newDateTime),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Fever record updated successfully"),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Failed to update fever record: $e"),
        backgroundColor: Colors.red,
      ));
    }
  }



  Widget buildFeverCard(FeverData feverData) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, left: 8, top: 8),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.lightBlue[100]!, Colors.lightBlue[300]!],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Temperature: ${feverData.temperature.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Date: ${DateFormat('dd/MM/yyyy').format(feverData.dateTime)}', style: const TextStyle(fontSize: 14)),
                    Text('Time: ${DateFormat('hh:mm a').format(feverData.dateTime)}', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.green),
                    onPressed: () => _showEditDialog(feverData),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => _deleteFeverData(feverData.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteFeverData(String id) async {
    try {
      await _firestore.collection('Fever').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fever record deleted successfully'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete fever record: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100],
        title: const Text('Fever Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: Column(
        children: [
          InkWell(
            onTap: () => _selectDate(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  Text(
                    'Select Date: ${selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate!) : 'All Data'}',
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_drop_down, color: Colors.blue),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<FeverData>>(
              stream: getFeverDataStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView(
                    children: snapshot.data!.map((feverData) => buildFeverCard(feverData)).toList(),
                  );
                } else {
                  return const Center(child: Text('No records available'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(FeverData feverData) {
    TextEditingController temperatureController = TextEditingController(text: feverData.temperature.toStringAsFixed(1));
    DateTime selectedDate = feverData.dateTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(feverData.dateTime);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Fever Record"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: temperatureController,
                  decoration: const InputDecoration(
                    labelText: "Temperature (°C)",
                    prefixIcon: Icon(Icons.thermostat_outlined),
                    border: InputBorder.none,  // Removes underline
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text(selectedTime.format(context)),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null && picked != selectedTime) {
                      setState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Save"),
              onPressed: () {
                double? newTemperature = double.tryParse(temperatureController.text);
                if (newTemperature != null) {
                  DateTime newDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  _updateFeverData(feverData.id, newTemperature, newDateTime);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Invalid temperature input"),
                    backgroundColor: Colors.red,
                  ));
                }
              },
            ),
          ],
        );
      },
    );
  }

}

class FeverData {
  final String id;
  final DateTime dateTime;
  final double temperature;

  FeverData({required this.id, required this.dateTime, required this.temperature});

  factory FeverData.fromFirestore(Map<String, dynamic> firestoreData, String id) {
    return FeverData(
      id: id,
      dateTime: (firestoreData['dateTime'] as Timestamp).toDate(),
      temperature: firestoreData['temperature'].toDouble(),
    );
  }
}
