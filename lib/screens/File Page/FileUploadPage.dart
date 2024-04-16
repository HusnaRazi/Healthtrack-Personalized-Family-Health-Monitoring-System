import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/component/HomePage_header.dart';
import 'package:healthtrack/screens/File%20Page/AllFilePage.dart';
import 'package:healthtrack/screens/File%20Page/FileUpload.dart';
import 'package:healthtrack/screens/File%20Page/SummaryGraph.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class FilePage extends StatefulWidget {
  const FilePage({Key? key}) : super(key: key);

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  int selectedIndex = 0;

  Widget _getSelectedPage() {
    switch (selectedIndex) {
      case 0:
        return FileDisplay(); // Show this widget when selectedIndex is 0
      case 1:
        return const GraphFile();
      case 2:
        return const FileUpload(); // Show this widget when selectedIndex is 2
      default:
        return Container(); // Return an empty container or any other default widget for other cases
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Define what happens when the button is tapped
          },
        ),
        title: const Text(
          'Medical Records',
          style: TextStyle(
            fontFamily: 'MuseoSlab',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LineAwesomeIcons.search),
            color: Colors.black,
            onPressed: () {
              // Define what happens when the button is tapped
            },
          ),
          IconButton(
            icon: const Icon(LineAwesomeIcons.info),
            color: Colors.black,// Changed to a material icon
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  // Return object of type Dialog
                  return AlertDialog(
                    title: const Text("Details",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    content: const Text(
                      "Medical records are the document that explains all detail about the patient's history, clinical findings, "
                          "diagnostic test results, pre and postoperative care, patient's progress and medication.",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.justify,
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text("Close"),
                        onPressed: () {
                          Navigator.of(context).pop(); // Closes the dialog
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
        backgroundColor: Colors.lightBlue[100],
      ),
      body: SingleChildScrollView(
        child: Container(
          color: Colors.lightBlue[100],
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 15),
              SizedBox(
                height: 30,
                child: Padding( // Add padding to position the list view to the right
                  padding: const EdgeInsets.only(left: 20.0), // Adjust this value as needed
                  child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: 3,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, index) {
                        // Array containing labels for each list item
                        final labels = ["All Records", "Summary", "Upload File"];

                        return Row(
                          children: [
                            if (index > 0) const SizedBox(width: 4.0), // Adds space between items, but not before the first item
                            InkWell(
                              onTap: () {
                                setState(() {
                                  selectedIndex = index; // Mark the tapped item
                                });
                                // Handle the tap
                                if (kDebugMode) {
                                  print('Tapped on ${labels[index]}');
                                }
                                // You can navigate to another page or show a dialog here
                              },

                              child: Container(
                                width: 110,
                                height: 50,
                                margin: const EdgeInsets.symmetric(horizontal: 4.0), // Adds space between items
                                decoration: BoxDecoration(
                                  color: selectedIndex == index ? Colors.blue : Colors.white, // Change color when selected
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    labels[index], // Assigns the correct label based on the index
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                ),
              ),
              _getSelectedPage(),

              SizedBox(
                height: 800,
                child: Stack(
                  children: [
                    Positioned(
                      top: 400,
                      right: -300,
                      child: Header(backgroundColor: Colors.white.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}