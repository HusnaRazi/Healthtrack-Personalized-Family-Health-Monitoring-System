import 'package:flutter/material.dart';

class WaysToMeasure extends StatelessWidget {
  const WaysToMeasure({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 2,
      child: ExpansionTile(
        leading: Image.asset(
          'images/blood.png',
          width: 24,
          height: 24,
        ),
        title: const Text(
          'Ways to Measure',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Blood pressure is traditionally measured using an inflatable cuff around your arm. The cuff is inflated, and the cuff gently tightens on your arm. The air in the cuff is slowly released and a small gauge measures your blood pressure.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 10),
                Divider(),
                Text(
                  'Blood Pressure is recorded as two numbers:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.black, height: 1.5), // Default text style for all spans
                    children: [
                      TextSpan(text: '\n'),
                      TextSpan(
                        text: 'Systolic blood pressure',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' — Indicates how much pressure your blood is exerting against your artery walls when the heart beats.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: Colors.black, height: 1.5), // Default text style for all spans
                    children: [
                      TextSpan(
                        text: 'Diastolic blood pressure',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' — Indicates how much pressure your blood is exerting against your artery walls while the heart is resting between beats.',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
