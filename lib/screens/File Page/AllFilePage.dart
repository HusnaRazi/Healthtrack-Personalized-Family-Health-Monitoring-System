import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/File%20Page/PdfView.dart';
import 'package:intl/intl.dart';

class FileDisplay extends StatefulWidget {
  @override
  State<FileDisplay> createState() => _FileDisplayState();
}

class _FileDisplayState extends State<FileDisplay> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('uploads')
        .where('uid', isEqualTo: user?.uid)
        .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Map<String, dynamic>> files = [];
        snapshot.data!.docs.forEach((document) {
          Map<String, dynamic> fileData = document.data() as Map<String, dynamic>;

          // Extract the timestamp
          Timestamp timestamp = fileData['dateUploaded'];

          // Format the timestamp to display only the date
          String date = timestamp != null
              ? DateFormat('dd/MM/yyyy').format(timestamp.toDate())
              : '';

          // Directly using 'Date Treatment' as a String
          String dateTreatment = fileData['Date Treatment'] ?? '';

          files.add({
            'title': fileData['title'],
            'doctor': fileData['doctor'],
            'hospital': fileData['hospital'],
            'date': date,
            'dateTreatment': dateTreatment,
          });
        });

        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 5.0),
              ListView.builder(
                shrinkWrap: true,
                itemCount: files.length,
                itemBuilder: (BuildContext context, int index) {
                  // Extracting data for each file
                  String title = files[index]['title'];
                  String doctor = files[index]['doctor'];
                  String hospital = files[index]['hospital'];
                  String date = files[index]['date'];
                  String dateTreatment = files[index]['dateTreatment'];

                  return Card(
                    elevation: 4.0,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Stack(
                      children: [
                        ListTile(
                          title: Text(title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Doctor: $doctor'),
                              Text('Hospital: $hospital'),
                              Text('Date Treatment: $dateTreatment'),
                              Text('Date Updated: $date'),
                            ],
                          ),
                          onTap: () {
                            String pdfUrl = snapshot.data!.docs[index]['pdfUrl'];
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => PdfView(pdfUrl: pdfUrl),
                            ));
                          },
                        ),
                        Positioned(
                          right: 5.0,
                          child: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              String documentId = snapshot.data!.docs[index].id;
                              showDeleteConfirmationDialog(context, documentId);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

void showDeleteConfirmationDialog(BuildContext context, String documentId) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this file?'),
        actions: <Widget>[
          TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () {
              FirebaseFirestore.instance.collection('uploads').doc(documentId).delete().then((_) {
                Navigator.of(context).pop(); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Report successfully deleted!")),
                );
              }).catchError((error) {
                Navigator.of(context).pop(); // Close the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error removing document: $error")),
                );
              });
            },
          ),
        ],
        );
      },
  );
}
