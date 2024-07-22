import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BloodPressureAllData extends StatefulWidget {
  const BloodPressureAllData({Key? key}) : super(key: key);

  @override
  State<BloodPressureAllData> createState() => _BloodPressureAllDataState();
}

class _BloodPressureAllDataState extends State<BloodPressureAllData> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? selectedDate;

  Future<List<Map<String, dynamic>>> fetchBloodPressureData() async {
    Query<Map<String, dynamic>> query = _firestore.collection('Blood Pressure');

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

  Future<void> _showEditDialog(BuildContext context, Map<String, dynamic> bloodPressureData) async {
    TextEditingController systolicController = TextEditingController(text: bloodPressureData['systolic'].toString());
    TextEditingController diastolicController = TextEditingController(text: bloodPressureData['diastolic'].toString());
    DateTime selectedEditDate = (bloodPressureData['timestamp'] as Timestamp).toDate();
    TimeOfDay selectedEditTime = TimeOfDay.fromDateTime(selectedEditDate);
    final _formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Text('Edit Blood Pressure Data', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: systolicController,
                      decoration: InputDecoration(
                        labelText: 'Systolic (mmHg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        prefixIcon: Icon(Icons.trending_up),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter systolic value';
                        }
                        return null;
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: diastolicController,
                      decoration: InputDecoration(
                        labelText: 'Diastolic (mmHg)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        prefixIcon: Icon(Icons.trending_down),
                        filled: true,
                        fillColor: Colors.grey[200],
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter diastolic value';
                        }
                        return null;
                      },
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.calendar_month_rounded),
                    title: const Text("Select Date"),
                    subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedEditDate)),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedEditDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedEditDate = picked;
                        });
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.access_time_rounded),
                    title: const Text("Select Time"),
                    subtitle: Text(selectedEditTime.format(context)),
                    onTap: () async {
                      final TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: selectedEditTime,
                      );
                      if (picked != null) {
                          selectedEditTime = picked;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.blue, // foreground
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: const Text('Save'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final DateTime combinedDateTime = DateTime(
                    selectedEditDate.year,
                    selectedEditDate.month,
                    selectedEditDate.day,
                    selectedEditTime.hour,
                    selectedEditTime.minute,
                  );
                  updateBloodPressureData(
                    bloodPressureData['id'],
                    int.parse(systolicController.text),
                    int.parse(diastolicController.text),
                    combinedDateTime,
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

  void updateBloodPressureData(String docId, int systolic, int diastolic, DateTime date) async {
    await _firestore.collection('Blood Pressure').doc(docId).update({
      'systolic': systolic,
      'diastolic': diastolic,
      'timestamp': Timestamp.fromDate(date),
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Blood pressure data updated successfully')),
    );
    setState(() {});
  }

  Widget buildBloodPressureCard(Map<String, dynamic> bloodPressureData) {
    DateTime dateTime = (bloodPressureData['timestamp'] as Timestamp).toDate();
    String systolic = bloodPressureData['systolic'].toString();
    String diastolic = bloodPressureData['diastolic'].toString();
    String date = DateFormat('dd-MM-yyyy').format(dateTime);
    String time = DateFormat('h:mm a').format(dateTime);

    return Padding(
      padding: const EdgeInsets.only(right: 8, left: 8, top: 8),
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
                'Blood Pressure: $systolic/$diastolic mmHg',
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
                      await _showEditDialog(context, bloodPressureData);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.lightGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
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
                                  await _firestore.collection('Blood Pressure').doc(bloodPressureData['id']).delete();
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
                      foregroundColor: Colors.white, backgroundColor: Colors.redAccent,
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
        title: const Text('Blood Pressure Data'),
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
      backgroundColor: Colors.lightBlue[100],
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
              future: fetchBloodPressureData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No data found for this date.'));
                }
                return ListView(
                  children: snapshot.data!.map((data) =>
                      buildBloodPressureCard(data)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
