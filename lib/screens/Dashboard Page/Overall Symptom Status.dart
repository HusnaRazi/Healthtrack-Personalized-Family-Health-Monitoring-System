import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SymptomGaugeChart extends StatefulWidget {
  @override
  _SymptomGaugeChartState createState() => _SymptomGaugeChartState();
}

class SymptomData {
  String symptom;
  int severity;
  SymptomData(this.symptom, this.severity);
}

class _SymptomGaugeChartState extends State<SymptomGaugeChart> {
  List<SymptomData> symptoms = [];
  String selectedSymptom = 'Coughing';
  int severity = 1;

  @override
  void initState() {
    super.initState();
    fetchSymptoms();
  }

  Future<void> fetchSymptoms() async {
    var snapshotCoughing = await FirebaseFirestore.instance.collection('Coughing').orderBy('startDateTime', descending: true).limit(1).get();
    var snapshotChestPain = await FirebaseFirestore.instance.collection('Chest Pain').orderBy('startDateTime', descending: true).limit(1).get();
    var snapshotHeadaches = await FirebaseFirestore.instance.collection('Headaches').orderBy('startDateTime', descending: true).limit(1).get();
    var snapshotRunnyNose = await FirebaseFirestore.instance.collection('RunnyNose').orderBy('startDateTime', descending: true).limit(1).get();

    if (snapshotCoughing.docs.isNotEmpty) {
      var data = snapshotCoughing.docs.first;
      int severityLevelCough = mapSeverity(data['severity'].toString());
      symptoms.add(SymptomData('Coughing', severityLevelCough));
    }

    if (snapshotChestPain.docs.isNotEmpty) {
      var data = snapshotChestPain.docs.first;
      int severityLevelChestPain = mapSeverity(data['condition'].toString());
      symptoms.add(SymptomData('Chest Pain', severityLevelChestPain));
    }

    if (snapshotHeadaches.docs.isNotEmpty) {
      var data = snapshotHeadaches.docs.first;
      int severityLevelHeadache = mapSeverity(data['severity'].toString());
      symptoms.add(SymptomData('Headaches', severityLevelHeadache));
    }

    if (snapshotRunnyNose.docs.isNotEmpty) {
      var data = snapshotRunnyNose.docs.first;
      int severityLevelRunnyNose = mapSeverity(data['severity'].toString());
      symptoms.add(SymptomData('Runny Nose', severityLevelRunnyNose));
    }

    if (symptoms.isNotEmpty) {
      setState(() {
        selectedSymptom = symptoms.first.symptom;
        severity = symptoms.first.severity;
      });
    }
  }

  int mapSeverity(String severity) {
    switch (severity) {
      case 'Not Present':
        return 0;
      case 'Mild':
        return 1;
      case 'Moderate':
        return 2;
      case 'Severe':
        return 3;
      case 'Very Severe':
        return 4;
      default:
        return 0; // Default to 0 if unrecognized
    }
  }

  void onSymptomChanged(String? newSymptom) {
    setState(() {
      selectedSymptom = newSymptom!;
      severity = symptoms.firstWhere((symptom) => symptom.symptom == selectedSymptom).severity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      shadowColor: Colors.black.withOpacity(0.2),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Symptom Status',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            SizedBox(height: 10),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedSymptom,
                onChanged: onSymptomChanged,
                icon: Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                iconSize: 24,
                elevation: 16,
                style: TextStyle(color: Colors.red[800], fontSize: 18),
                dropdownColor: Colors.white,
                items: symptoms.map<DropdownMenuItem<String>>((SymptomData value) {
                  return DropdownMenuItem<String>(
                    value: value.symptom,
                    child: Row(
                      children: [
                        Icon(
                          _getSymptomIcon(value.symptom),
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text(value.symptom),
                      ],
                    ),
                  );
                }).toList(),
                isExpanded: true,
              ),
            ),
            SizedBox(height: 20),
            SfRadialGauge(
              enableLoadingAnimation: true,
              animationDuration: 2000,
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: 4,
                  ranges: <GaugeRange>[
                    GaugeRange(startValue: 0, endValue: 1, color: Colors.green, label: 'Mild', startWidth: 10, endWidth: 10),
                    GaugeRange(startValue: 1, endValue: 2, color: Colors.yellow, label: 'Moderate', startWidth: 10, endWidth: 10),
                    GaugeRange(startValue: 2, endValue: 3, color: Colors.orange, label: 'Severe', startWidth: 10, endWidth: 10),
                    GaugeRange(startValue: 3, endValue: 4, color: Colors.red, label: 'Very Severe', startWidth: 10, endWidth: 10),
                  ],
                  pointers: [
                    NeedlePointer(
                      value: severity.toDouble(),
                      enableAnimation: true,
                      animationType: AnimationType.ease,
                      needleEndWidth: 6,
                      needleLength: 0.8,
                      knobStyle: const KnobStyle(
                        knobRadius: 0.08,
                        color: Colors.white,
                        borderWidth: 0.02,
                        borderColor: Colors.black,
                      ),
                    )
                  ],
                  annotations: [
                    GaugeAnnotation(
                      widget: Container(
                        child: Text(
                          '$severity / 4',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      angle: 90,
                      positionFactor: 0.5,
                    )
                  ],
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSymptomIcon(String symptom) {
    switch (symptom) {
      case 'Coughing':
        return Icons.sick;
      case 'Chest Pain':
        return Icons.favorite;
      case 'Headaches':
        return Icons.headset;
      case 'Runny Nose':
        return Icons.water_drop;
      default:
        return Icons.warning;
    }
  }
}
