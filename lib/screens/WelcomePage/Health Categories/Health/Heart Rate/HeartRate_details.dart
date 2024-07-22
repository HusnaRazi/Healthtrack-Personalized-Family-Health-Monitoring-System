import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Heart%20Rate/HeartRate_allinput.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Heart%20Rate/HeartRate_guide.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:url_launcher/url_launcher.dart';

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
        // Convert Firestore timestamp to local DateTime
        final DateTime dateTimeUtc = timestamp.toDate();
        final DateTime dateTimeLocal = dateTimeUtc.toLocal();

        return _ChartData(dateTimeLocal, doc['bpm']);
      }).toList();

      if (snapshot.docs.isNotEmpty) {
        final latestDoc = snapshot.docs.first;
        final Timestamp latestTimestamp = latestDoc['timestamp'];
        // Convert to local DateTime
        final DateTime utcDateTime = latestTimestamp.toDate();
        final DateTime localDateTime = utcDateTime.toLocal();
        final latestBpmValue = latestDoc['bpm'];

        // Formatting the local DateTime
        String formattedDateTime = DateFormat('dd/MM/yyyy hh:mm a').format(localDateTime);

        latestUpdate =
        "Latest BPM: $latestBpmValue at $formattedDateTime";

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

  Future<List<_ChartData>> fetchHeartRateDataForDate(DateTime date) async {
    print("Fetching heart rate data for date: $date");
    DateTime startDate = DateTime(date.year, date.month, date.day);
    DateTime endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
    print("Start date: $startDate, End date: $endDate");

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('Heart Rate')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp')
          .get();

      var data = snapshot.docs.map((doc) {
        Timestamp timestamp = doc['timestamp'];
        DateTime dateTime = timestamp.toDate().toLocal();
        int bpm = doc['bpm'];
        return _ChartData(dateTime, bpm);  // Assuming _HeartRateData is defined with DateTime and int
      }).toList();

      print("Heart rate data fetched successfully, count: ${data.length}");
      return data;
    } catch (e) {
      print("Error fetching heart rate data: $e");
      return [];
    }
  }

  void _showHeartRateCalendarPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.red),
            dialogBackgroundColor: Colors.white,
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      print("Date picked: $picked");
      try {
        List<_ChartData> dataForDate = await fetchHeartRateDataForDate(picked);
        print("Data for dialog ready, showing dialog...");

        if (dataForDate.isEmpty) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('No Data Available'),
                content: const Text('No heart rate data available for the selected date.'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                elevation: 8.0,
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Graph for ${DateFormat.yMMMd().format(picked)}',
                        style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                      const SizedBox(height: 20.0),
                      SizedBox(
                        width: double.infinity,
                        height: 300,
                        child: buildHeartRateChart(dataForDate),
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close', style: TextStyle(fontSize: 16.0, color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      } catch (e) {
        print("Failed to load data or show dialog: $e");
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to load data: $e'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } else {
      print("No date was picked.");
    }
  }

  Widget buildHeartRateChart(List<_ChartData> data) {
    return SfCartesianChart(
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat('h:mm a'), // Format time in 12-hour notation with AM/PM
        intervalType: DateTimeIntervalType.hours,
        interval: 1, // Set interval to 1 hour; adjust if needed based on data density
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: const NumericAxis(
        autoScrollingMode: AutoScrollingMode.start,
        axisLine: AxisLine(width: 0),
        majorTickLines: MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(width: 0.5),
      ),
      series: <LineSeries<_ChartData, DateTime>>[
        LineSeries<_ChartData, DateTime>(
          dataSource: data,
          xValueMapper: (_ChartData data, _) => data.time,
          yValueMapper: (_ChartData data, _) => data.bpm,  // Ensure the mapper uses the bpm field
          color: Colors.redAccent,
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
      tooltipBehavior: TooltipBehavior(enable: true),
    );
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
              _showHeartRateCalendarPicker();
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const HeartRateAllData()),
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Text(
                latestUpdate,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 36.0),
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
                              colors: [
                                getStatusColor().withOpacity(0.5),
                                getStatusColor()
                              ],
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
            const SizedBox(height: 15),
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
            const SizedBox(height: 15),
            _buildFactorsCard(),
            const SizedBox(height: 10),
            _buildGuideCard(),
            const SizedBox(height: 10),
            _buildCheckCard(),
            const SizedBox(height: 10),
            _HighHeartRateCard(),
            const SizedBox(height: 10),
            _LowHeartRateCard(),
            const SizedBox(height: 20),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildCreditsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorsCard() {
    return Card(
      elevation: 4, // Adds a subtle shadow for depth
      margin: EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Smooths corners for a softer look
      ),
      child: ExpansionTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/heart-attack.png'),
        ),
        title: Text(
          'Factors Affecting',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Adds a professional tone to the title
          ),
        ),
        children: const [
          ListTile(
            leading: Icon(Icons.wb_sunny, color: Colors.orange), // Color-coded for clarity
            title: Text('Air Temperature'),
            subtitle: Text(
              'Increases in temperature or humidity may increase heart rate.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.directions_walk, color: Colors.green), // Color-coded for clarity
            title: Text('Body Position'),
            subtitle: Text(
              'Transitioning from sitting to standing can temporarily raise heart rate.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.sentiment_very_satisfied, color: Colors.blue), // Color-coded for clarity
            title: Text('Emotions'),
            subtitle: Text(
              'Stress, anxiety, or happiness can affect heart rate.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.fitness_center, color: Colors.purple), // Changed icon for relevance
            title: Text('Body Size'),
            subtitle: Text(
              'Usually it does not increase your heart rate. However, if you are obese, you may have a higher resting heart rate.',
            ),
          ),
          ListTile(
            leading: Icon(LineAwesomeIcons.pills, color: Colors.redAccent), // Consistent icon styling
            title: Text('Medication Use'),
            subtitle: Text(
              'Medications that block adrenaline tend to slow your heart rate. Thyroid medication may raise it.',
            ),
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: ExpansionTile(
        leading: SizedBox(
        width: 24,
        height: 24,
        child: Image.asset('images/heart-monitoring.png'),
      ),
        title: const Text(
          'Ways To Measure',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
                SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _HighHeartRateCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: ExpansionTile(
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset('images/hight heart-rate.png'),
          ),
          title: const Text(
            'Tachycardia',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: const [
            Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A resting heart rate over 100 bpm is called tachycardia. This may indicate issues with your heart\'s conduction system, such as atrial flutter or ventricular tachycardia.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  'Possible Causes:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Dehydration', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Infection', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Fever', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Pain', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Anxiety', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 10),
                      Text('Thyroid disorders', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Note: Factors like stress, weather conditions, or emotions might temporarily raise your heart rate. Check again when these factors are absent.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _LowHeartRateCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: ExpansionTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/low heart-rate.png'), // Ensure you have an appropriate asset
        ),
        title: const Text(
          'Bradycardia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A resting heart rate under 60 bpm is called bradycardia. This condition can be normal for well-trained athletes but may indicate problems in others, such as heart signal issues.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(fontSize: 15),
                ),
                SizedBox(height: 20),
                Text(
                  'Possible Causes:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.blue),
                      SizedBox(width: 10),
                      Text('Heart signal issues (e.g., heart block)', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.blue),
                      SizedBox(width: 10),
                      Text('Beta-blocker medications', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.blue),
                      SizedBox(width: 10),
                      Text('High physical fitness (athletes)', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Note: Consult your doctor if you are concerned about your low resting heart rate, especially if you experience symptoms like dizziness or fatigue.',
                  style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildCreditsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'Info provided by: ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () => launchUrl(Uri.parse('https://www.heart.org/en/health-topics/high-blood-pressure/understanding-blood-pressure-readings')),
              child: const Text(
                'American Heart Association',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Text(' and '),
            TextButton(
              onPressed: () => launchUrl(Uri.parse('https://my.clevelandclinic.org/health/diagnostics/heart-rate')),
              child: const Text(
                'Cleveland Clinic',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SfCartesianChart _buildLiveLineChart() {
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      primaryXAxis: DateTimeAxis(
        edgeLabelPlacement: EdgeLabelPlacement.shift,
        dateFormat: DateFormat('h:mm a'),
        // Format time in 12-hour notation with AM/PM
        intervalType: DateTimeIntervalType.auto,
        majorGridLines: const MajorGridLines(width: 0),
        labelStyle: TextStyle(
          fontSize: 10,
        ),
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
          xValueMapper: (_ChartData data, _) => data.time,
          // Assumes data.time is already in local timezone
          yValueMapper: (_ChartData data, _) => data.bpm,
          color: Colors.deepOrange[600],
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
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }
}

  class _ChartData {
  final DateTime time;
  final int bpm;

  _ChartData(this.time, this.bpm);
}