import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Medical%20Profile/MedicalProfile_user.dart';

class MedicalProfilePage extends StatefulWidget {
  @override
  _MedicalProfilePageState createState() => _MedicalProfilePageState();
}

class _MedicalProfilePageState extends State<MedicalProfilePage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MedicalProfileUser()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // You can display a loading indicator while waiting for navigation
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
