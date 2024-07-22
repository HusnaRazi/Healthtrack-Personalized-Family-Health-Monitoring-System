import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Headache/Headache_AllData.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class HeadacheDetails extends StatefulWidget {
  const HeadacheDetails({super.key});

  @override
  State<HeadacheDetails> createState() => _HeadacheDetailsState();
}

class _HeadacheDetailsState extends State<HeadacheDetails> {
  late TooltipBehavior _tooltipBehavior;
  DateTime selectedDate = DateTime.now();
  bool _isExpanded = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(enable: true);
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToCurrentDate());
  }

  int getNumberOfDaysInMonth(int year, int month) {
    DateTime firstDayThisMonth = DateTime(year, month, 1);
    DateTime firstDayNextMonth = (month == 12)
        ? DateTime(year + 1, 1, 1)
        : DateTime(year, month + 1, 1);
    return firstDayNextMonth
        .difference(firstDayThisMonth)
        .inDays;
  }

  Stream<List<HeadacheData>> getHeadacheDataStream() {
    return FirebaseFirestore.instance.collection('Headaches')
        .where('startDateTime',
        isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDate))
        .where('startDateTime', isLessThanOrEqualTo: Timestamp.fromDate(
        selectedDate.add(Duration(days: 1))))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return HeadacheData.fromFirestore(data);
      }).toList();
    });
  }

  void scrollToCurrentDate() {
    int daysFromMonthStart = selectedDate.day - 1;
    double offset = (60.0 *
        daysFromMonthStart); // Assuming each ListTile has a width of 60.0
    _scrollController.animateTo(
      offset,
      duration: Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color? getSeverityColor(String severity) {
    switch (severity) {
      case 'Not Present':
        return Colors.grey[350];
      case 'Mild':
        return Colors.green;
      case 'Moderate':
        return Colors.orange;
      case 'Severe':
        return Colors.redAccent;
      case 'Very Severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void showHeadacheDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return StreamBuilder<List<HeadacheData>>(
          stream: getHeadacheDataStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                HeadacheData headache = snapshot.data![index];
                return ListTile(
                  title: Text('Area: ${headache.type}'),
                  subtitle: Text('Time: ${DateFormat('hh:mm a').format(headache.start)} to ${DateFormat('hh:mm a').format(headache.end)}'),
                  leading: Icon(Icons.warning, color: getSeverityColor(headache.severity)),
                  trailing: Text(headache.severity),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildGraphCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(8),
        child: StreamBuilder<List<HeadacheData>>(
          stream: getHeadacheDataStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            } else if (snapshot.hasData) {
              return SfCartesianChart(
                primaryXAxis: const CategoryAxis(
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                  majorGridLines: MajorGridLines(width: 0),
                  axisLine: AxisLine(width: 2),
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                primaryYAxis: DateTimeAxis(
                  isVisible: true,
                  intervalType: DateTimeIntervalType.auto,
                  dateFormat: DateFormat('hh:mm a'),
                  majorGridLines: MajorGridLines(width: 0),
                  axisLine: AxisLine(width: 2),
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                series: <CartesianSeries>[
                  RangeColumnSeries<HeadacheData, String>(
                    dataSource: snapshot.data!,
                    xValueMapper: (HeadacheData data, _) => data.severity,
                    highValueMapper: (HeadacheData data, _) =>
                        data.end.millisecondsSinceEpoch.toDouble(),
                    lowValueMapper: (HeadacheData data, _) =>
                        data.start.millisecondsSinceEpoch.toDouble(),
                    pointColorMapper: (HeadacheData data, _) =>
                        getSeverityColor(data.severity),
                    dataLabelSettings: DataLabelSettings(isVisible: false),
                  ),
                ],
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  // Customizing the tooltip to show detailed start and end times
                  builder: (dynamic data, dynamic point, dynamic series,
                      int pointIndex, int seriesIndex) {
                    final coughData = snapshot.data![pointIndex];
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Severity: ${coughData.severity}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.white)),
                          Text('Start Time: ${DateFormat('hh:mm a').format(
                              coughData.start)}', style: TextStyle(
                              fontSize: 12, color: Colors.white)),
                          Text('End Time: ${DateFormat('hh:mm a').format(
                              coughData.end)}', style: TextStyle(
                              fontSize: 12, color: Colors.white)),
                        ],
                      ),
                    );
                  },
                ),
              );
            } else {
              return const Text('No data available');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Headache Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlue[100],
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.list_sharp),
            onPressed: () { // Correct method is onPressed, not onTap
              Navigator.push(
                context,
                MaterialPageRoute(builder: (
                    context) => const HeadacheAllData()), // Assuming CoughDetails is the correct destination widget
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showHeadacheDetails(context),
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildDateSelector(),
            Container(
              height: 300,
              child: buildGraphCard(),
            ),
            buildDefinitionHeadache(),
            buildTypesHeadache(),
            SizedBox(height: 15),
            buildCausesOfHeadache(),
            SizedBox(height: 15),
            buildHeadacheDiagnosis(),
            SizedBox(height: 15),
            buildHeadacheTestsWidget(),
            SizedBox(height: 15),
            buildEmergencySection(context),
            SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  Widget buildDateSelector() {
    int daysInMonth = getNumberOfDaysInMonth(
        selectedDate.year, selectedDate.month);
    return SizedBox(
      height: 60,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: daysInMonth,
        itemBuilder: (context, index) {
          DateTime date = DateTime(
              selectedDate.year, selectedDate.month, index + 1);
          bool isSelected = selectedDate.day == date.day;
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = date;
                scrollToCurrentDate();
              });
            },
            child: Container(
              width: 60,
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected ? Colors.blueAccent : Colors.grey
                        .withOpacity(
                        0.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('EEE').format(date), style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black)),
                  Text(DateFormat('dd').format(date), style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildDefinitionHeadache() {
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
              Text('Definition',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Divider(color: Colors.blueAccent[900]),
              Text(
                'Headaches are common and often feel like pressure or pain in the head or face. They can vary in type, severity, location, and frequency. Most people experience headaches multiple times in their lives, and they are a leading cause of missed work or school days. While most headaches are harmless, some may indicate more serious health issues.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 16, color: Colors.indigo[800]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTypesHeadache() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      // Reduced margins
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0), // Reduced padding
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset('images/type symptom.png'),
          ),
          title: const Text(
            'Types of Headache',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18, // Smaller font size
              color: Colors.black,
            ),
          ),
          trailing: Icon(
            Icons.expand_more,
            size: 20, // Smaller icon size
          ),
          children: <Widget>[
            _buildInteractiveListTile(
              title: 'Primary Headaches',
              description:
              'Includes tension-type, migraine, cluster, and new daily persistent headaches. Not caused by another condition and triggered by factors like alcohol and poor sleep.',
              context: context,
            ),
            _buildInteractiveListTile(
              title: 'Secondary Headaches',
              description:
              'Caused by underlying conditions such as dehydration, sinus issues, and medication overuse. Spinal headaches may occur after procedures like a spinal tap.',
              context: context,
            ),
            _buildInteractiveListTile(
              title: 'Serious Secondary Headaches',
              description:
              'Includes thunderclap headaches which are severe and sudden, often requiring immediate medical attention. Indicators of serious issues like brain bleeds or high blood pressure.',
              context: context,
              isUrgent: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveListTile({
    required BuildContext context,
    required String title,
    required String description,
    bool isUrgent = false,
  }) {
    return GestureDetector(
      onTap: () {
        _showInfoDialog(context, title, description, isUrgent);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2), // Reduced margins
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.teal[700]
            ),
          ),
          subtitle: Text(
            description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14, // Smaller font size
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String description,
      bool isUrgent) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(description),
          actions: <Widget>[
            if (isUrgent)
              TextButton(
                child: Text('Urgent Care', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  // Implement urgent care navigation
                  Navigator.of(context).pop();
                },
              ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

Widget buildCausesOfHeadache() {
  return Card(
    elevation: 4,
    margin: EdgeInsets.symmetric(horizontal: 16),
    child: ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 16),
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Image.asset('images/infection-cause.png'),
      ),
      title: const Text(
        'Causes of Headache',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          ),
      ),
      childrenPadding: EdgeInsets.symmetric(horizontal: 16), // Added vertical padding
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: const <Widget>[
        ListTile(
          leading: Icon(Icons.restart_alt_outlined, color: Colors.orange),  // Added icons for each cause
          title: Text('Headache pain originates from interactions between the brain, blood vessels, and nerves. When specific nerves affecting muscles and blood vessels are activated, they send pain signals to the brain, leading to a headache.'),
        ),
        ListTile(
          leading: Icon(Icons.kitchen, color: Colors.brown),
          title: Text('Certain foods or ingredients like caffeine, alcohol, fermented foods, chocolate, and cheese.'),
        ),
        ListTile(
          leading: Icon(Icons.family_restroom, color: Colors.green),
          title: Text('Genetics'),
        ),
        ListTile(
          leading: Icon(Icons.energy_savings_leaf, color: Colors.purple),
          title: Text('Allergens.'),
        ),
        ListTile(
          leading: Icon(Icons.smoke_free, color: Colors.grey),
          title: Text('Exposure to secondhand smoke.'),
        ),
        ListTile(
          leading: Icon(Icons.warning_amber, color: Colors.yellow),
          title: Text('Strong odors from household chemicals or perfumes.'),
        ),
      ],
    ),
  );
}

Widget buildHeadacheDiagnosis() {
  return Card(
    elevation: 4,
    margin: EdgeInsets.symmetric(horizontal: 16),
    child: ExpansionTile(
      tilePadding: EdgeInsets.symmetric(horizontal: 16),
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Image.asset('images/result.png'),
      ),
      title: const Text(
        'Diagnosis of Headache',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          ),
      ),
      childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: const <Widget>[
        Text('If you often have severe headaches, consult your healthcare provider. Proper diagnosis is crucial for effective treatment. Your provider will review your medical history and symptoms, and perform a physical exam. \n\nThey will ask about your headache\'s:'),
        ListTile(
          leading: Icon(Icons.query_builder, color: Colors.orange),
          title: Text('intensity, frequency, duration, and triggers.'),
        ),
        ListTile(
          leading: Icon(Icons.family_restroom, color: Colors.green),
          title: Text('Family history of headaches is also considered.'),
        ),
        ListTile(
          leading: Icon(Icons.sports_soccer, color: Colors.blue),
          title: Text('Physical activities that worsen the headache are noted.'),
        ),
        ListTile(
          leading: Icon(Icons.visibility, color: Colors.purple),
          title: Text('Additional symptoms like vision problems, balance issues, or fatigue are checked.'),
        ),
        Text('\nNeurological exams may be conducted to rule out other diseases. After these assessments, your provider can determine the type of headache, its seriousness, and if further tests are needed. If the cause is unclear, a referral to a headache specialist might be made.'),
      ],
    ),
  );
}

Widget buildHeadacheTestsWidget() {
  return Card(
    elevation: 4,
    margin: EdgeInsets.symmetric(horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),  // Rounded corners for a modern look
    ),
    child: ExpansionTile(
      initiallyExpanded: false,
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Image.asset('images/Test Option.png'),
      ),
      title: Text(
        'Tests Available',
        style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
        ),
      ),
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'While CT scans and MRIs do not diagnose migraines or tension-type headaches directly, they are essential for ruling out other medical conditions that could be causing headaches.',
            style: TextStyle(fontSize: 16),
          ),
        ),
        ListTile(
          leading: Icon(Icons.scanner, color: Colors.deepPurple),
          title: Text('CT Scan'),
          subtitle: Text('Used to check for issues in the central nervous system that may be causing headaches.'),
        ),
        Divider(thickness: 1.5),
        ListTile(
          leading: Icon(Icons.scanner, color: Colors.deepPurple),
          title: Text('MRI'),
          subtitle: Text('Provides detailed brain images to identify abnormalities or problems.'),
        ),
      ],
    ),
  );
}

Widget buildEmergencySection(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEmergencyDialog(context),
      child: Card(
        elevation: 4,
        margin: EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Emergency Symptoms',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.red, // Red color to emphasize urgency
                ),
              ),
              Icon(Icons.info_outline, color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

void _showEmergencyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Emergency Headache Symptoms', style: TextStyle(
          color: Colors.redAccent,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Seek immediate medical care if you or someone you know has any of the following:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\n• Sudden, new, and severe headache.'),
              Text('• Headache with fever, shortness of breath, stiff neck, or rash.'),
              Text('• Headaches after a head injury or accident.'),
              Text('• New type of headache after age 55.'),
              Text('\nAlso, seek immediate care if the headache comes with neurological symptoms:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('\n• Weakness or numbness.'),
              Text('• Dizziness or sudden loss of balance.'),
              Text('• Difficulty speaking.'),
              Text('• Confusion, seizures, or personality changes.'),
              Text('• Changes in vision like blurry or double vision.'),
            ],
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.call, color: Colors.red),
            onPressed: () => _makePhoneCall('tel:999'), // Example emergency number, replace with actual
            tooltip: 'Call Emergency Services',
          ),
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<void> _makePhoneCall(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class HeadacheData {
  final DateTime start;
  final DateTime end;
  final String type;
  final String severity;

  HeadacheData({required this.start, required this.end, required this.type, required this.severity});

  factory HeadacheData.fromFirestore(Map<String, dynamic> data) {
    DateTime start = (data['startDateTime'] as Timestamp).toDate();
    DateTime end = (data['endDateTime'] as Timestamp).toDate();
    String type = data['type'] ?? "Unknown";
    String severity = data['severity'];
    return HeadacheData(start: start, end: end, type: type, severity: severity);
  }
}

