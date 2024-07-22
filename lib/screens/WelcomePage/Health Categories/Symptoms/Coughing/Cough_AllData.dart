import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CoughListdata extends StatefulWidget {
  const CoughListdata({Key? key}) : super(key: key);

  @override
  State<CoughListdata> createState() => _CoughListdataState();
}

class _CoughListdataState extends State<CoughListdata> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? selectedDate;

  Stream<List<CoughData>> getCoughDataStream() {
    Query<Map<String, dynamic>> query = _firestore.collection('Coughing');

    // Ensure selectedDate is not null before filtering
    if (selectedDate != null) {
      DateTime startOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
      DateTime endOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 23, 59, 59);
      query = query
          .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CoughData.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
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

  Future<void> _deleteCoughData(String id) async {
    try {
      await _firestore.collection('Coughing').doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmationDialog(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm Deletion"),
          content: const Text("Are you sure you want to delete this entry?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await _deleteCoughData(id);
                Navigator.of(context).pop(); // Close the dialog
                setState(() {}); // Refresh the UI after deletion
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(CoughData coughData) {
    TextEditingController severityController = TextEditingController(text: coughData.severity);
    DateTime selectedDateTime = coughData.startDateTime;
    TimeOfDay selectedStartTime = TimeOfDay.fromDateTime(coughData.startDateTime);
    TimeOfDay selectedEndTime = TimeOfDay.fromDateTime(coughData.endDateTime);
    String? selectedSeverity = coughData.severity;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("Edit Cough Data", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal[800]),),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text("Severity: "),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedSeverity,
                        decoration: const InputDecoration(border: InputBorder.none),
                        items: ['Not present', 'Mild', 'Moderate', 'Severe', 'Very Severe'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedSeverity = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text("Select Date"),
                  subtitle: Text(DateFormat('dd-MM-yyyy').format(selectedDateTime)),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          selectedStartTime.hour,
                          selectedStartTime.minute,
                        );
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text("Select Start Time"),
                  subtitle: Text(selectedStartTime.format(context)),
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedStartTime,
                    );
                    if (pickedTime != null) {
                      setState(() {
                        selectedStartTime = pickedTime;
                        selectedDateTime = DateTime(
                          selectedDateTime.year,
                          selectedDateTime.month,
                          selectedDateTime.day,
                          selectedStartTime.hour,
                          selectedStartTime.minute,
                        );
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text("Select End Time"),
                  subtitle: Text(selectedEndTime.format(context)),
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: selectedEndTime,
                    );
                    if (pickedTime != null) {
                      setState(() {
                        selectedEndTime = pickedTime;
                        selectedDateTime = DateTime(
                          selectedDateTime.year,
                          selectedDateTime.month,
                          selectedDateTime.day,
                          selectedEndTime.hour,
                          selectedEndTime.minute,
                        );
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await _updateCoughData(coughData.id, selectedSeverity ?? coughData.severity, selectedDateTime, selectedDateTime.add(Duration(hours: selectedEndTime.hour - selectedStartTime.hour, minutes: selectedEndTime.minute - selectedStartTime.minute)));
                Navigator.of(context).pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }


  Future<void> _updateCoughData(String id, String severity, DateTime startDateTime, DateTime endDateTime) async {
    try {
      await _firestore.collection('Coughing').doc(id).update({
        'severity': severity,
        'startDateTime': Timestamp.fromDate(startDateTime),
        'endDateTime': Timestamp.fromDate(endDateTime),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {}); // Refresh the UI after updating
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildCoughCard(CoughData coughData) {
    String date = DateFormat('dd/MM/yyyy').format(coughData.startDateTime);
    String startTime = DateFormat('h:mm a').format(coughData.startDateTime);
    String endTime = DateFormat('h:mm a').format(coughData.endDateTime);

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
                    Text('${coughData.severity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('Date: $date', style: const TextStyle(fontSize: 14)),
                    Text('Start Time: $startTime', style: const TextStyle(fontSize: 14)),
                    Text('End Time: $endTime', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.green),
                    onPressed: () {
                      _showEditDialog(coughData);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      _showDeleteConfirmationDialog(coughData.id);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100],
        title: const Text(
          'Cough Data',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
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
                    'Date: ${selectedDate != null ? DateFormat('dd/MM/yyyy').format(selectedDate!) : 'All'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<CoughData>>(
              stream: getCoughDataStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) => buildCoughCard(snapshot.data![index]),
                  );
                } else {
                  return const Center(child: Text("No data available"));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CoughData {
  final String id; // Added id field
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String severity;

  CoughData({
    required this.id, // Added id to the constructor
    required this.startDateTime,
    required this.endDateTime,
    required this.severity,
  });

  factory CoughData.fromFirestore(Map<String, dynamic> firestoreData, String id) {
    return CoughData(
      id: id, // Initialize id
      startDateTime: (firestoreData['startDateTime'] as Timestamp).toDate(),
      endDateTime: (firestoreData['endDateTime'] as Timestamp).toDate(),
      severity: firestoreData['severity'],
    );
  }
}
