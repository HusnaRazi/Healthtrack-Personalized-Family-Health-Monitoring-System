import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Medications/ListMedications_Card.dart';
import 'package:intl/intl.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Medications/AddMedicine.dart';

class MedicationPage extends StatefulWidget {
  const MedicationPage({Key? key}) : super(key: key);

  @override
  State<MedicationPage> createState() => _MedicationPageState();
}

class _MedicationPageState extends State<MedicationPage> {
  List<Map<String, dynamic>> medications = [];

  @override
  void initState() {
    super.initState();
  }

  List<Map<String, dynamic>> fetchTodayMedications(QuerySnapshot snapshot) {
    DateTime today = DateTime.now();
    DateFormat dateFormatter = DateFormat('yMd');
    DateFormat timeFormatter = DateFormat('h:mm a'); // 12-hour format with AM/PM

    List<Map<String, dynamic>> fetchedMedications = [];
    for (var doc in snapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      DateTime startDate = (data['startDate'] as Timestamp).toDate();

      // Check if the medication is for today
      if (dateFormatter.format(startDate) == dateFormatter.format(today)) {
        List<dynamic> reminderTimes = data['reminderTimes'];
        for (var time in reminderTimes) {
          DateTime fullTime = DateTime(today.year, today.month, today.day,
              time['hour'], time['minute']);
          String formattedTime = timeFormatter.format(fullTime); // Formatting the time

          fetchedMedications.add({
            'id': doc.id, // Document ID to update the done status
            'name': '${data['medicineName']} ${data['dosage']}mg',
            'time': formattedTime, // Using formatted time
            'done': data['done'] ?? false, // Fetch done status
          });
        }
      }
    }

    return fetchedMedications;
  }

  Future<void> toggleDone(int index) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String medicationId = medications[index]['id'];
      bool newDoneStatus = !medications[index]['done'];

      try {
        // Update the 'done' status in Firestore
        await FirebaseFirestore.instance
            .collection('Medication Reminder')
            .doc(user.uid)
            .collection('Medicine')
            .doc(medicationId)
            .update({'done': newDoneStatus});

        // Update the local state
        setState(() {
          medications[index]['done'] = newDoneStatus;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating medication status: $e')));
      }
    }
  }

  void _navigateToAddMedication(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddMedicationPage()),
    ).then((value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Returned from Add Medication page')),
      );
      // No need to call fetchTodayMedications here since StreamBuilder will handle updates
    });
  }

  void removeMedication(int index) {
    setState(() {
      medications.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    var user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Center(
        child: Text('No user logged in!'),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('Medication Reminder')
          .doc(user.uid)
          .collection('Medicine')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No medications added yet for today.'),
          );
        }

        // Fetch today's medications whenever there's new data
        medications = fetchTodayMedications(snapshot.data!);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 3),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Medication'),
                        onPressed: () => _navigateToAddMedication(context),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8), // Space between the buttons
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.list),
                        label: const Text('List Medications'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ListMedications()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.green, // Use a different color for distinction
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  "Today's Reminders:",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ...medications.map((med) => Card(
                color: med['done'] ? Colors.green[100] : Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Image.asset('images/medicine.png', width: 24, height: 24),
                  title: Text(med['name']),
                  subtitle: Text(med['time']),
                  trailing: IconButton(
                    icon: Icon(med['done'] ? Icons.check_circle : Icons.check_circle_outline),
                    onPressed: () => toggleDone(medications.indexOf(med)),
                  ),
                ),
              )).toList(),
            ],
          ),
        );
      },
    );
  }
}
