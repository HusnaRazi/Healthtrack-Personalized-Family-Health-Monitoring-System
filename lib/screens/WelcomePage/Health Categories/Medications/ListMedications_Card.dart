import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Medications/EditMedication%20Page.dart';
import 'package:intl/intl.dart';

class ListMedications extends StatefulWidget {
  const ListMedications({super.key});

  @override
  State<ListMedications> createState() => _ListMedicationsState();
}

class _ListMedicationsState extends State<ListMedications> {
  List<Map<String, dynamic>> medications = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMedications();
  }

  Future<void> fetchMedications() async {
    setState(() {
      isLoading = true;
    });

    try {
      var user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var snapshot = await FirebaseFirestore.instance
            .collection('Medication Reminder')
            .doc(user.uid)
            .collection('Medicine')
            .get();

        List<Map<String, dynamic>> fetchedMedications = snapshot.docs.map((doc) {
          var data = doc.data();
          data['id'] = doc.id; // Save document ID for potential operations like edit/delete
          return data;
        }).toList();

        setState(() {
          medications = fetchedMedications;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No user logged in!'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching medications: $e'))
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void refreshMedicationDetails() {
    fetchMedications(); // Calls fetchMedicationDetails again to refresh data
  }

  void navigateToEditMedication(BuildContext context, String medicationId) {
    // Assuming you have a route or a screen setup for editing medications
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => EditMedicationPage(medicationId: medicationId),
    )).then((result) {
      // Optionally refresh the list after editing
      if (result != null && result == true) {
        fetchMedications(); // Refresh medications list
      }
    });
  }

  void deleteMedication(String medicationId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this medication?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('Medication Reminder')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .collection('Medicine')
                      .doc(medicationId)
                      .delete();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Medication deleted successfully')));
                  fetchMedications(); // Refresh the list after deletion
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting medication')));
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List of Medications', style: TextStyle(
            color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.lightBlue[100],
        actions: [
          IconButton(icon: Icon(Icons.search),
            onPressed: refreshMedicationDetails, // Refresh button action
            tooltip: 'Refresh Details',
          ),
          IconButton(icon: Icon(Icons.refresh), onPressed: fetchMedications),
        ],
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : Container(
          color: Colors.lightBlue[100], // Set the background color of the body
          child: medications.isEmpty ? Center(
            child: Text('No medications added yet.',
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          ) : ListView.builder(
            itemCount: medications.length,
            itemBuilder: (context, index) {
              var med = medications[index];
              return Card(
                elevation: 4,
                margin: EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  isThreeLine: true,
                  leading: Image.asset('images/pills.png', width: 24, height: 24),
                  title: Text('${med['medicineName']} ${med['dosage']}mg',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Intake: ${med['dosageFrequency']} times per day\nDuration: ${med['duration']}'),
                  trailing: IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () =>
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => buildBottomSheetMenu(context, med),
                        ),
                  ),
                  onTap: () => showMedicationDetails(context, med),
                ),
              );
            },
          ),
        ),
      );
    }

  Widget buildBottomSheetMenu(BuildContext context, Map<String, dynamic> med) {
    return Wrap(
      children: [
        ListTile(leading: Icon(Icons.edit), title: Text('Edit'), onTap: () {
          Navigator.pop(context);
          navigateToEditMedication(context, med['id']);
        }),
        ListTile(leading: Icon(Icons.delete), title: Text('Delete'), onTap: () {
          Navigator.pop(context);
          deleteMedication(med['id']);
        }),
      ],
    );
  }

  void showMedicationDetails(BuildContext context, Map<String, dynamic> med) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
            title: Text(
              med['medicineName'],
              style: TextStyle(
                color: Colors.blue[800], // Set the color to dark blue specifically
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailText("Type", med['medicineType']),
                _buildDetailText("Dosage", "${med['dosage']} mg"),
                _buildDetailText(
                    "Frequency", "${med['dosageFrequency']} times per day"),
                _buildDetailText("Duration", med['duration']),
                _buildDetailText("Start Date",
                    DateFormat('dd-MM-yyyy').format(med['startDate'].toDate())),
                ...med['reminderTimes'].map<Widget>((t) =>
                    _buildDetailText("Reminder at", _formatTime(t))).toList(),
                med['sideNotes'].isNotEmpty ? _buildDetailText(
                    "Notes", med['sideNotes']) : SizedBox(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3, // Adjust the flex to allocate space to the label and value proportionally
            child: Text(
              "$label: ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          Expanded(
            flex: 2, // Gives less space for the value, adjusting these flex values helps in alignment
            child: Text(
              value,
              textAlign: TextAlign.right, // This aligns the text to the right of its container
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }


  String _formatTime(Map<String, dynamic> time) {
    final DateTime fakeDate = DateTime(2000, 1, 1, time['hour'],
        time['minute']); // Create a DateTime object to format time
    return DateFormat('h:mm a').format(
        fakeDate); // 'h:mm a' for 12-hour format with AM/PM
  }
}


