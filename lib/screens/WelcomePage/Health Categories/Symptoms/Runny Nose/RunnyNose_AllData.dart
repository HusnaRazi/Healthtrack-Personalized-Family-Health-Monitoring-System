import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RunnyNoseAllData extends StatefulWidget {
  const RunnyNoseAllData({super.key});

  @override
  State<RunnyNoseAllData> createState() => _RunnyNoseAllDataState();
}

class _RunnyNoseAllDataState extends State<RunnyNoseAllData> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = null; // Set to null to load all data initially
  }

  Stream<List<RunnyNoseData>> getRunnyNoseDataStream() {
    Query<Map<String, dynamic>> query = _firestore.collection('RunnyNose');

    if (selectedDate != null) {
      DateTime startOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
      DateTime endOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 23, 59, 59);
      query = query
          .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RunnyNoseData.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
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

  Future<void> _deleteRunnyNoseData(String id) async {
    try {
      await _firestore.collection('RunnyNose').doc(id).delete();
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
                await _deleteRunnyNoseData(id);
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

  void _showEditDialog(RunnyNoseData runnyNoseData) {
    TextEditingController severityController = TextEditingController(text: runnyNoseData.severity);
    DateTime selectedStartDate = runnyNoseData.startDateTime;
    TimeOfDay selectedStartTime = TimeOfDay.fromDateTime(runnyNoseData.startDateTime);

    // List of severity options
    final List<String> severityOptions = [
      'Not Present',
      'Mild',
      'Moderate',
      'Severe',
      'Very Severe'
    ];

    // Initialize selectedSeverity with current severity
    String selectedSeverity = runnyNoseData.severity;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Edit Runny Nose Record",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSeverity,
                  decoration: InputDecoration(
                    labelText: "Severity",
                    prefixIcon: Icon(Icons.warning, color: Colors.blueGrey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blueGrey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  items: severityOptions.map((String severity) {
                    return DropdownMenuItem<String>(
                      value: severity,
                      child: Text(severity),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedSeverity = newValue!;
                    });
                  },
                ),
                SizedBox(height: 16), // Space between elements
                ListTile(
                  leading: Icon(Icons.calendar_today, color: Colors.blueGrey),
                  title: Text(
                    "Date: ${DateFormat('dd/MM/yyyy').format(selectedStartDate)}",
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedStartDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null && picked != selectedStartDate) {
                      setState(() {
                        selectedStartDate = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.access_time, color: Colors.blueGrey),
                  title: Text(
                    "Start Time: ${selectedStartTime.format(context)}",
                    style: TextStyle(fontSize: 16),
                  ),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedStartTime,
                    );
                    if (picked != null && picked != selectedStartTime) {
                      setState(() {
                        selectedStartTime = picked;
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
            ElevatedButton(
              child: Text("Save"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                DateTime newStartDateTime = DateTime(
                  selectedStartDate.year,
                  selectedStartDate.month,
                  selectedStartDate.day,
                  selectedStartTime.hour,
                  selectedStartTime.minute,
                );

                _updateRunnyNoseData(runnyNoseData.id, selectedSeverity, newStartDateTime);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateRunnyNoseData(String id, String newSeverity, DateTime newStartDateTime) async {
    try {
      await _firestore.collection('RunnyNose').doc(id).update({
        'severity': newSeverity,
        'startDateTime': Timestamp.fromDate(newStartDateTime), // Ensure field name matches Firestore
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildRunnyNoseCard(RunnyNoseData runnyNoseData) {
    return Padding(
      padding: const EdgeInsets.all(8),
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
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            subtitle: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Severity: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '${runnyNoseData.severity}\n',
                  ),
                  TextSpan(
                    text: 'Date: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '${DateFormat('dd/MM/yyyy').format(runnyNoseData.startDateTime)}\n',
                  ),
                  TextSpan(
                    text: 'Start: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: '${DateFormat('hh:mm a').format(runnyNoseData.startDateTime)}\n',
                  ),
                ],
              ),
            ),
            leading: Icon(Icons.medical_services, color: Colors.red),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.green[900]),
                  onPressed: () {
                    _showEditDialog(runnyNoseData);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    _showDeleteConfirmationDialog(runnyNoseData.id);
                  },
                ),
              ],
            ),
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
        title: const Text('Runny Nose Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<RunnyNoseData>>(
              stream: getRunnyNoseDataStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) => buildRunnyNoseCard(snapshot.data![index]),
                  );
                } else {
                  return Center(child: Text('No records available'));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class RunnyNoseData {
  final String id;
  final DateTime startDateTime;
  final String severity;

  RunnyNoseData({
    required this.id,
    required this.startDateTime,
    required this.severity,
  });

  factory RunnyNoseData.fromFirestore(Map<String, dynamic> firestoreData, String id) {
    return RunnyNoseData(
      id: id,
      startDateTime: (firestoreData['startDateTime'] as Timestamp).toDate(), // Ensure correct field name
      severity: firestoreData['severity'] as String,
    );
  }
}
