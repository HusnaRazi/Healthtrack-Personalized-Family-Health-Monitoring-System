import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ListOthersymptoms extends StatefulWidget {
  @override
  _ListOthersymptomsState createState() => _ListOthersymptomsState();
}

class _ListOthersymptomsState extends State<ListOthersymptoms> {
  DateTime? selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'List of Symptoms',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.lightBlue[100],
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: Colors.black),
            onPressed: () {
              _selectDate(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() {
                selectedDate = null;
              });
            },
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('symptoms')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No symptoms found'));
          }

          List<DocumentSnapshot> filteredDocs = snapshot.data!.docs;
          if (selectedDate != null) {
            filteredDocs = filteredDocs.where((doc) {
              DateTime docDate = (doc['timestamp'] as Timestamp).toDate();
              return docDate.year == selectedDate!.year &&
                  docDate.month == selectedDate!.month &&
                  docDate.day == selectedDate!.day;
            }).toList();
          }

          if (filteredDocs.isEmpty) {
            return Center(child: Text('No Data Available'));
          }

          return ListView.builder(
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot symptom = filteredDocs[index];
              return _buildSymptomTile(context, symptom, index);
            },
          );
        },
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    } else {
      setState(() {
        selectedDate = null;
      });
    }
  }


  Widget _buildSymptomTile(BuildContext context, DocumentSnapshot symptom, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Card(
        elevation: 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ListTile(
          leading: Icon(Icons.healing, color: Colors.blue),
          title: Text(
            symptom['symptom'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date: ${DateFormat('dd/MM/yyyy').format(symptom['timestamp'].toDate())}'),
              Text('Time: ${DateFormat('hh:mm a').format(symptom['timestamp'].toDate())}'),
              Text('Description: ${symptom['description']}'),
            ],
          ),
          onTap: () {
            _editSymptom(context, symptom);
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.green),
                onPressed: () {
                  _editSymptom(context, symptom);
                },
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  _deleteSymptom(context, symptom);
                },
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          tileColor: index.isEven ? Colors.grey[100] : Colors.white,
        ),
      ),
    );
  }

  void _editSymptom(BuildContext context, DocumentSnapshot symptom) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController dateController = TextEditingController(
            text: DateFormat('dd/MM/yyyy').format(symptom['timestamp'].toDate())
        );
        TextEditingController timeController = TextEditingController(
            text: DateFormat('hh:mm a').format(symptom['timestamp'].toDate())
        );
        TextEditingController symptomController = TextEditingController(text: symptom['symptom']);
        TextEditingController descriptionController = TextEditingController(text: symptom['description']);

        return AlertDialog(
          title: Text('Edit Symptom'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: symptomController,
                decoration: InputDecoration(labelText: 'Symptom'),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: dateController,
                decoration: InputDecoration(labelText: 'Date'),
                onTap: () => _selectDateForEdit(context, dateController),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: timeController,
                decoration: InputDecoration(labelText: 'Time'),
                onTap: () => _selectTimeForEdit(context, timeController),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Update symptom in Firestore
                FirebaseFirestore.instance.collection('symptoms').doc(symptom.id).update({
                  'symptom': symptomController.text,
                  'timestamp': DateFormat('dd/MM/yyyy hh:mm a').parse('${dateController.text} ${timeController.text}'),
                  'description': descriptionController.text,
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Set the button color to green
              ),
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteSymptom(BuildContext context, DocumentSnapshot symptom) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Symptom'),
          content: Text('Are you sure you want to delete this symptom?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Delete the symptom from Firestore
                FirebaseFirestore.instance.collection('symptoms').doc(symptom.id).delete();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Set the button color to red
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDateForEdit(BuildContext context, TextEditingController dateController) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      dateController.text = DateFormat('dd/MM/yyyy').format(picked);
    }
  }

  Future<void> _selectTimeForEdit(BuildContext context, TextEditingController timeController) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      timeController.text = picked.format(context);
    }
  }
}
