import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HeadacheAllData extends StatefulWidget {
  const HeadacheAllData({super.key});

  @override
  State<HeadacheAllData> createState() => _HeadacheAllDataState();
}

class _HeadacheAllDataState extends State<HeadacheAllData> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = null;  // Set to null to load all data initially
  }

  Stream<List<HeadacheData>> getHeadacheDataStream() {
    Query<Map<String, dynamic>> query = _firestore.collection('Headaches');

    if (selectedDate != null) {
      DateTime startOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
      DateTime endOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 23, 59, 59);
      query = query
          .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return HeadacheData.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
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

  Future<void> _deleteHeadacheData(String id) async {
    try {
      await _firestore.collection('Headaches').doc(id).delete();
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
                await _deleteHeadacheData(id);
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

  void _showEditDialog(HeadacheData headacheData) {
    TextEditingController typeController = TextEditingController(text: headacheData.type);
    TextEditingController severityController = TextEditingController(text: headacheData.severity);
    DateTime selectedStartDate = headacheData.startDateTime;
    TimeOfDay selectedStartTime = TimeOfDay.fromDateTime(headacheData.startDateTime);
    DateTime selectedEndDate = headacheData.endDateTime;
    TimeOfDay selectedEndTime = TimeOfDay.fromDateTime(headacheData.endDateTime);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Headache Record", style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.redAccent,
          ),),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(
                    labelText: "Area",
                    prefixIcon: Icon(Icons.label),
                    border: InputBorder.none,  // Removes underline
                  ),
                ),
                TextField(
                  controller: severityController,
                  decoration: const InputDecoration(
                    labelText: "Severity",
                    prefixIcon: Icon(Icons.upgrade),
                    border: InputBorder.none,  // Removes underline
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text("Date: ${DateFormat('dd/MM/yyyy').format(selectedStartDate)}"),
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
                  leading: Icon(Icons.access_time),
                  title: Text("Start Time: ${selectedStartTime.format(context)}"),
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
                ListTile(
                  leading: Icon(Icons.access_time),
                  title: Text("End Time: ${selectedEndTime.format(context)}"),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedEndTime,
                    );
                    if (picked != null && picked != selectedEndTime) {
                      setState(() {
                        selectedEndTime = picked;
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
                String newType = typeController.text;
                String newSeverity = severityController.text;
                DateTime newStartDateTime = DateTime(
                  selectedStartDate.year,
                  selectedStartDate.month,
                  selectedStartDate.day,
                  selectedStartTime.hour,
                  selectedStartTime.minute,
                );
                DateTime newEndDateTime = DateTime(
                  selectedEndDate.year,
                  selectedEndDate.month,
                  selectedEndDate.day,
                  selectedEndTime.hour,
                  selectedEndTime.minute,
                );

                _updateHeadacheData(headacheData.id, newType, newSeverity, newStartDateTime, newEndDateTime);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateHeadacheData(String id, String newType, String newSeverity, DateTime newStartDateTime, DateTime newEndDateTime) async {
    try {
      await _firestore.collection('Headaches').doc(id).update({
        'type': newType,
        'severity': newSeverity,
        'startDateTime': Timestamp.fromDate(newStartDateTime),
        'endDateTime': Timestamp.fromDate(newEndDateTime),
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

  Widget buildHeadacheCard(HeadacheData headacheData) {
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
            title: Text('${headacheData.type}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Text(
                'Severity: ${headacheData.severity}\n'
                    'Date: ${DateFormat('dd/MM/yyyy').format(headacheData.startDateTime)}\n'
                    'Start: ${DateFormat('hh:mm a').format(headacheData.startDateTime)}\n'
                    'End: ${DateFormat('hh:mm a').format(headacheData.endDateTime)}'
            ),
            leading: Icon(Icons.health_and_safety, color: Colors.red),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green),
                  onPressed: () {
                    _showEditDialog(headacheData);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () {
                    _showDeleteConfirmationDialog(headacheData.id);
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
        title: const Text('Headache Records',
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
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  const Icon(Icons.edit),
                ],
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<HeadacheData>>(
              stream: getHeadacheDataStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) => buildHeadacheCard(snapshot.data![index]),
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

class HeadacheData {
  final String id;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String type;
  final String severity;

  HeadacheData({
    required this.id,
    required this.startDateTime,
    required this.endDateTime,
    required this.type,
    required this.severity,
  });

  factory HeadacheData.fromFirestore(Map<String, dynamic> firestoreData, String id) {
    return HeadacheData(
      id: id,
      startDateTime: (firestoreData['startDateTime'] as Timestamp).toDate(),
      endDateTime: (firestoreData['endDateTime'] as Timestamp).toDate(),
      type: firestoreData['type'] as String,
      severity: firestoreData['severity'] as String,
    );
  }
}
