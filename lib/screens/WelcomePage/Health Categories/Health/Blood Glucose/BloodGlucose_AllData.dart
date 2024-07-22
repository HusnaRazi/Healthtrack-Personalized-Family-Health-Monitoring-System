import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BloodGlucoseAllData extends StatefulWidget {
  const BloodGlucoseAllData({Key? key}) : super(key: key);

  @override
  State<BloodGlucoseAllData> createState() => _BloodGlucoseAllDataState();
}

class _BloodGlucoseAllDataState extends State<BloodGlucoseAllData> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? selectedDate;

  Future<List<Map<String, dynamic>>> fetchBloodGlucoseData() async {
    Query<Map<String, dynamic>> query = _firestore.collection('Blood Glucose');

    if (selectedDate != null) {
      DateTime startOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
      DateTime endOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 23, 59, 59);
      query = query.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));
    }

    QuerySnapshot<Map<String, dynamic>> querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
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

  Future<void> _showEditDialog(BuildContext context, Map<String, dynamic> bloodGlucoseData) async {
    // Controllers for text fields
    TextEditingController glucoseLevelController = TextEditingController(text: bloodGlucoseData['glucose'].toString());
    DateTime dateTime = (bloodGlucoseData['timestamp'] as Timestamp).toDate();
    DateTime newDate = dateTime;
    TimeOfDay newTime = TimeOfDay.fromDateTime(dateTime);

    // Form key for validation
    GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    // Display the dialog
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Blood Glucose Data'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: ListBody(
                children: <Widget>[
                  TextFormField(
                    controller: glucoseLevelController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Glucose Level (mg/dL)',
                      border: OutlineInputBorder(),
                      hintText: 'Enter glucose level',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a glucose level';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text("Select Date"),
                      subtitle: Text(DateFormat('dd-MM-yyyy').format(newDate)),
                    ),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: newDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        newDate = picked;
                      }
                    },
                  ),
                  InkWell(
                    child: ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text("Select Time"),
                      subtitle: Text(newTime.format(context)),
                    ),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: newTime,
                      );
                      if (picked != null) {
                        newTime = picked;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Assuming a method to update data is implemented
                  _updateBloodGlucoseData(
                      bloodGlucoseData['id'],
                      glucoseLevelController.text,
                      DateTime(newDate.year, newDate.month, newDate.day, newTime.hour, newTime.minute)
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _updateBloodGlucoseData(String id, String glucoseLevel, DateTime dateTime) async {
    int? glucose = int.tryParse(glucoseLevel);
    if (glucose != null) {
      try {
        await FirebaseFirestore.instance.collection('Blood Glucose').doc(id).update({
          'glucose': glucose,
          'timestamp': Timestamp.fromDate(dateTime),
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Blood glucose data updated successfully!'))
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update data: $e'))
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid glucose level entered'))
      );
    }
    setState(() {}); // Refresh the list to show updated data
  }

  Widget buildBloodGlucoseCard(Map<String, dynamic> bloodGlucoseData) {
    DateTime dateTime = (bloodGlucoseData['timestamp'] as Timestamp).toDate();
    String glucoseLevel = bloodGlucoseData['glucose'].toString();
    String date = DateFormat('dd-MM-yyyy').format(dateTime);
    String time = DateFormat('h:mm a').format(dateTime);

    return Padding(
      padding: const EdgeInsets.only(right: 8, left: 8),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), // Rounded corners
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.lightBlue[100]!, Colors.lightBlue[300]!], // Changed to light blue gradient
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Glucose Level: $glucoseLevel mg/dL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900], // Changed text color
                ),
              ),
              Text(
                'Date: $date',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey[700]), // Changed text color
              ),
              Text(
                'Time: $time',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey[700]), // Changed text color
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit button
                  ElevatedButton.icon(
                    onPressed: () async {
                      await _showEditDialog(context, bloodGlucoseData);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.lightGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Delete button
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Confirm Deletion"),
                            content: const Text("Are you sure you want to delete this entry?"),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await _firestore.collection('Blood Glucose').doc(bloodGlucoseData['id']).delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Data deleted successfully')),
                                  );
                                  setState(() {});
                                  Navigator.pop(context); // Close the dialog
                                },
                                child: const Text("Delete"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.redAccent,
                    ),
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
        backgroundColor: Colors.lightBlue[100], // Changed app bar background color
        title: const Text('Blood Glucose Data'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 20,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {}); // Refresh action
            },
            icon: Icon(Icons.refresh, color: Colors.black),
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100], // Changed background color
      body: Column(
        children: [
          InkWell(
            onTap: () => _selectDate(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: Colors.blueGrey[900]), // Calendar icon
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${selectedDate != null ? '${selectedDate!.day.toString().padLeft(2, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.year}' : 'All'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(Icons.edit, color: Colors.blueGrey[900], size: 20),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: fetchBloodGlucoseData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return buildBloodGlucoseCard(snapshot.data![index]);
                    },
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
