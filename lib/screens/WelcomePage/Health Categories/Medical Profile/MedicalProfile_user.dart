import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class MedicalProfileUser extends StatefulWidget {
  @override
  _MedicalProfileUserState createState() => _MedicalProfileUserState();
}

class _MedicalProfileUserState extends State<MedicalProfileUser> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String? profileImageUrl;

  bool isEditing = false;
  String firstName = '', lastName = '', identityCard = '';
  String name = '';
  DateTime? dob;
  String gender = '';
  String nationality = '';
  String address = '';
  String phoneNumber = '';
  String email = '';
  String weight = '';
  String height = '';
  List<Map<String, String>> allergies = [];
  String notes = '';
  List<Map<String, String>> emergencyContacts = [];
  String bloodType = '';

  // Text controllers
  TextEditingController fNameController = TextEditingController();
  TextEditingController lNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController idCardController = TextEditingController();

    Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dob ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != dob) {
      setState(() {
        dob = picked;
        dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserProfile();
    fetchUserMedicalProfile();
    loadImageUrlFromFirestore();
  }

  Future<void> fetchUserProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var docSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (docSnapshot.exists) {
          Map<String, dynamic> data = docSnapshot.data()!;
          setState(() {
            firstName = data['firstName'] ?? '';
            lastName = data['lastName'] ?? '';
            email = data['email'] ?? '';
            phoneNumber = data['phoneNumber'] ?? '';
            name = '$firstName $lastName';

            fNameController.text = firstName;
            lNameController.text = lastName;
            emailController.text = email;
            phoneNumberController.text = phoneNumber;

          });
        }
      }
    } catch (e) {
      print("Failed to fetch user profile: $e");
    }
  }

  Future<void> fetchUserMedicalProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var docSnapshot = await FirebaseFirestore.instance.collection('MedicalProfile').doc(user.uid).get();
        if (docSnapshot.exists) {
          Map<String, dynamic> data = docSnapshot.data()!;
          setState(() {
            identityCard = data['identity Card'] ?? '';
            gender = data['gender'] ?? '';
            bloodType = data['bloodType'] ?? '';
            nationality = data['nationality'] ?? '';
            address = data['address'] ?? '';
            dob = data['dob'] != null ? (data['dob'] as Timestamp).toDate() : null;
            weight = data['weight'] ?? '';
            height = data['height'] ?? '';
            allergies = List<Map<String, String>>.from(data['allergies'] ?? []);
            notes = data['notes'] ?? '';
            emergencyContacts = List<Map<String, String>>.from(data['emergencyContacts'] ?? []);

            // Ensure the text controllers are updated if needed
            phoneNumberController.text = phoneNumber;
            dobController.text = dob != null ? DateFormat('dd/MM/yyyy').format(dob!) : '';
            idCardController.text = identityCard;
          });
        }
      }
    } catch (e) {
      print("Failed to fetch user profile: $e");
    }
  }


  Future<void> saveUserProfile() async {
    if (!_formKey.currentState!.validate()) {
      return; // If the form isn't valid, don't save the data.
    }
    _formKey.currentState!.save();

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'firstName': firstName,
          'lastName': lastName,
          'phoneNumber': phoneNumber,
          'email': email,
        });
        print("User profile saved successfully");
      } catch (e) {
        print("Failed to save user profile: $e");
        // Consider showing an error message to the user
      }
    }
  }

  int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> saveUserMedicalProfile(String imageUrl) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Map<String, dynamic> dataToUpdate = {
          'firstName': firstName,
          'lastName': lastName,
          'identity Card': identityCard,
          'phoneNumber': phoneNumber,
          'email': email,
          'gender': gender,
          'bloodType': bloodType,
          'nationality': nationality,
          'address': address,
          'dob': dob != null ? Timestamp.fromDate(dob!) : null,
          'weight': weight,
          'height': height,
          'allergies': allergies,
          'notes': notes,
          'emergencyContacts': emergencyContacts,
        };

        if (imageUrl != null) {
          dataToUpdate['profileImageUrl'] = imageUrl;
        }

        await FirebaseFirestore.instance.collection('MedicalProfile').doc(user.uid).update(dataToUpdate);
        print("User medical profile saved successfully");
      }
    } catch (e) {
      print("Failed to save user medical profile: $e");
    }
  }

  Future<String?> uploadImage(XFile? imageFile) async {
    if (imageFile == null) return null;

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    String filePath = 'user_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}';
    File file = File(imageFile.path);

    try {
      firebase_storage.UploadTask task = firebase_storage.FirebaseStorage.instance
          .ref(filePath)
          .putFile(file);

      firebase_storage.TaskSnapshot snapshot = await task;
      String imageUrl = await snapshot.ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print("Failed to upload image: $e");
      return null;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });

      // Upload the image to Firebase Storage and get the URL
      String? imageUrl = await uploadImage(_imageFile);
      if (imageUrl != null) {
        updateUserImageUrl(imageUrl);  // Update Firestore
        setState(() {
          profileImageUrl = imageUrl;  // Update local state
        });
      }
    }
  }


  Future<void> loadImageUrlFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var docSnapshot = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (docSnapshot.exists && docSnapshot.data()!.containsKey('profileImageUrl')) {
        setState(() {
          profileImageUrl = docSnapshot.data()!['profileImageUrl'] as String?;
        });
      }
    }
  }

  Future<void> updateUserImageUrl(String imageUrl) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'profileImageUrl': imageUrl,
        });
        print("Image URL updated successfully in Firestore");
      } catch (e) {
        print("Failed to update image URL in Firestore: $e");
      }
    }
  }

  Widget _buildProfileSection() {
    ImageProvider<Object>? imageProvider;

    if (_imageFile != null) {
      // When _imageFile is not null, use a FileImage
      imageProvider = FileImage(File(_imageFile!.path));
    } else if (profileImageUrl != null) {
      // Ensure profileImageUrl is not null before passing to NetworkImage
      imageProvider = NetworkImage(profileImageUrl!); // Use the '!' to assert that it's not null
    }

    return Column(
      children: [
        GestureDetector(
          onTap: isEditing ? _pickImage : null,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? Icon(Icons.add_a_photo, size: 50, color: Colors.blueGrey)
                : null,
          ),
        ),
      ],
    );
  }


  Widget _buildDetailTile({required String label, required String value, required IconData icon, Function()? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 10),
      title: Text(label),
      subtitle: Text(value),
      leading: Icon(icon),
      onTap: isEditing ? onTap : null,
    );
  }

  Widget _buildPersonalDetailsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Personal Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          Divider(),
          isEditing
              ? Column(
            children: [
              TextFormField(
                controller: fNameController,
                decoration: InputDecoration(labelText: 'First Name', icon: Icon(Icons.drive_file_rename_outline_outlined)),
                onSaved: (value) => firstName = value!,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),

              TextFormField(
                controller: lNameController,
                decoration: InputDecoration(labelText: 'Last Name', icon: Icon(Icons.drive_file_rename_outline_outlined)),
                onSaved: (value) => lastName = value!,
              ),
              TextFormField(
                controller: idCardController,
                decoration: InputDecoration(labelText: 'Identity Card', icon: Icon(Icons.file_present_outlined)),
                onSaved: (value) => identityCard = value!,
              ),
              DropdownButtonFormField<String>(
                value: gender.isNotEmpty ? gender : null,
                decoration: InputDecoration(labelText: 'Gender', icon: Icon(Icons.person)),
                items: ['Male', 'Female', 'Other'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    gender = newValue!;
                  });
                },
                onSaved: (value) => gender = value!,
              ),
              DropdownButtonFormField<String>(
                value: bloodType.isNotEmpty ? bloodType : null,
                decoration: InputDecoration(labelText: 'Blood Type', icon: Icon(Icons.bloodtype)),
                items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    bloodType = newValue!;
                  });
                },
                onSaved: (value) => bloodType = value!,
              ),
              TextFormField(
                initialValue: nationality,
                decoration: InputDecoration(labelText: 'Nationality', icon: Icon(Icons.language)),
                onSaved: (value) => nationality = value!,
              ),
              TextFormField(
                initialValue: address,
                decoration: InputDecoration(labelText: 'Address', icon: Icon(Icons.home)),
                onSaved: (value) => address = value!,
              ),
              TextFormField(
                controller: phoneNumberController,
                decoration: InputDecoration(labelText: 'Phone Number', icon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                onSaved: (value) => phoneNumber = value!,
              ),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email', icon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                onSaved: (value) => email = value!,
              ),
              GestureDetector(
                onTap: () => isEditing ? _selectDate(context) : null,
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: dobController,
                    decoration: InputDecoration(labelText: 'Date of Birth', icon: Icon(Icons.cake)),
                  ),
                ),
              ),
              TextFormField(
                initialValue: weight,
                decoration: InputDecoration(labelText: 'Weight (kg)', icon: Icon(Icons.monitor_weight)),
                keyboardType: TextInputType.number,
                onSaved: (value) => weight = value!,
              ),
              TextFormField(
                initialValue: height,
                decoration: InputDecoration(labelText: 'Height (cm)', icon: Icon(Icons.height)),
                keyboardType: TextInputType.number,
                onSaved: (value) => height = value!,
              ),
            ],
          )
              : Column(
            children: [
              _buildDetailTile(label: 'Full Name', value: name.isNotEmpty ? name : 'Not set', icon: Icons.drive_file_rename_outline_outlined),
              _buildDetailTile(label: 'Identity Card', value: identityCard.isNotEmpty ? identityCard : 'Not set', icon: Icons.file_present_outlined),
              _buildDetailTile(label: 'Gender', value: gender.isNotEmpty ? gender : 'Not set', icon: Icons.person),
              _buildDetailTile(label: 'Blood Type', value: bloodType.isNotEmpty ? bloodType : 'Not set', icon: Icons.bloodtype),
              _buildDetailTile(label: 'Nationality', value: nationality.isNotEmpty ? nationality : 'Not set', icon: Icons.language),
              _buildDetailTile(label: 'Address', value: address.isNotEmpty ? address : 'Not set', icon: Icons.home),
              _buildDetailTile(label: 'Phone Number', value: phoneNumber, icon: Icons.phone),
              _buildDetailTile(label: 'Email', value: email.isNotEmpty ? email : 'Not set', icon: Icons.email),
              _buildDetailTile(label: 'Date of Birth', value: dob != null ? DateFormat('dd-MM-yyyy').format(dob!) : 'Not set', icon: Icons.cake),
              _buildDetailTile(label: 'Age', value: dob != null ? _calculateAge(dob!).toString() : 'Not set', icon: Icons.calendar_today),
              _buildDetailTile(label: 'Weight (kg)', value: weight.isNotEmpty ? weight : 'Not set', icon: Icons.monitor_weight),
              _buildDetailTile(label: 'Height (cm)', value: height.isNotEmpty ? height : 'Not set', icon: Icons.height),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllergiesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Allergies', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ],
          ),
          Divider(),
          if (isEditing)
            Column(
              children: [
                for (int i = 0; i < allergies.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: allergies[i]['name'],
                            decoration: InputDecoration(labelText: 'Allergy'),
                            onSaved: (value) => allergies[i]['name'] = value!,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Severity'),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.redAccent,
                                  inactiveTrackColor: Colors.yellow,
                                  trackShape: RoundedRectSliderTrackShape(),
                                  trackHeight: 4.0,
                                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
                                  thumbColor: Colors.blueAccent,
                                  overlayColor: Colors.blue.withAlpha(32),
                                  overlayShape: RoundSliderOverlayShape(overlayRadius: 28.0),
                                  tickMarkShape: RoundSliderTickMarkShape(),
                                  activeTickMarkColor: Colors.blueAccent,
                                  inactiveTickMarkColor: Colors.yellow,
                                  valueIndicatorShape: PaddleSliderValueIndicatorShape(),
                                  valueIndicatorColor: Colors.blueAccent,
                                  valueIndicatorTextStyle: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                child: Slider(
                                  value: double.parse(allergies[i]['severity'] ?? '0'),
                                  min: 0,
                                  max: 2,
                                  divisions: 2,
                                  label: _getSeverityLabel(double.parse(allergies[i]['severity'] ?? '0')),
                                  onChanged: (value) {
                                    setState(() {
                                      allergies[i]['severity'] = value.toString();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              allergies.removeAt(i);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      allergies.add({'name': '', 'severity': '0'});
                    });
                  },
                  child: Text('Add Allergy'),
                ),
              ],
            )
          else
            for (var allergy in allergies)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16),
                    SizedBox(width: 5),
                    Text('${allergy['name']}: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    Text(_getSeverityLabel(double.parse(allergy['severity']!))),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  String _getSeverityLabel(double value) {
    switch (value.toInt()) {
      case 0:
        return 'Mild';
      case 1:
        return 'Moderate';
      case 2:
        return 'Severe';
      default:
        return '';
    }
  }

  Widget _buildNotesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notes', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ],
          ),
          Divider(),
          isEditing
              ? TextFormField(
            initialValue: notes,
            decoration: InputDecoration(labelText: 'Notes', icon: Icon(Icons.note)),
            maxLines: null,
            onSaved: (value) => notes = value!,
          )
              : Row(
            children: [
              Icon(Icons.note, size: 16),
              SizedBox(width: 5),
              Expanded(child: Text(notes)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Emergency Contacts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ],
          ),
          Divider(),
          if (isEditing)
            Column(
              children: [
                for (int i = 0; i < emergencyContacts.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: emergencyContacts[i]['name'],
                                decoration: InputDecoration(labelText: 'Contact Name', icon: Icon(Icons.person)),
                                onSaved: (value) => emergencyContacts[i]['name'] = value!,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  emergencyContacts.removeAt(i);
                                });
                              },
                            ),
                          ],
                        ),
                        TextFormField(
                          initialValue: emergencyContacts[i]['number'],
                          decoration: InputDecoration(labelText: 'Contact Number', icon: Icon(Icons.phone)),
                          keyboardType: TextInputType.phone,
                          onSaved: (value) => emergencyContacts[i]['number'] = value!,
                        ),
                      ],
                    ),
                  ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      emergencyContacts.add({'name': '', 'number': ''});
                    });
                  },
                  child: Text('Add Emergency Contact'),
                ),
              ],
            )
          else
            for (var contact in emergencyContacts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(Icons.phone, size: 16),
                    SizedBox(width: 5),
                    Text('${contact['name']}: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(contact['number']!),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        isEditing = false;
        name = '$firstName $lastName'; // Update the full name
      });

      // Collect tasks to wait on
      List<Future> tasks = [saveUserProfile()];
      if (profileImageUrl != null) {
        tasks.add(saveUserMedicalProfile(profileImageUrl!)); // Use the bang operator
      }

      // Execute all tasks
      Future.wait(tasks).then((_) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text("Profile Saved Successfully!"),
          ),
        );
      }).catchError((error) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text("Failed to save profile: $error"),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medical Profile'),
        backgroundColor: Colors.lightBlue[100],
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (isEditing) {
                _saveForm();
              } else {
                setState(() {
                  isEditing = true;
                });
              }
            },
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _buildProfileSection()),
              _buildPersonalDetailsSection(),
              _buildAllergiesSection(),
              _buildNotesSection(),
              _buildEmergencyContactsSection(),
            ],
          ),
        ),
      ),
    );
  }
}