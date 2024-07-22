import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Chest%20Pain/ChestPain_AllData.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:url_launcher/url_launcher.dart';

class ChestPainDetails extends StatefulWidget {
  const ChestPainDetails({Key? key}) : super(key: key);

  @override
  State<ChestPainDetails> createState() => _ChestPainDetailsState();
}

class _ChestPainDetailsState extends State<ChestPainDetails> {
  late TooltipBehavior _tooltipBehavior;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
  }

  Stream<List<ChestPainData>> getChestPainDataStream() {
    return FirebaseFirestore.instance.collection('Chest Pain')
        .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDate))
        .where('startDateTime', isLessThanOrEqualTo: Timestamp.fromDate(selectedDate.add(Duration(days: 1))))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return ChestPainData.fromFirestore(data);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chest Pain Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlue[100],
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChestpainAlldata()), // Assuming CoughDetails is the correct destination widget
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showChestPainDetails(context),
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 80, child: buildDateSelector()),
            Container(
              height: 300,
              child: buildGraphCard(),
            ),
            buildDefinitionChestPain(),
            buildSymptomsChestPain(),
            SizedBox(height: 15),
            buildCausesOfChestPain(),
            SizedBox(height: 15),
            buildChestPainCareTreatment(),
            SizedBox(height: 20),
            buildEmergencySection(context),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget buildDefinitionChestPain() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(8),
      child: Card(
        elevation: 4,
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Definition', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Divider(),
              Text(
                'Chest pain is discomfort in any part of your chest, which might spread to your arms, neck, or jaw. '
                    'This pain can be sharp or dull, and you might feel tightness, achiness, or a sensation of crushing or squeezing. '
                    'Chest pain can last from a few minutes to over six months, often worsening with exertion and easing at rest, but it can also occur while resting. '
                    'The pain might be localized to one area or feel more widespread, affecting the left, middle, or right side of the chest.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 16, color: Colors.indigo[900]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSymptomsChestPain() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/type symptom.png'),
        ),
        title: const Text(
          'Types of Chest Pain',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Text(
            'Heart-related Chest Pain:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 8, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Pressure, fullness, burning or tightness in the chest.'),
                Text('• Crushing or searing pain that spreads to the back, neck, jaw, shoulders, and arms.'),
                Text('• Pain that worsens with activity, may come and go, or varies in intensity.'),
                Text('• Shortness of breath, cold sweats, dizziness, or nausea.'),
              ],
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Other Types of Chest Pain:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 8, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Sour taste or the sensation of food reentering the mouth.'),
                Text('• Pain may improve or worsen with change in body position.'),
                Text('• Pain intensifies when breathing deeply or coughing.'),
                Text('• Tenderness when pushing on the chest.'),
                Text('• Symptoms persist for many hours without significant changes.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCausesOfChestPain() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.symmetric(horizontal: 12),
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/infection-cause.png'),
        ),
        title: Text(
          "Causes of Chest Pain",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        children: const <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Heart-Related Causes:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                ),
                Text(
                  'Includes angina, heart attacks, aortic dissection, and pericarditis.',
                ),
                SizedBox(height: 10),
                Text(
                  'Digestive Causes:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                ),
                Text(
                  'Covers heartburn, swallowing disorders, and gallbladder or pancreas issues.',
                ),
                SizedBox(height: 10),
                Text(
                  'Muscle and Bone Causes:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
                Text(
                  'Involves costochondritis, sore muscles, and injured ribs.',
                ),
                SizedBox(height: 10),
                Text(
                  'Lung-Related Causes:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                Text(
                  'Includes pulmonary embolism, pleurisy, collapsed lung, and pulmonary hypertension.',
                ),
                SizedBox(height: 10),
                Text(
                  'Other Causes:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                Text(
                  'Includes panic attacks and shingles.',
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildChestPainCareTreatment() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.symmetric(horizontal: 12),
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/Treatment Symptom.png'),
        ),
        title: const Text(
            "Treatment of Chest Pain",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
        ),
        children: <Widget>[
          ListTile(
            title: Text(
              "Heart Attack Treatment",
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Emergency treatment is critical, often involving medications and procedures to restore blood flow to the heart.",
              style: TextStyle(fontSize: 14),
            ),
          ),
          Divider(color: Colors.grey, height: 1),
          ListTile(
            title: Text(
              "Noncardiac Treatment",
              style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Treatment options may include lifestyle changes, medicines, or possibly surgery, depending on the specific condition.",
              style: TextStyle(fontSize: 14),
            ),
          ),
          Divider(color: Colors.grey, height: 1),
          ListTile(
            title: Text(
              "Prevention",
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Reducing the risk involves maintaining a healthy lifestyle, managing existing conditions, and avoiding risk factors like smoking.",
              style: TextStyle(fontSize: 14),
            ),
          ),
          Divider(color: Colors.grey, height: 1),
          ListTile(
            title: Text(
              "Important Note",
              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Always seek immediate medical help if you experience severe chest pain to rule out life-threatening conditions.",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmergencySection(BuildContext context) {
    return InkWell(
      onTap: () {
        showEmergencyDialog(context);
      },
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.redAccent.shade200, Colors.redAccent.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16),
            title: const Text(
              "Emergency Cough Situations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            subtitle: const Text(
              "Immediate actions to take in case of severe chest pain.",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ),
    );
  }

  void showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Emergency Cough Situations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'When to Call the Doctor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'If you have chest pain that lasts longer than five minutes and doesn’t go away when you rest or take medication, get immediate help.',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 12),
                Text(
                  'Chest pain can be a sign of a heart attack. Other signs include:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Sweating.'),
                Text('• Nausea or vomiting.'),
                Text('• Shortness of breath.'),
                Text('• Light-headedness or fainting.'),
                Text('• A rapid or irregular heartbeat.'),
                Text('• Pain in your back, jaw, neck, upper abdomen, arm, or shoulder.'),
              ],
            ),
          ),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green, // Background color
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    icon: Icon(Icons.call, color: Colors.white),
                    label: Text(
                      'Call Emergency',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () => launchUrl(Uri.parse("tel:999")),
                  ),
                  TextButton(
                    child: Text('Understood', style: TextStyle(fontSize: 14, color: Colors.purple)),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void showChestPainDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return StreamBuilder<List<ChestPainData>>(
          stream: getChestPainDataStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                ChestPainData chestpain = snapshot.data![index];
                return ListTile(
                  title: Text('${chestpain.severity} Chest Pain'),
                  subtitle: Text('Starts: ${DateFormat('hh:mm a').format(chestpain.start)}\nEnds: ${DateFormat('hh:mm a').format(chestpain.end)}'),
                  leading: Icon(Icons.health_and_safety, color: chestpain.color),
                  trailing: Text('Duration: ${(chestpain.end.difference(chestpain.start).inMinutes)} mins'),
                );
              },
            );
          },
        );
      },
    );
  }

  List<DateTime> _generateDateList() {
    DateTime now = DateTime.now();
    int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return List<DateTime>.generate(daysInMonth, (index) => DateTime(now.year, now.month, index + 1));
  }

  Widget buildDateSelector() {
    List<DateTime> dates = _generateDateList();
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: dates.length,
      itemBuilder: (context, index) {
        DateTime date = dates[index];
        bool isSelected = selectedDate.year == date.year && selectedDate.month == date.month && selectedDate.day == date.day;
        return GestureDetector(
          onTap: () => setState(() => selectedDate = DateTime(date.year, date.month, date.day)),
          child: Container(
            width: 60,
            margin: EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('EEE').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
                Text(DateFormat('dd').format(date), style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildGraphCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(8),
        child: StreamBuilder<List<ChestPainData>>(
          stream: getChestPainDataStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            } else if (snapshot.hasData) {
              return SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: DateTimeAxis(
                  intervalType: DateTimeIntervalType.auto,
                  dateFormat: DateFormat('hh:mm a'),
                  majorGridLines: MajorGridLines(width: 0),
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                    final chestPainData = snapshot.data![pointIndex];
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Severity: ${chestPainData.severity}', style: const TextStyle(
                              fontSize: 12, color: Colors.white)
                          ),
                          Text('Start Time: ${DateFormat('hh:mm a').format(chestPainData.start)}',
                              style: TextStyle(fontSize: 12, color: Colors.white)),
                          Text('End Time: ${DateFormat('hh:mm a').format(chestPainData.end)}',
                              style: TextStyle(fontSize: 12, color: Colors.white)),
                        ],
                      ),
                    );
                  },
                ),
                series: <CartesianSeries>[
                  RangeColumnSeries<ChestPainData, String>(
                    dataSource: snapshot.data!,
                    xValueMapper: (ChestPainData data, _) => data.severity,
                    highValueMapper: (ChestPainData data, _) => data.end.millisecondsSinceEpoch.toDouble(),
                    lowValueMapper: (ChestPainData data, _) => data.start.millisecondsSinceEpoch.toDouble(),
                    pointColorMapper: (ChestPainData data, _) => data.color,
                    name: 'Chest Pain Episodes',
                    animationDuration: 1500,
                  )
                ],
              );
            } else {
              return const Text('No data available');
            }
          },
        ),
      ),
    );
  }


}

class ChestPainData {
  final DateTime start;
  final DateTime end;
  final String severity;
  final Color color;

  ChestPainData({required this.start, required this.end, required this.severity, required this.color});

  factory ChestPainData.fromFirestore(Map<String, dynamic> data) {
    DateTime start = (data['startDateTime'] as Timestamp).toDate();
    DateTime end = (data['endDateTime'] as Timestamp).toDate();
    String severity = data['condition'] ?? "Unknown";
    Color color = _getColorFromSeverity(severity);
    return ChestPainData(start: start, end: end, severity: severity, color: color);
  }

  static Color _getColorFromSeverity(String severity) {
    switch (severity) {
      case 'Mild': return Colors.yellow;
      case 'Moderate': return Colors.orange;
      case 'Severe': return Colors.redAccent;
      case 'Very Severe': return Colors.red;
      default: return Colors.grey;
    }
  }
}
