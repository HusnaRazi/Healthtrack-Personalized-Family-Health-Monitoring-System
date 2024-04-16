import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  late Future<DocumentSnapshot> _userData;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  Uint8List? _image; // To store the selected image data
  String? _profileImageUrl; // To store the uploaded file URL

  @override
  void initState() {
    super.initState();
    _userData = getUserData();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  Future<DocumentSnapshot> getUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            // Update all fields including the profile image URL.
            firstNameController.text = userData['firstName'] ?? '';
            lastNameController.text = userData['lastName'] ?? '';
            usernameController.text = userData['username'] ?? '';
            emailController.text = userData['email'] ?? '';
            phoneNumberController.text = userData['phoneNumber'] ?? '';
            _profileImageUrl = userData['profileImageUrl']; // Ensure this is updated
          });
        }
        return userDoc;
      } else {
        throw Exception("User not authenticated");
      }
    } catch (e) {
      print('Error fetching user data: $e');
      throw e;
    }
  }

  // Corrected to be asynchronous and properly use ImagePicker
  Future<void> selectImage() async {
    try {
      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        Uint8List imgData = await image.readAsBytes();
        setState(() {
          _image = imgData;
        });
        uploadFile(imgData);
      }
    } catch (e) {
      print("Failed to pick image: $e");
    }
  }

  Future<void> uploadFile(Uint8List imgData) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not authenticated');
      return;
    }
    String path = 'profileImages/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.png';
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putData(imgData);
      final url = await ref.getDownloadURL();
      setState(() {
        _profileImageUrl = url; // Update the state with the new URL
      });
      // Update Firestore document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'profileImageUrl': url,
      });
    } catch (e) {
      print('Error uploading file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontFamily: 'MuseoSlab',
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          child: FutureBuilder<DocumentSnapshot>(
            future: _userData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
              // While data is loading
                return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  // If an error occurs
                  return Text('Error: ${snapshot.error}');
                } else {
                  // If data is successfully loaded
                  Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;
                  // Set initial values for text fields
                  firstNameController.text = userData['firstName'] ?? '';
                  lastNameController.text = userData['lastName'] ?? '';
                  usernameController.text = userData['username'] ?? '';
                  emailController.text = userData['email'] ?? '';
                  phoneNumberController.text = userData['phoneNumber'] ?? '';
                  return Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 64,
                            backgroundImage: _image != null
                                ? MemoryImage(_image!) // Display the newly selected image
                                : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(_profileImageUrl!)
                                : AssetImage("path/to/your/default/image.png")) as ImageProvider,
                          ),
                          Positioned(
                            bottom: -10,
                            left: 80,
                            child: IconButton(
                              icon: const Icon(Icons.add_a_photo_sharp),
                              onPressed: selectImage,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      Form(child: Column(
                        children: [
                          TextFormField(
                            controller: firstNameController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  LineAwesomeIcons.user,
                                  color: Colors.blue[800],
                                ),
                                labelText: "First Name",
                                hintText: "First Name",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(100)),
                                ),
                              ),
                          const SizedBox(height: 15),
                            TextFormField(
                              controller: lastNameController,
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  LineAwesomeIcons.user,
                                  color: Colors.blue[800],
                                ),
                                labelText: "Last Name",
                                hintText: "Last Name",
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(100)),
                              ),
                            ),
                        const SizedBox(height: 15),

                        TextFormField(
                          controller: usernameController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.people_outline,
                              color: Colors.blue[800],
                            ),
                            labelText: "Username",
                            hintText: "Enter Username",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100)),
                          ),
                        ),

                        const SizedBox(height: 15),

                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Colors.blue[800],
                            ),
                            labelText: "E-mail",
                            hintText: "Enter E-mail",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100)),
                          ),
                        ),

                        const SizedBox(height: 15),

                        TextFormField(
                          controller: phoneNumberController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.contact_phone_outlined,
                              color: Colors.blue[800],
                            ),
                            labelText: "Phone Number",
                            hintText: "Enter Phone Number",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(100)),
                          ),
                        ),

                        const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 50.0,
                      child: ElevatedButton(
                        onPressed: () async{
                          try {
                          User? user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                            'firstName': firstNameController.text,
                            'lastName': lastNameController.text,
                            'username': usernameController.text,
                            'email': emailController.text,
                            'phoneNumber': phoneNumberController.text,
                            });

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Success!"),
                                titleTextStyle: const TextStyle(
                                  fontFamily: 'SansSerif',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 22),

                                content: const Text("Your Profile has been Updated"),
                                actions: <Widget>[
                                  TextButton(
                                    child: const Text("Close"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                              );
                            },
                          );
                        } else {
                            throw Exception("User not authenticated");
                          }
                          } catch (e) {
                            print('Error updating user data: $e');
                            // Handle error
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            "Update Profile",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
