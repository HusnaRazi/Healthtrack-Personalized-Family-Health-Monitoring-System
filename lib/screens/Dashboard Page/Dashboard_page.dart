import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/Dashboard%20Page/Overall%20Health%20Status.dart';
import 'package:healthtrack/screens/Dashboard%20Page/Overall%20Symptom%20Status.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String patientID = '';
  String latestUpdate = 'Fetching...';
  String latestUpdateHeartRate = 'Fetching...';
  String latestUpdateBloodPressure = 'Fetching...';
  double currentSystolic = 120.0;
  double currentDiastolic = 80.0;
  late StreamSubscription subscription;

  @override
  void initState() {
    super.initState();
    fetchUserMedicalProfile();
    setupGlucoseDataListener();
    setupHeartRateDataListener();
    setupBloodPressureDataListener();
  }

  Future<void> fetchUserMedicalProfile() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        var docSnapshot = await FirebaseFirestore.instance.collection(
            'MedicalProfile').doc(user.uid).get();
        if (docSnapshot.exists) {
          Map<String, dynamic> data = docSnapshot.data()!;
          setState(() {
            patientID = data['identity Card'] ?? '';
          });
        }
      }
    } catch (e) {
      print("Failed to fetch user profile: $e");
    }
  }

  void setupGlucoseDataListener() {
    subscription = FirebaseFirestore.instance
        .collection('Blood Glucose')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final DocumentSnapshot doc = snapshot.docs.first;
        final Timestamp timestamp = doc.get('timestamp');
        final DateTime dateTime = timestamp.toDate();
        final int latestGlucoseValue = doc.get('glucose');

        setState(() {
          latestUpdate = "$latestGlucoseValue mg/dL";
        });
      } else {
        setState(() {
          latestUpdate = "No data available";
        });
      }
    }, onError: (error) {
      print("Error listening to glucose updates: $error");
    });
  }

  void setupHeartRateDataListener() {
    subscription = FirebaseFirestore.instance
        .collection('Heart Rate')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final DocumentSnapshot doc = snapshot.docs.first;
        final Timestamp timestamp = doc.get('timestamp');
        final DateTime dateTime = timestamp.toDate();
        final int latestHeartRateValue = doc.get('bpm');

        setState(() {
          latestUpdateHeartRate = "$latestHeartRateValue bpm";
        });
      } else {
        setState(() {
          latestUpdateHeartRate = "No data available";
        });
      }
    }, onError: (error) {
      print("Error listening to Heart Rate updates: $error");
    });
  }

  void setupBloodPressureDataListener() {
    subscription = FirebaseFirestore.instance
        .collection('Blood Pressure')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final DocumentSnapshot doc = snapshot.docs.first;
        final Timestamp timestamp = doc.get('timestamp');
        final DateTime dateTime = timestamp.toDate();

        // Assuming your document contains 'systolic' and 'diastolic' fields
        final int latestSystolic = doc.get('systolic');
        final int latestDiastolic = doc.get('diastolic');

        setState(() {
          setState(() {
            currentSystolic = latestSystolic.toDouble();
            currentDiastolic = latestDiastolic.toDouble();
            latestUpdateBloodPressure = "$latestSystolic/$latestDiastolic mmHg";
          });
        });
      } else {
        setState(() {
          latestUpdateBloodPressure = "No data available";
        });
      }
    }, onError: (error) {
      print("Error listening to Blood Pressure updates: $error");
    });
  }


  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double heartRateValue = 0.0;
    // Parse the heart rate from the update string if available
    if (latestUpdateHeartRate.contains('bpm')) {
      heartRateValue = double.parse(latestUpdateHeartRate.split(' ')[0]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Health Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.lightBlue[100],
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.lightBlue[100],
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildGridItem(context, 'Patient ID',
                  patientID.isNotEmpty ? patientID : 'Not Assigned',
                  Icons.person, Colors.blue),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildGridItem(
                        context, 'Blood Glucose', latestUpdate, Icons.bloodtype,
                        Colors.red),
                  ),
                  Expanded(
                    child: _buildGridItem(
                        context, 'Heart Rate', latestUpdateHeartRate,
                        Icons.favorite, Colors.red),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildGridItem(
                        context, 'B Pressure', latestUpdateBloodPressure,
                        Icons.trending_up, Colors.red),
                  ),
                  Expanded(
                    child: _buildGridItem(
                        context, 'Temperature', '33.90 °C', Icons.thermostat,
                        Colors.orange),
                  ),
                ],
              ),
              const OverallHealthStatusChart(),
              SymptomGaugeChart(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        subtitle: Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final double y;
}








