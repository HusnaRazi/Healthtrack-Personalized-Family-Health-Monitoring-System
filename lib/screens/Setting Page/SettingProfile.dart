import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/LoginPage/Login_page.dart';
import 'package:healthtrack/screens/Setting%20Page/ChangePassPage.dart';
import 'package:healthtrack/screens/Setting%20Page/UpdateProfilePage.dart';
import 'package:healthtrack/screens/Setting%20Page/widgets/profile_menu.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? userProfileImageUrl;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Call refreshUserProfile() in initState()
    refreshUserProfile();
  }

  void refreshUserProfile() {
    fetchUserProfile();
  }

  void fetchUserProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var docSnapshot = await FirebaseFirestore.instance.collection('users')
            .doc(user.uid)
            .get();
        if (docSnapshot.exists) {
          Map<String, dynamic> data = docSnapshot.data()!;
          print("Fetched data: $data"); // Debug print
          setState(() {
            userProfileImageUrl = data['profileImageUrl'];
            usernameController.text = data['username'] ?? 'No username';
            emailController.text = data['email'] ?? 'No email';
          });
        } else {
          print("Document does not exist");
        }
      } else {
        print("User is not logged in");
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {}, icon: const Icon(Icons.arrow_back)),
          title: const Text(
            'Profile',
            style: TextStyle(
              fontFamily: 'MuseoSlab',
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
                onPressed: () {}, icon: const Icon(LineAwesomeIcons.moon))
          ],
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: userProfileImageUrl != null
                        ? Image.network(
                      '$userProfileImageUrl?time=${DateTime
                          .now()
                          .millisecondsSinceEpoch}',
                      fit: BoxFit.cover,
                    )
                        : const Image(
                        image: AssetImage('path/to/your/placeholder/image')),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  usernameController.text,
                  // assuming you've fetched and set this
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                  ),
                ),
                Text(
                  emailController.text, // assuming you've fetched and set this
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.normal,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 15),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (
                            context) => const UpdateProfile()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue.shade400,
                        side: BorderSide.none,
                        shape: const StadiumBorder()),
                    child: const Text(
                      'Edit Profile', style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                ProfileMenuWidget(title: "Notification",
                    icon: Icons.notifications_active,
                    onPress: () {}),
                ProfileMenuWidget(title: "Language",
                    icon: Icons.language_outlined,
                    onPress: () {}),
                ProfileMenuWidget(
                    title: "About", icon: Icons.info_outline, onPress: () {}),
                ProfileMenuWidget(title: "Setting",
                    icon: Icons.settings_sharp,
                    onPress: () {
                      Navigator.of(context).pop();
                      Navigator.pushReplacement(context, MaterialPageRoute(
                        builder: (context) => const ChangePasswordPage()),
                        );
                    }),
                ProfileMenuWidget(title: "Logout",
                  icon: Icons.logout,
                  textColor: Colors.red[900],
                  onPress: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Exit Page?"),
                          titleTextStyle: const TextStyle(
                              fontFamily: 'SansSerif',
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 22),

                          content: const Text("Do You Really Want To Log Out?"),
                          actions: <Widget>[
                            TextButton(
                              child: const Text("No"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text("Yes"),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.pushReplacement(context,
                                  MaterialPageRoute(
                                      builder: (context) => const LoginPage()),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Future<String?> getUserProfileImageUrl() async {
    // Your logic to fetch the profile image URL from Firestore
    // For example, fetching from Firestore where 'users' is your collection
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var docSnapshot = await FirebaseFirestore.instance.collection('users')
          .doc(user.uid)
          .get();
      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data()!;
        return data['profileImageUrl']; // Assuming 'profileImageUrl' is the field in your document
      }
    }
    return null;
  }
