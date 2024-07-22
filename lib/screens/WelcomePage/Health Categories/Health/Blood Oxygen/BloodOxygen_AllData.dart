import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BloodOxygenAllData extends StatefulWidget {
  const BloodOxygenAllData({Key? key}) : super(key: key);

  @override
  State<BloodOxygenAllData> createState() => _BloodOxygenAllDataState();
}

class _BloodOxygenAllDataState extends State<BloodOxygenAllData> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? selectedDate;

  Future<List<Map<String, dynamic>>> fetchBloodOxygenData() async {
    Query<Map<String, dynamic>> query = _firestore.collection('Blood Oxygen');

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

  Future<void> _showEditDialog(BuildContext context, Map<String, dynamic> bloodOxygenData) async {
    TextEditingController saturationController = TextEditingController(text: bloodOxygenData['saturation'].toString());
    DateTime dateTime = (bloodOxygenData['timestamp'] as Timestamp).toDate();
    DateTime newDate = dateTime;
    TimeOfDay newTime = TimeOfDay.fromDateTime(dateTime);

    GlobalKey<FormState> _formKey = GlobalKey<FormState>();  // Add a form key for validation

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Blood Oxygen Data'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey, // Set form key
              child: ListBody(
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'Oxygen Saturation: ',
                        style: TextStyle(
                          fontSize: 16.0, // Ensure the text size is appropriate
                          fontWeight: FontWeight.bold, // Bold for clear visibility
                          color: Colors.black, // Optional: adjust color to fit your theme
                        ),
                      ),
                      SizedBox(width: 8), // Provides spacing between label and input field
                      Expanded(
                        child: TextField(
                          controller: saturationController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                            fontSize: 16.0, // Ensure the text field font size matches the label
                            color: Colors.black, // Optional: adjust color to match the label
                          ),
                          decoration: InputDecoration(
                            isDense: true, // Reduces the space and aligns better with the label
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Adjusts the padding inside the text field
                            hintText: 'Enter value', // Provides a placeholder when empty
                            border: OutlineInputBorder( // Gives a subtle border to define the field area
                                borderSide: BorderSide(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(5) // Optional: adds rounded corners to the field
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
                  _updateBloodOxygenData(bloodOxygenData['id'],
                      saturationController.text, newDate, newTime);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateBloodOxygenData(String docId, String saturation, DateTime date, TimeOfDay time) async {
    int saturationValue = int.tryParse(saturation) ?? 0; // Validate and parse the input
    DateTime newDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    await _firestore.collection('Blood Oxygen').doc(docId).update({
      'saturation': saturationValue,
      'timestamp': Timestamp.fromDate(newDateTime),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data updated successfully')),
    );

    setState(() {}); // Refresh the list to show updated data
  }

  Widget buildBloodOxygenCard(Map<String, dynamic> bloodOxygenData) {
    DateTime dateTime = (bloodOxygenData['timestamp'] as Timestamp).toDate();
    String oxygenLevel = bloodOxygenData['saturation'].toString();
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
                'Oxygen Saturation: $oxygenLevel%',
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
                      await _showEditDialog(context, bloodOxygenData);
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
                                  await _firestore.collection('Blood Oxygen').doc(bloodOxygenData['id']).delete();
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
        title: const Text('Blood Oxygen Data'),
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
              future: fetchBloodOxygenData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return buildBloodOxygenCard(snapshot.data![index]);
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
