import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Coughing/Cough_AllData.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class CoughDetails extends StatefulWidget {
  const CoughDetails({super.key});

  @override
  State<CoughDetails> createState() => _CoughDetailsState();
}

class _CoughDetailsState extends State<CoughDetails> {
  late TooltipBehavior _tooltipBehavior;
  DateTime selectedDate = DateTime.now();
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
  }

  Stream<List<CoughData>> getCoughDataStream() {
    return FirebaseFirestore.instance.collection('Coughing')
        .where('startDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDate))
        .where('startDateTime', isLessThanOrEqualTo: Timestamp.fromDate(selectedDate.add(Duration(days: 1))))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return CoughData.fromFirestore(data);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cough Report', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlue[100],
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.list_sharp),
            onPressed: () { // Correct method is onPressed, not onTap
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CoughListdata()), // Assuming CoughDetails is the correct destination widget
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showCoughDetails(context),
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
            buildDefinitionCough(),
            buildTypesCough(),
            SizedBox(height: 15),
            buildCausesOfCough(),
            SizedBox(height: 15),
            buildCoughCareTreatment(),
            SizedBox(height: 20),
            buildEmergencySection(),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget buildDefinitionCough() {
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
              Text('Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Divider(color: Colors.blueAccent[900]),
              Text(
                'A cough is a natural reflex that is your body’s way of removing irritants from your upper (throat) and lower (lungs) airways. A cough helps your body heal and protect itself.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 16, color: Colors.indigo[800]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTypesCough() {
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
          'Types of Cough',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,  // Highlighting the title with a vibrant color
          ),
        ),
        childrenPadding: EdgeInsets.symmetric(horizontal: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildCoughDetail(
              'Acute Cough',
              'Begins suddenly, lasting 2-3 weeks.',
              iconData: Icons.looks_one_outlined
          ),
          buildCoughDetail(
              'Subacute Cough',
              'Persists post-infection for 3-8 weeks.',
              iconData: Icons.looks_two_outlined
          ),
          buildCoughDetail(
              'Chronic Cough',
              'Lasts longer than eight weeks, also known as persistent cough.',
              iconData: Icons.three_k_outlined
          ),
          buildCoughDetail(
              'Refractory Cough',
              'A chronic cough that has not responded to conventional treatment.',
              iconData: Icons.four_k_outlined
          ),
          buildCoughDetail(
              'Productive (Wet) Cough',
              'Brings up mucus or phlegm.',
              iconData: Icons.five_k_outlined
          ),
          buildCoughDetail(
              'Non-Productive (Dry) Cough',
              'Does not bring up mucus or phlegm.',
              iconData: Icons.six_k_outlined
          ),
          buildCoughDetail(
              'Whooping',
              'Sounds like a whoop, associated with Pertussis or whooping cough.',
              iconData: Icons.eight_k_outlined
          ),
          buildCoughDetail(
              'Barking',
              'Resembles a barking sound, often indicative of croup.',
              iconData: Icons.nine_k_outlined
          ),
          buildCoughDetail(
              'Wheezing',
              'Typically occurs with blocked airways, associated with infections like colds or chronic conditions like asthma.',
              iconData: Icons.ten_k_outlined
          ),
          buildCoughDetail(
              'Daytime Cough',
              'Occurs during the day.',
              iconData: Icons.eleven_mp_outlined
          ),
          buildCoughDetail(
              'Nighttime (Nocturnal) Cough',
              'Happens during the night.',
              iconData: Icons.twelve_mp_outlined
          ),
          buildCoughDetail(
              'Cough with Vomiting',
              'Common in children, where intense coughing leads to gagging and vomiting.',
              iconData: Icons.thirteen_mp_outlined
          ),
        ],
      ),
    );
  }

  Widget buildCausesOfCough() {
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
        title: const Text(
          'Causes of Cough',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        childrenPadding: EdgeInsets.symmetric(horizontal: 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildCoughCauseDetail(
              'Throat Clearing',
              'A natural response to clear your throat of mucus or irritants like dust or smoke.'
          ),
          buildCoughCauseDetail(
              'Viruses',
              'Common respiratory infections like colds or flu often lead to a cough. This includes viruses such as COVID-19, which can also cause prolonged coughing in long COVID.'
          ),
          buildCoughCauseDetail(
              'Smoking',
              'Chronic cough, known as smoker\'s cough, results from ongoing smoking and has a distinct sound.'
          ),
          buildCoughCauseDetail(
              'Asthma',
              'Especially in children, asthma can cause coughing that involves wheezing, typically treated with inhalers or nebulizers.'
          ),
          buildCoughCauseDetail(
              'Medications',
              'Some medications, like ACE inhibitors used for blood pressure, can lead to coughing as a side effect.'
          ),
          buildCoughCauseDetail(
              'Other Conditions',
              'Various conditions can cause coughing, including GERD, where stomach acid flows back into the esophagus, stimulating a cough reflex.'
          ),
        ],
      ),
    );
  }

  Widget buildCoughCauseDetail(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 30, color: Colors.blueGrey)),  // Bullet point as a text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCoughCareTreatment() {
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
          'Treatment of Cough',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,  // Elegant deep purple for title
          ),
        ),
        trailing: AnimatedSwitcher(
          duration: Duration(milliseconds: 250),
          child: Icon(
            Icons.expand_more, // This will rotate based on the tile's expansion state
            key: ValueKey<bool>(!_isExpanded),
          ),
        ),
        onExpansionChanged: (bool expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        childrenPadding: EdgeInsets.symmetric(horizontal: 24),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildTextSection(
              'Managing a Cough:',
              'Treatment varies based on the cause. For infections, antibiotics or antivirals might be necessary. GERD may require diet adjustments and specific medications.',
              color: Colors.deepPurple
          ),
          buildTextSection(
              'Home Remedies:',
              'Hydration, vaporizers, and avoiding irritants are key. Honey, throat lozenges, or hot beverages can also provide relief.',
              color: Colors.deepPurple
          ),
          buildTextSection(
              'Over-the-Counter Treatments:',
              'While many options are available, natural remedies like honey are often just as effective.',
              color: Colors.deepPurple
          ),
          buildTextSection(
              'Prevention Tips:',
              'Stay vaccinated, avoid contact with the sick, and practice good hygiene to prevent infections.',
              color: Colors.deepPurple
          ),
          buildTextSection(
              'Important Note for Children:',
              'Consult a doctor before giving cough medicines to children under 6 years old.',
              color: Colors.red  // Red color for emphasis on important notes
          ),
        ],
      ),
    );
  }

  Widget buildEmergencySection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: InkWell(
            onTap: () => showEmergencyDialog(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.red[600],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Emergency Cough Situations',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24)
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Emergency Cough Situations',
              style: TextStyle(fontSize:18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red)),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Seek immediate medical help if you experience any of the following:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('• Choking or feeling like you’re choking.'),
                Text('• Difficulty breathing or sudden breathlessness.'),
                Text('• Coughing up a significant amount of blood.'),
                Text('• Severe chest pain.'),
              ],
            ),
          ),
          actions: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: Colors.green,  // Green background
                shape: BoxShape.circle,  // Circular shape
              ),
              child: IconButton(
                icon: const Icon(Icons.call, color: Colors.white),
                onPressed: () => launchUrl(Uri.parse("tel:911")), // Adjust the phone number as needed
                tooltip: 'Call Emergency',
              ),
            ),
            TextButton(
              child: Text('Understood'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildTextSection(String title, String description, {Color color = Colors.blueGrey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,  // Customizable color for titles
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 4),
            child: Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCoughDetail(String title, String description, {required IconData iconData}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: Icon(iconData, color: Colors.purple),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.teal, // Using a consistent theme color for titles
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
      ),
    );
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
        child: StreamBuilder<List<CoughData>>(
          stream: getCoughDataStream(),
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
                  // Customizing the tooltip to show detailed start and end times
                  builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                    final coughData = snapshot.data![pointIndex];
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Severity: ${coughData.severity}', style: const TextStyle(
                              fontSize: 12, color: Colors.white)
                          ),
                          Text('Start Time: ${DateFormat('hh:mm a').format(coughData.start)}',
                              style: TextStyle(fontSize: 12, color: Colors.white)),
                          Text('End Time: ${DateFormat('hh:mm a').format(coughData.end)}',
                              style: TextStyle(fontSize: 12, color: Colors.white)),
                        ],
                      ),
                    );
                  },
                ),
                series: <CartesianSeries>[
                  RangeColumnSeries<CoughData, String>(
                    dataSource: snapshot.data!,
                    xValueMapper: (CoughData data, _) => data.severity,
                    highValueMapper: (CoughData data, _) => data.end.millisecondsSinceEpoch.toDouble(),
                    lowValueMapper: (CoughData data, _) => data.start.millisecondsSinceEpoch.toDouble(),
                    pointColorMapper: (CoughData data, _) => data.color,
                    name: 'Cough Episodes',
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

  void showCoughDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return StreamBuilder<List<CoughData>>(
          stream: getCoughDataStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                CoughData cough = snapshot.data![index];
                return ListTile(
                  title: Text('${cough.severity} Cough'),
                  subtitle: Text('Starts: ${DateFormat('hh:mm a').format(cough.start)}\nEnds: ${DateFormat('hh:mm a').format(cough.end)}'),
                  leading: Icon(Icons.health_and_safety, color: cough.color),
                  trailing: Text('Duration: ${(cough.end.difference(cough.start).inMinutes)} mins'),
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
}

class CoughData {
  final DateTime start;
  final DateTime end;
  final String severity;
  final Color color;

  CoughData({required this.start, required this.end, required this.severity, required this.color});

  factory CoughData.fromFirestore(Map<String, dynamic> data) {
    DateTime start = (data['startDateTime'] as Timestamp).toDate();
    DateTime end = (data['endDateTime'] as Timestamp).toDate();
    String severity = data['severity'] ?? "Unknown";
    Color color = _getColorFromSeverity(severity);
    return CoughData(start: start, end: end, severity: severity, color: color);
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
