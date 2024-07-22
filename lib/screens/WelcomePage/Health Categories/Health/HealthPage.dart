import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Blood%20Glucose/BloodGlucose.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Blood%20Oxygen/BloodOxygenPage.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Blood%20Pressure/BloodPressure.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Heart%20Rate/HeartRate.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({Key? key}) : super(key: key);

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
    @override
    Widget build(BuildContext context) {
      return const Column(
        children: <Widget>[
          BloodGlucose(),
          BloodOxygen(),
          BloodPressure(),
          HeartRate(),
        ],
      );
    }
}