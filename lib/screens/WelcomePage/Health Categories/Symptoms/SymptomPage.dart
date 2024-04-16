import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Chest%20Pain/ChestPain_data.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Coughing/Cough_data.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Fever/Fever_data.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Headache/Headache.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Runny%20Nose/Runnynose_Data.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Vomit/Vomit_data.dart';

class SymptomsPage extends StatelessWidget {
  const SymptomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
        children: <Widget>[
          ChestPainPage(),
          CoughPage(),
          FeverPage(),
          HeadachePage(),
          RunnyNosePage(),
          VomitPage(),
      ],
    );
  }
}
