import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Vomit/Vomit_AllData.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VomitDetails extends StatefulWidget {
  const VomitDetails({Key? key}) : super(key: key);

  @override
  _VomitDetailsState createState() => _VomitDetailsState();
}

class _VomitDetailsState extends State<VomitDetails> {
  late ScrollController _scrollController;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => scrollToCurrentDate());
  }

  void scrollToCurrentDate() {
    int daysFromMonthStart = selectedDate.day - 1;
    double offset = 60.0 * daysFromMonthStart;
    _scrollController.animateTo(
      offset,
      duration: const Duration(seconds: 1),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Stream<List<VomitData>> getVomitDataStream() {
    return FirebaseFirestore.instance.collection('Vomits')
        .where('DateTime', isGreaterThanOrEqualTo: DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day))
        .where('DateTime', isLessThanOrEqualTo: DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 23, 59))
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) =>
            VomitData.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Color _getColorForSeverity(String severity) {
    switch (severity) {
      case 'Not Present':
        return Colors.green;
      case 'Mild':
        return Colors.lightGreen;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vomit Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlue[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.list_sharp),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const VomitAlldata())),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showVomitDetails(context),
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildDateSelector(),
            Container(height: 300, child: buildGraphCard()),
            buildDefinitionVomit(),
            const SizedBox(height: 10),
            buildCausesOfVomit(),
            const SizedBox(height: 10),
            buildVomitTreatmentMethods(),
          ],
        ),
      ),
    );
  }

  Widget buildDateSelector() {
    int daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0)
        .day;
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
            onTap: () =>
                setState(() {
                  selectedDate = date;
                  scrollToCurrentDate();
                }),
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected ? Colors.blueAccent : Colors.grey
                        .withOpacity(0.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('EEE').format(date)),
                  Text(DateFormat('dd').format(date)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildGraphCard() {
    return StreamBuilder<List<VomitData>>(
      stream: getVomitDataStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        List<VomitData> data = snapshot.hasData && snapshot.data!.isNotEmpty
            ? snapshot.data!
            : [
          VomitData(
            dateTime: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 12),
            severity: 'Not Present',
            type: 'Other',
            frequency: 'Once',
          )
        ];

        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                edgeLabelPlacement: EdgeLabelPlacement.shift,
                dateFormat: DateFormat('hh:mm a'),
                intervalType: DateTimeIntervalType.hours,
              ),
              primaryYAxis: NumericAxis(minimum: 0, maximum: 5, interval: 1),
              series: <StepLineSeries<VomitData, DateTime>>[
                StepLineSeries<VomitData, DateTime>(
                  dataSource: data,
                  xValueMapper: (VomitData data, _) => data.dateTime,
                  yValueMapper: (VomitData data, _) => _severityToNumeric(data.severity),
                  name: 'Severity',
                  animationDuration: 1500,
                  markerSettings: MarkerSettings(isVisible: true),
                  dataLabelSettings: DataLabelSettings(isVisible: true),
                ),
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
              zoomPanBehavior: ZoomPanBehavior(
                enablePanning: true,
                enablePinching: true,
                zoomMode: ZoomMode.x,
              ),
            ),
          ),
        );
      },
    );
  }

  int _severityToNumeric(String severity) {
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
        return 5; // Consider this as an error value or unknown severity
    }
  }


  void showVomitDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return StreamBuilder<List<VomitData>>(
          stream: getVomitDataStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                VomitData vomit = snapshot.data![index];
                return ListTile(
                  title: Text('Vomit: ${vomit.type}'),
                  subtitle: Text('Recorded at: ${DateFormat('hh:mm a').format(vomit.dateTime)}'
                      '\nFrequency: ${vomit.frequency}'),
                  leading: Icon(Icons.local_drink, color: _getColorForSeverity(vomit.severity)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Severity: ${vomit.severity}'),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget buildDefinitionVomit() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 4,
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Divider(color: Colors.blueAccent[900]),
              Text(
                'Vomiting is the forceful expulsion of the contents of the stomach through the mouth. It is a reflex action that occurs when the body tries to rid itself of harmful substances or irritants.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCausesOfVomit() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 4,
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Causes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Divider(color: Colors.blueAccent[900]),
              Text(
                'Common causes of vomiting include viral infections, food poisoning, motion sickness, pregnancy, and gastrointestinal problems.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildVomitTreatmentMethods() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 4,
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Treatment Methods',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Divider(color: Colors.blueAccent[900]),
              Text(
                'Treatment methods vary depending on the underlying cause but often include hydration, rest, and medication. For severe cases, medical consultation is advised.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VomitData {
  final DateTime dateTime;
  final String severity;
  final String type;
  final String frequency;

  VomitData({
    required this.dateTime,
    required this.severity,
    required this.type,
    required this.frequency,
  });

  factory VomitData.fromFirestore(Map<String, dynamic> firestore) {
    return VomitData(
      dateTime: (firestore['DateTime'] as Timestamp).toDate(),
      severity: firestore['severity'] as String,
      type: firestore['type'] as String,
      frequency: firestore['frequency'] as String,
    );
  }
}

