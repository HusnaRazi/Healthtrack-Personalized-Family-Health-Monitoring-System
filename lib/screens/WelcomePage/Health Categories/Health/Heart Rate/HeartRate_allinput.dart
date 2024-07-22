import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HeartRateAllData extends StatefulWidget {
  const HeartRateAllData({Key? key}) : super(key: key);

  @override
  State<HeartRateAllData> createState() => _HeartRateAllDataState();
}

class _HeartRateAllDataState extends State<HeartRateAllData> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? selectedDate;

  Future<List<Map<String, dynamic>>> fetchHeartRateData() async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('Heart Rate');

      if (selectedDate != null) {
        DateTime startOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
        DateTime endOfDay = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day, 23, 59, 59);

        // Convert startOfDay and endOfDay to Timestamps
        Timestamp startTimestamp = Timestamp.fromDate(startOfDay);
        Timestamp endTimestamp = Timestamp.fromDate(endOfDay);

        // Adjust the query to filter documents within the selected date
        query = query.where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
            .where('timestamp', isLessThanOrEqualTo: endTimestamp);
      }

      QuerySnapshot<Map<String, dynamic>> querySnapshot = await query.get();

      List<Map<String, dynamic>> heartRates = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> data = doc.data();
        data['id'] = doc.id;
        heartRates.add(data);
      }
      return heartRates;
    } catch (e) {
      print(e); // Ideally, handle the error more gracefully
      return [];
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(), // Use the current selected date if available, otherwise current date
      firstDate: DateTime(2000), // Adjust this to your requirement
      lastDate: DateTime.now(), // Last date is today
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _showHeartRateEditDialog(BuildContext context, Map<String, dynamic> heartRateData) async {
    TextEditingController rateController = TextEditingController(text: heartRateData['bpm'].toString());
    DateTime dateTime = (heartRateData['timestamp'] as Timestamp).toDate();
    DateTime newDate = dateTime;
    TimeOfDay newTime = TimeOfDay.fromDateTime(dateTime);

    GlobalKey<FormState> _formKey = GlobalKey<FormState>();  // Add a form key for validation

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Heart Rate Data',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey, // Set form key
              child: ListBody(
                children: <Widget>[
                  SizedBox(height: 5),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Heart Rate: ',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: rateController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 16.0, color: Colors.black),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            hintText: 'Enter BPM',
                            border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(5)
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: const Text("Select Date"),
                      subtitle: Text("${newDate.day}-${newDate.month}-${newDate.year}"),
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
                  _updateHeartRateData(heartRateData['id'], rateController.text, newDate, newTime);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateHeartRateData(String docId, String bpm, DateTime date, TimeOfDay time) async {
    int bpmValue = int.tryParse(bpm) ?? 0; // Validate and parse the input
    DateTime newDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await _firestore.collection('Heart Rate').doc(docId).update({
      'bpm': bpmValue, // Changed 'rate' to 'bpm' in the database field as well
      'timestamp': Timestamp.fromDate(newDateTime),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data updated successfully')),
    );

    setState(() {}); // Refresh the list to show updated data
  }

  Widget buildHeartRateCard(Map<String, dynamic> heartRateData) {
    DateTime timestamp = (heartRateData['timestamp'] as Timestamp).toDate();
    String bpm = heartRateData['bpm'].toString();
    String date = DateFormat('dd/MM/yyyy').format(timestamp); // Use DateFormat for date
    String time = DateFormat('hh:mm a').format(timestamp); // Format time to 12-hour format with AM/PM

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
              colors: [Colors.lightBlue[100]!, Colors.lightBlue[300]!],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BPM: $bpm',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),
              Text(
                'Date: $date',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey[700]),
              ),
              Text(
                'Time: $time',
                style: TextStyle(fontSize: 14, color: Colors.blueGrey[700]),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Edit button
                  ElevatedButton.icon(
                    onPressed: () {
                      _showHeartRateEditDialog(context, heartRateData);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.lightGreen, // Text color
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
                                  await _firestore.collection('Heart Rate').doc(heartRateData['id']).delete();
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
        backgroundColor: Colors.lightBlue[100],
        title: const Text('Heart Rate Data'),
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5),
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
              future: fetchHeartRateData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return buildHeartRateCard(snapshot.data![index]);
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
