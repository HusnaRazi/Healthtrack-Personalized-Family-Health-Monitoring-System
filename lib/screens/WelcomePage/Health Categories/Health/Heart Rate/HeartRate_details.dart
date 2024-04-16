import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Heart%20Rate/HeartRate_allinput.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Heart%20Rate/HeartRate_guide.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HeartRateDetails extends StatefulWidget {
  const HeartRateDetails({Key? key}) : super(key: key);

  @override
  State<HeartRateDetails> createState() => _HeartRateDetailsState();
}

class _HeartRateDetailsState extends State<HeartRateDetails> {
  List<_ChartData> chartData = [];
  String latestUpdate = "Loading latest update...";
  late StreamSubscription<QuerySnapshot> subscription;
  double latestBpmProgress = 0;
  int latestBpm = 0;

  @override
  void initState() {
    super.initState();
    subscription = FirebaseFirestore.instance
        .collection('Heart Rate')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      final newData = snapshot.docs.map((doc) {
        final Timestamp timestamp = doc['timestamp'];
        final DateTime dateTimeWithTimezone = timestamp.toDate().add(
            const Duration(hours: 8));
        return _ChartData(dateTimeWithTimezone, doc['bpm']);
      }).toList();

      if (snapshot.docs.isNotEmpty) {
        final latestDoc = snapshot.docs.first;
        final Timestamp latestTimestamp = latestDoc['timestamp'];
        final DateTime utcDateTimeWithTimezone = latestTimestamp.toDate().add(
            const Duration(hours: 8));
        final latestBpmValue = latestDoc['bpm']; // Changed variable name

        String formattedDateTimeWithTimezone = DateFormat.yMd()
            .add_Hms()
            .format(utcDateTimeWithTimezone);

        latestUpdate =
        "Latest BPM: $latestBpmValue at $formattedDateTimeWithTimezone";

        latestBpm = latestBpmValue;
        latestBpmProgress = latestBpmValue / 200;
      }

      setState(() {
        chartData = newData;
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  String getHeartRateStatus() {
    if (latestBpm < 60) {
      return "Good";
    } else if (latestBpm >= 60 && latestBpm <= 100) {
      return "Normal";
    } else {
      return "Critical";
    }
  }

  Color getStatusColor() {
    if (latestBpm > 100) {
      return Colors.red; // Critical
    } else if (latestBpm >= 60 && latestBpm <= 100) {
      return Colors.green; // Normal
    } else {
      return Colors.orange;
    }
  }

  void _showCalendarPicker(BuildContext context) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
    );

    if (selectedDate != null) {
      print("Selected date: $selectedDate");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100],
        title: const Text('Heart Rate Report'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 20,
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_calendar_sharp),
            onPressed: () {
              _showCalendarPicker(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HeartRateAllData()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
              width: double.infinity,
              height: 200,
              child: _buildLiveLineChart(),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                latestUpdate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 36.0),
                  child: Text(
                    getHeartRateStatus(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: getStatusColor(),
                    ),
                  ),
                ),

                Padding(
                    padding: const EdgeInsets.only(right: 24.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          Container(
                            width: 130,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 1000),
                            curve: Curves.easeOut,
                            width: 200 * (latestBpm / 200.0),
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [getStatusColor().withOpacity(0.5), getStatusColor()],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const Card(
              elevation: 5,
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Heart rate, also known as pulse, is the number of times your heart beats per minute.'
                          'It is an important indicator of your overall health and fitness level.'
                          'Your resting heart rate is when the heart is pumping the lowest amount of blood you need because you are not exercising.'
                          'A normal resting heart rate for adults ranges from 60 to 100 beats per minute.',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildFactorsCard(),
            const SizedBox(height: 20),
            _buildGuideCard(),
            const SizedBox(height: 20),
            _buildCheckCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorsCard() {
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: ExpansionTile(
        leading: Icon(Icons.medical_information_outlined, color: Colors.red),
        // Example icon
        title: Text(
          'Factors Affecting Heart Rate',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          ListTile(
            leading: Icon(Icons.wb_sunny), // Example factor icon
            title: Text('Air Temperature'),
            subtitle: Text(
                'Increases in temperature or humidity may increase heart rate.'),
          ),
          ListTile(
            leading: Icon(Icons.directions_walk),
            title: Text('Body Position'),
            subtitle: Text(
                'Transitioning from sitting to standing can temporarily raise heart rate.'),
          ),
          ListTile(
            leading: Icon(Icons.sentiment_very_satisfied),
            title: Text('Emotions'),
            subtitle: Text(
                'Stress, anxiety, or happiness can affect heart rate.'),
          ),
          ListTile(
            leading: Icon(Icons.directions_walk),
            title: Text('Body Size'),
            subtitle: Text(
              'Usually it does not increase your heart rate. However, if you are obese, you may have a higher resting heart rate.',),
          ),
          ListTile(
            leading: Icon(LineAwesomeIcons.pills),
            title: Text('Medication Use'),
            subtitle: Text(
              'Medications that block adrenaline tend to slow your heart rate. Thyroid medication may raise it.',),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildGuideCard() {
    return const HeartRateGuide();
  }

  Widget _buildCheckCard() {
    return const Card(
        margin: EdgeInsets.symmetric(horizontal: 20),
        color: Colors.white,
        child: ExpansionTile(
          leading: Icon(Icons.monitor_heart_outlined, color: Colors.red),
          title: Text(
            'Ways To Measure',
            style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To check pulse at neck',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5), // Add some space between the texts
                  Text(
                    'Place your index and third fingers on your neck to the side of your windpipe.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '\nTo check pulse at wrist',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Place two fingers between the bone and the tendon over your radial artery which is located on the thumb side of your wrist.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '\nWhen you feel the pulse',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Count the number of beats in 15 seconds. Multiply this number by 4 to calculate your beats per minute.',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }

  SfCartesianChart _buildLiveLineChart() {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        edgeLabelPlacement: EdgeLabelPlacement.shift,
        dateFormat: DateFormat('h:mm a'),
        intervalType: DateTimeIntervalType.auto,
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: const NumericAxis(
        minimum: 0,
        maximum: 200,
        axisLine: AxisLine(width: 0),
        majorTickLines: MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(width: 0.5),
      ),
      series: <CartesianSeries<_ChartData, DateTime>>[
      LineSeries<_ChartData, DateTime>(
        dataSource: chartData,
        xValueMapper: (_ChartData data, _) => data.time, // Directly using DateTime
        yValueMapper: (_ChartData data, _) => data.bpm,
          color: Colors.blueAccent,
          width: 2,
          markerSettings: const MarkerSettings(
            isVisible: true,
            width: 4,
            height: 4,
            color: Colors.red,
            borderColor: Colors.white,
            borderWidth: 2,
          ),
        animationDuration: 1500,
        ),
      ],
      tooltipBehavior: TooltipBehavior(
        enable: true),
    );
  }
}

class _ChartData {
  final DateTime time;
  final int bpm;

  _ChartData(this.time, this.bpm);
}