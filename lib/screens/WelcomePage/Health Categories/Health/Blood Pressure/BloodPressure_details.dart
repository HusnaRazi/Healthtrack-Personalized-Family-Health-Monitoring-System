import 'dart:async';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Blood%20Pressure/BloodPressureData.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Blood%20Pressure/BloodPressure_level.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Blood%20Pressure/Ways%20to%20measure.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const MaterialApp(home: BloodPressureDetails()));

class BloodPressureDetails extends StatefulWidget {
  const BloodPressureDetails({Key? key}) : super(key: key);

  @override
  State<BloodPressureDetails> createState() => _BloodPressureDetailsState();
}

class _BloodPressureDetailsState extends State<BloodPressureDetails> {
  List<ChartData> systolicChartData = [];
  List<ChartData> diastolicChartData = [];
  String latestUpdate = "Loading latest update...";
  bool isLoading = true;
  Color currentStatusColor = Colors.grey;
  String currentStatusText = "Unknown";
  List<ChartData> currentChartData = [];  // Data for the selected date
  DateTime? selectedDate;


  @override
  void initState() {
    super.initState();
    fetchBloodPressureData();
  }

  void updateBPStatus(int systolic, int diastolic) {
    setState(() {
      currentStatusColor = getStatusColor(systolic, diastolic);
      currentStatusText = getBPStatus(systolic, diastolic);
    });
  }

  void fetchBloodPressureData() async {
    setState(() {
      isLoading = true;
    });
    try {
      DateTime now = DateTime.now();
      var collection = FirebaseFirestore.instance.collection('Blood Pressure');
      var snapshot = await collection
          .orderBy('timestamp', descending: true)
          .limit(20) // Only fetch the latest 20 entries
          .get();

      List<ChartData> fetchedData = [];
      if (snapshot.docs.isNotEmpty) {
        var latestDoc = snapshot.docs.first;
        var latestData = latestDoc.data() as Map<String, dynamic>;
        DateTime latestTimestamp = (latestData['timestamp'] as Timestamp).toDate().toLocal(); // Convert to local time
        final latestSystolic = latestData['systolic'];
        final latestDiastolic = latestData['diastolic'];

        setState(() {
          latestUpdate = "Latest BP: $latestSystolic/$latestDiastolic at ${DateFormat('dd/MM/yyyy hh:mm a').format(latestTimestamp)}";
          updateBPStatus(latestSystolic, latestDiastolic);
        });

        for (var doc in snapshot.docs) {
          var data = doc.data() as Map<String, dynamic>;
          DateTime localDate = (data['timestamp'] as Timestamp).toDate().toLocal();
          fetchedData.add(ChartData(localDate, data['systolic'].toDouble(), data['diastolic'].toDouble()));
        }
      } else {
        setState(() {
          latestUpdate = "No data found for today.";
        });
      }

      setState(() {
        systolicChartData = fetchedData;
        diastolicChartData = fetchedData;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        latestUpdate = "Error fetching data: $e";
        isLoading = false;
      });
    }
  }

  Future<List<ChartData>> fetchBloodPressureDataForDate(DateTime date) async {
    DateTime startDate = DateTime(date.year, date.month, date.day, 0, 0, 0);
    DateTime endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('Blood Pressure')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp')
          .get();

      print("Number of documents fetched: ${snapshot.docs.length}");
      snapshot.docs.forEach((doc) {
        print(doc['timestamp'].toDate());
      });

      var data = snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        DateTime dateTime = (data['timestamp'] as Timestamp).toDate(); // Ensure this conversion is consistent
        return ChartData(dateTime, data['systolic'].toDouble(), data['diastolic'].toDouble());
      }).toList();

      return data;
    } catch (e) {
      print("Error fetching blood pressure data: $e");
      return [];
    }
  }

  String getBPStatus(int systolic, int diastolic) {
    if (systolic < 90 && diastolic < 60) {
      return "Low Blood Pressure";
    } else if (systolic < 120 && diastolic < 80) {
      return "Normal";
    } else if (systolic >= 120 && systolic < 130 && diastolic < 80) {
      return "Elevated";
    } else if ((systolic >= 130 && systolic < 140) || (diastolic >= 80 && diastolic < 90)) {
      return "Hypertension Stage 1";
    } else if ((systolic >= 140 && systolic < 180) || (diastolic >= 90 && diastolic < 120)) {
      return "Hypertension Stage 2";
    } else if (systolic >= 180 || diastolic >= 120) {
      return "Hypertensive Crisis";
    } else {
      return "Unknown"; // Should not be reachable
    }
  }

  Color getStatusColor(int systolic, int diastolic) {
    if (systolic < 90 && diastolic < 60) {
      return const Color(0xFF0000FF); // Blue, indicates low blood pressure
    } else if (systolic < 120 && diastolic < 80) {
      return const Color(0xFF008000); // Green, indicates normal
    } else if (systolic >= 120 && systolic < 130 && diastolic < 80) {
      return const Color(0xFFFFFF00); // Yellow, indicates elevated
    } else if ((systolic >= 130 && systolic < 140) || (diastolic >= 80 && diastolic < 90)) {
      return const Color(0xFFFFA500); // Orange, indicates Hypertension Stage 1
    } else if ((systolic >= 140 && systolic < 180) || (diastolic >= 90 && diastolic < 120)) {
      return const Color(0xFFFF0000); // Red, indicates Hypertension Stage 2
    } else if (systolic >= 180 || diastolic >= 120) {
      return const Color(0xFF800000); // Dark Red, indicates Hypertensive Crisis
    } else {
      return const Color(0xFFB0B0B0); // Light Grey, undefined or data error
    }
  }

  void _showBloodPressureCalendarPicker() async {
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
        List<ChartData> dataForDate = await fetchBloodPressureDataForDate(picked);
        print("Data for dialog ready, showing dialog...");

        if (dataForDate.isEmpty) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('No Data Available'),
                content: Text('No blood pressure data available for the selected date.'),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0)),
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
                        style: const TextStyle(fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.red),
                      ),
                      const SizedBox(height: 20.0),
                      SizedBox(
                        width: double.infinity,
                        height: 300,
                        child: buildChartForDate(dataForDate), // Now passing the fetched data
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close', style: TextStyle(
                              fontSize: 16.0, color: Colors.red)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100],
        title: const Text('Blood Pressure Report'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 20,  // Increased font size
        ),
        actions: <Widget>[
          IconButton(
          icon: const Icon(Icons.edit_calendar_sharp),
          onPressed: () {
            _showBloodPressureCalendarPicker();
          },
        ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BloodPressureAllData()),
              );
            }
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : buildBody(),
    );
  }

  Widget buildBody() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              Card(
                elevation: 4.0,
                margin: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Colors.white,
                  ),
                  child: buildChart(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  latestUpdate,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'MuseoSlab',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 10),
              buildBPStatus(),
              const SizedBox(height: 15),
              buildInfoCard(),
              const SizedBox(height: 15),
              const WaysToMeasure(),
              const SizedBox(height: 15),
              const BloodPressureLevel(),
              const SizedBox(height: 15),
              _buildBloodPressureSymptomsCard(),
              const SizedBox(height: 15),
              _buildBloodPressureRiskFactorsCard(),
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
      ],
    );
  }

  Widget buildBPStatus() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Text(
            currentStatusText, // Use the dynamically updated status text
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: currentStatusColor, // Color also updates dynamically
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 24.0),
          child: Draggable(
            feedback: Material(
              elevation: 4.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Container(
                width: 110,
                height: 20,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: currentStatusColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    currentStatusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            childWhenDragging: Container(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 110,
                height: 20,
                decoration: BoxDecoration(
                  color: currentStatusColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildChart() => SfCartesianChart(
    primaryXAxis: DateTimeAxis(
      dateFormat: DateFormat('h:mm a'),
      intervalType: DateTimeIntervalType.auto,
      edgeLabelPlacement: EdgeLabelPlacement.shift,
      majorGridLines: const MajorGridLines(width: 0), // hide major grid lines
    ),
    primaryYAxis: const NumericAxis(
        autoScrollingMode: AutoScrollingMode.start,
        axisLine: AxisLine(width: 0),  // hide the axis line
        majorTickLines: MajorTickLines(size: 0) // hide major tick lines
    ),
    series: <LineSeries<ChartData, DateTime>>[
      LineSeries<ChartData, DateTime>(
          dataSource: systolicChartData,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.systolic,
          name: 'Systolic',
          dataLabelSettings: const DataLabelSettings(isVisible: true)
      ),
      LineSeries<ChartData, DateTime>(
          dataSource: diastolicChartData,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.diastolic,
          name: 'Diastolic',
          dataLabelSettings: const DataLabelSettings(isVisible: true)
      ),
    ],
    tooltipBehavior: TooltipBehavior(enable: true),
    trackballBehavior: TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipSettings: InteractiveTooltip(enable: true, format: 'point.x : point.y'),
    ),
    zoomPanBehavior: ZoomPanBehavior(
      enablePinching: true,
      zoomMode: ZoomMode.x,
      enablePanning: true,
    ),
    crosshairBehavior: CrosshairBehavior(
      enable: true,
      lineType: CrosshairLineType.both,
      lineWidth: 1,
      activationMode: ActivationMode.longPress,
    ),
  );

  Widget buildInfoCard() => const Card(
    elevation: 5,
    margin: EdgeInsets.symmetric(horizontal: 20),
    child: Padding(
      padding: EdgeInsets.all(16),
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
            'Blood pressure measures the force exerted by blood against the walls of your arteries. As your heart beats, which occurs 60 to 100 times per minute every day, it sends blood through these arteries, distributing it across your body. This circulation delivers essential oxygen and nutrients to all parts of your body, enabling it to operate properly.',
            style: TextStyle(
              fontSize: 16,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    ),
  );
}

Widget _buildBloodPressureSymptomsCard() {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    elevation: 2,
    child: ExpansionTile(
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Image.asset('images/symptom1.png'),
      ),
      title: const Text(
        'Symptoms',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: const <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What blood pressure is too high?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'If your top number (systolic) is ever 180 or higher or your bottom number (diastolic) is ever 120 or higher, seek emergency medical treatment immediately. This is a hypertensive crisis, a severe condition that must be addressed right away.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 20),
              Text(
                'During a hypertensive crisis, symptoms may include:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '• Shortness of breath\n'
                    '• Chest pain\n'
                    '• Difficulty with vision or speech\n'
                    '• Pain in your back\n'
                    '• Weakness or numbness\n'
                    '• Nosebleeds\n'
                    '• Headaches',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildBloodPressureRiskFactorsCard() {
  return Card(
    margin: const EdgeInsets.symmetric(horizontal: 20),
    elevation: 2,
    child: ExpansionTile(
      leading: SizedBox(
        width: 24,
        height: 24,
        child: Image.asset('images/riskfactors.png'),
      ),
      title: const Text(
        'Risk Factors',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildRiskFactorDetails(),
          ),
        ),
      ],
    ),
  );
}

List<Widget> _buildRiskFactorDetails() {
  List<Map<String, dynamic>> factors = [
    {'icon': Icons.cake, 'color': Colors.amber, 'text': 'Age', 'detail': 'Increases with age, more common in men until age 64, and women after age 65.'},
    {'icon': Icons.public, 'color': Colors.green, 'text': 'Race', 'detail': 'Especially common among Black individuals, developing earlier than in white populations.'},
    {'icon': Icons.group, 'color': Colors.brown, 'text': 'Family history', 'detail': 'Higher likelihood if a parent or sibling has it.'},
    {'icon': Icons.monitor_weight, 'color': Colors.red, 'text': 'Obesity', 'detail': 'Excess weight causes changes increasing blood pressure.'},
    {'icon': Icons.directions_walk, 'color': Colors.blue, 'text': 'Exercise', 'detail': 'Lack of physical activity increases risks.'},
    {'icon': Icons.smoking_rooms, 'color': Colors.grey, 'text': 'Tobacco', 'detail': 'Use raises blood pressure temporarily, damages vessels.'},
    {'icon': Icons.bolt, 'color': Colors.lightBlue, 'text': 'Salt Intake', 'detail': 'High sodium levels can increase blood pressure.'},
    {'icon': Icons.park, 'color': Colors.green, 'text': 'Potassium Levels', 'detail': 'Important for heart health and salt balance.'},
    {'icon': Icons.local_drink, 'color': Colors.brown, 'text': 'Alcohol', 'detail': 'Excessive drinking is linked with higher pressure.'},
    {'icon': Icons.stream, 'color': Colors.purple, 'text': 'Stress', 'detail': 'Can lead to a temporary increase in blood pressure.'},
    {'icon': Icons.health_and_safety, 'color': Colors.orange, 'text': 'Chronic Conditions', 'detail': 'Conditions like kidney disease and diabetes.'},
    {'icon': Icons.pregnant_woman, 'color': Colors.pink, 'text': 'Pregnancy', 'detail': 'Can cause high blood pressure in some cases.'},
  ];

  return factors.map((factor) {
    return ListTile(
      leading: Icon(factor['icon'], color: factor['color'], size: 26),  // Larger icons with vibrant colors
      title: Text(factor['text'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(factor['detail'], style: TextStyle(fontSize: 14, color: Colors.grey[800])),
      contentPadding: EdgeInsets.symmetric(horizontal: 16),
    );
  }).toList();
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
            onPressed: () => launchUrl(Uri.parse('https://www.mayoclinic.org/diseases-conditions/high-blood-pressure/symptoms-causes/syc-20373410')),
            child: const Text(
              'Mayo Clinic',
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

// Updated buildChart method that takes specific date data
Widget buildChartForDate(List<ChartData> dataForSpecificDate) {
  return SfCartesianChart(
    primaryXAxis: DateTimeAxis(
      dateFormat: DateFormat('h:mm a'),
      intervalType: DateTimeIntervalType.hours, // Ensures hours are marked if data points are sparse
      edgeLabelPlacement: EdgeLabelPlacement.shift,
      majorGridLines: const MajorGridLines(width: 0),
    ),
    primaryYAxis: const NumericAxis(
        autoScrollingMode: AutoScrollingMode.start,
        axisLine: AxisLine(width: 0),
        majorTickLines: MajorTickLines(size: 0)
    ),
    series: <LineSeries<ChartData, DateTime>>[
      LineSeries<ChartData, DateTime>(
          dataSource: dataForSpecificDate,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.systolic,
          name: 'Systolic',
          dataLabelSettings: const DataLabelSettings(isVisible: true)
      ),
      LineSeries<ChartData, DateTime>(
          dataSource: dataForSpecificDate,
          xValueMapper: (ChartData data, _) => data.date,
          yValueMapper: (ChartData data, _) => data.diastolic,
          name: 'Diastolic',
          dataLabelSettings: const DataLabelSettings(isVisible: true)
      ),
    ],
    tooltipBehavior: TooltipBehavior(enable: true),
    trackballBehavior: TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipSettings: InteractiveTooltip(enable: true, format: 'point.x : point.y'),
    ),
    zoomPanBehavior: ZoomPanBehavior(
      enablePinching: true,
      zoomMode: ZoomMode.x,
      enablePanning: true,
    ),
    crosshairBehavior: CrosshairBehavior(
      enable: true,
      lineType: CrosshairLineType.both,
      lineWidth: 1,
      activationMode: ActivationMode.longPress,
    ),
  );
}

class ChartData {
  final DateTime date;
  final double? systolic;
  final double? diastolic;

  ChartData(this.date, this.systolic, this.diastolic);
}
