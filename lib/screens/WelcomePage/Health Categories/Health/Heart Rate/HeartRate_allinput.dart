import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HeartRateAllData extends StatefulWidget {
  const HeartRateAllData({Key? key}) : super(key: key);

  @override
  State<HeartRateAllData> createState() => _HeartRateAllDataState();
}

class _HeartRateAllDataState extends State<HeartRateAllData> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? selectedDate; // Changed to nullable DateTime

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

  Widget buildHeartRateCard(Map<String, dynamic> heartRateData) {
    DateTime timestamp = (heartRateData['timestamp'] as Timestamp).toDate();
    String bpm = heartRateData['bpm'].toString();
    String date = '${timestamp.day.toString().padLeft(2, '0')}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.year}';
    String time = '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

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
                      // Implement your edit functionality
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
