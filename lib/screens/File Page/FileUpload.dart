import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FileUpload extends StatefulWidget {
  const FileUpload({Key? key}) : super(key: key);

  @override
  State<FileUpload> createState() => _FileUploadState();
}

class _FileUploadState extends State<FileUpload> {
  String? pdfUrl;
  File? localFile;
  Color containerColor = getRandomColor();
  String? title;
  String? doctor;
  String? hospital;
  String? datetreatment;
  bool isLoading = false;

  // Get current user
  final user = FirebaseAuth.instance.currentUser;

  // This function is responsible for picking files
  Future<List<PlatformFile>?> pickFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      return result.files;
    } else {
      // User canceled the picker
      return null;
    }
  }

  // This function uploads files to Firebase Storage and returns the URLs
  Future<List<String>> uploadFiles(List<PlatformFile>? files) async {
    List<String> uploadUrls = [];
    if (files == null) return uploadUrls;
    final storageRef = FirebaseStorage.instance.ref();
    final userId = user?.uid; // Get the current user's UID

    if (userId == null) {
      throw Exception("User not logged in");
    }

    await Future.forEach<PlatformFile>(files, (file) async {
      File fileToUpload = File(file.path!);
      try {
        // Define the path in the storage
        var taskSnapshot = await storageRef
            .child('uploads/$userId/${file.name}') // Store files under user's UID
            .putFile(fileToUpload);

        // Get the URL of the uploaded file
        final String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        uploadUrls.add(downloadUrl);
      } catch (e) {
        print(e); // Consider replacing this with user-friendly error handling
      }
    });

    return uploadUrls; // Returns the URLs of all uploaded files
  }


  Future<Map<String, String>?> showDetailsPopup(BuildContext context) async {
    String title = '';
    String doctor = '';
    String hospital = '';
    String datetreatment = '';

    return showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(onChanged: (value) => title = value, decoration: const InputDecoration(hintText: "Title")),
                TextField(onChanged: (value) => doctor = value, decoration: const InputDecoration(hintText: "Doctor's Name")),
                TextField(onChanged: (value) => hospital = value, decoration: const InputDecoration(hintText: "Hospital")),
                TextField(onChanged: (value) => datetreatment = value, decoration: const InputDecoration(hintText: "Date Treatment")),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Upload'),
              onPressed: () {
                if (title.isNotEmpty && doctor.isNotEmpty && hospital.isNotEmpty && datetreatment.isNotEmpty) {
                  Navigator.of(context).pop({'title': title, 'doctor': doctor, 'hospital': hospital, 'datetreatment': datetreatment});
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> selectAndUploadFiles() async {
    try {
      final files = await pickFiles();
      if (files != null) {
        // Show popup dialog to get additional details
        final details = await showDetailsPopup(context);
        if (details != null) {
          // Store the details in state variables
          setState(() {
            title = details['title'];
            doctor = details['doctor'];
            hospital = details['hospital'];
            datetreatment = details['datetreatment'];
          });

          // Show the loading dialog
          showLoadingDialog(context);

          final uploadUrls = await uploadFiles(files);
          if (uploadUrls.isNotEmpty) {
            setState(() {
              pdfUrl = uploadUrls.first; // Update the state with the first URL
            });
            final firestoreInstance = FirebaseFirestore.instance;
            await firestoreInstance.collection("uploads").add({
              'pdfUrl': pdfUrl,
              'title': title,
              'doctor': doctor,
              'hospital': hospital,
              'Date Treatment': datetreatment,
              'dateUploaded': FieldValue.serverTimestamp(),
              'uid': user!.uid,
            });
            downloadAndDisplayPdf(pdfUrl!);
          }
          print('Uploaded files: $uploadUrls');
        } else {
          print('Details not provided');
        }
      } else {
        print('No files selected');
      }
    } catch (e) {
      print('Error during file selection or upload: $e');
    } finally {
      // Dismiss the loading dialog
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<File> downloadFile(String url) async {
    final response = await http.get(Uri.parse(url));
    final documentDirectory = await getApplicationDocumentsDirectory();
    final file = File('${documentDirectory.path}/downloaded.pdf');

    await file.writeAsBytes(response.bodyBytes);
    return file;
  }

  Future<void> downloadAndDisplayPdf(String url) async {
    try {
      final file = await downloadFile(url);
      if (await file.exists()) {
        setState(() {
          localFile = file;
        });
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfViewPage(localFile!.path)));
      } else {
        throw Exception("Downloaded file does not exist");
      }
    } catch (e) {
      print("Failed to download file: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to download file: $e")),
      );
    }
  }

  String getFormattedDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(now);
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Uploading..."),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final String formattedDate = getFormattedDate();

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 30.0, top: 20.0, bottom: 5),
          child: Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                print("Create a File tapped");
          },
            child: Text(
              "Create a File",
              style: TextStyle(
                color: Colors.indigo[900], // Feel free to adjust the color
                fontWeight: FontWeight.bold,
                fontSize: 16,
                decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ),
            InkWell(
              onTap: () async {
                await selectAndUploadFiles();
              },
              child: Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.lightBlue,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white, // Border color
                    width: 2, // Border width
                  ),

                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_sharp,
                      color: Colors.white,
                      size: 80,
                    ),
                    Text(
                      'Upload Your File Here',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                child: Text(
                  "Recent Files:",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (localFile != null)
              InkWell(
                onTap: () {
                  // When the container is tapped, display the PDF.
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfViewPage(localFile!.path)));
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: containerColor, // Background color of the box
                    borderRadius: BorderRadius.circular(10), // Rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 8),
                        child: const Icon(Icons.picture_as_pdf, size: 60, color: Colors.white), // PDF icon
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Title: $title", style: const TextStyle(color: Colors.white)),
                            Text("Doctor: $doctor", style: const TextStyle(color: Colors.white)),
                            Text("Hospital: $hospital", style: const TextStyle(color: Colors.white)),
                            Text("Date Treatment: $datetreatment", style: const TextStyle(color: Colors.white)),
                            Text("Date Updated: $formattedDate", style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
    }
}

// A simple page to display the PDF.
class PdfViewPage extends StatelessWidget {
  final String path;

  const PdfViewPage(this.path, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View PDF'),
      ),
      body: PDFView(
        filePath: path,
      ),
    );
  }
}

// Function to generate a random color
Color getRandomColor() {
return Color((Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);
}
