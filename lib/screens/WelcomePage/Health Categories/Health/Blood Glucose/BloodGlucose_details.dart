import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Blood%20Glucose/BloodGlucose_AllData.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:url_launcher/url_launcher.dart';

class BloodGlucoseDetails extends StatefulWidget {
  const BloodGlucoseDetails({Key? key}) : super(key: key);

  @override
  State<BloodGlucoseDetails> createState() => _BloodGlucoseDetailsState();
}

class _BloodGlucoseDetailsState extends State<BloodGlucoseDetails> {
  List<_ChartData> chartData = [];
  String latestUpdate = "Loading latest update...";
  late StreamSubscription<QuerySnapshot> subscription;
  double latestGlucoseLevel = 0;
  int latestGlucose = 0;

  @override
  void initState() {
    super.initState();
    subscription = FirebaseFirestore.instance
        .collection('Blood Glucose')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      final newData = snapshot.docs.map((doc) {
        final Timestamp timestamp = doc['timestamp'];
        final DateTime dateTime = timestamp.toDate();  // Converts to local system time
        return _ChartData(dateTime, doc['glucose']);
      }).toList();

      if (snapshot.docs.isNotEmpty) {
        final latestDoc = snapshot.docs.first;
        final Timestamp latestTimestamp = latestDoc['timestamp'];
        final DateTime utcDateTime = latestTimestamp.toDate();  // Converts to local system time
        final latestGlucoseValue = latestDoc['glucose'];

        // Adjusting the date format to 12-hour format with AM/PM
        String formattedDateTime = DateFormat('dd/MM/yyyy h:mm a').format(utcDateTime);

        latestUpdate = "Latest Data: $latestGlucoseValue mg/dL at $formattedDateTime";

        latestGlucose = latestGlucoseValue;
        latestGlucoseLevel = latestGlucoseValue / 180; // Assuming 180 mg/dL as a reference max
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

  String getGlucoseStatus() {
    if (latestGlucose < 70) {
      return "Low";
    } else if (latestGlucose >= 70 && latestGlucose <= 140) {
      return "Normal";
    } else {
      return "High";
    }
  }

  Color getStatusColor() {
    if (latestGlucose > 140) {
      return Colors.red; // High
    } else if (latestGlucose >= 70 && latestGlucose <= 140) {
      return Colors.green; // Normal
    } else {
      return Colors.orange; // Low
    }
  }

  void _showCalendarPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSwatch(
              primarySwatch: Colors.blue,
            ),
            dialogBackgroundColor: Colors.white,
            buttonTheme: ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      // Show dialog with graph based on selected date
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0), // Add border radius
            ),
            elevation: 8.0, // Add elevation for shadow
            backgroundColor: Colors.white, // Set background color
            child: Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Graph for ${DateFormat.yMMMd().format(picked)}',
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue, // Use custom text color
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    height: 300,
                    child: _buildGraphForDate(picked), // Use the provided function to build the graph
                  ),
                  const SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.blue, // Use custom text color
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100],
        title: const Text('Blood Glucose Report'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 20,
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_calendar_sharp),
            onPressed: () => _showCalendarPicker(),
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BloodGlucoseAllData()),
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
                    getGlucoseStatus(),
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
                          width: 130 * latestGlucoseLevel,
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
            const Card(
              elevation: 5,
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
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
                      'Blood glucose or blood sugar, is the primary sugar present in the bloodstream and serves as main energy source of body. It originates from the food consume, with most of it being converted into glucose by digestion process in our body and then released into blood. When the blood glucose levels rise, it triggers the pancreas to release insulin, a hormone that facilitates the entry of glucose into cells for energy utilization.',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            _buildDiabetesInfo(),
            const SizedBox(height: 5),
            _buildTestList(),
            const SizedBox(height: 5),
            _buildSymptomsDiabetes(),
            const SizedBox(height:15),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildCredits(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiabetesInfo() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/diabetes.png'),
        ),
        title: const Text(
          'About Diabetes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Diabetes is a condition where your blood glucose levels are too high. When you have diabetes, your body either doesn\'t produce enough insulin, can\'t use it effectively, or both. This results in excess glucose remaining in your blood instead of being utilized by your cells. Over time, high blood glucose can lead to serious health issues known as diabetes complications.',
              textAlign: TextAlign.justify,
            ),
          ),
          ListTile(
            title: Text(
              'Blood Glucose Targets:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            title: Text(
              'Before a meal: 80 to 130 mg/dL',
            ),
          ),
          ListTile(
            title: Text(
              'Two hours after the start of a meal: Less than 180 mg/dL',
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTestList() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/diabetes test.png'),
        ),
        title: const Text(
          'Blood Glucose Tests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          _buildListTile(
            title: 'Capillary Blood Glucose Test',
            subtitle: 'Quick result from fingertip blood sample.',
            icon: Icons.waves,
          ),
          Divider(),
          _buildListTile(
            title: 'Venous Blood Glucose Test',
            subtitle: 'More accurate analysis from a blood sample at the lab.',
            icon: Icons.local_hospital,
          ),
          Divider(),
          _buildListTile(
            title: 'Fasting Blood Glucose Test',
            subtitle: 'Provides baseline blood sugar level without food influence.',
            icon: Icons.food_bank,
          ),
          Divider(),
          _buildListTile(
            title: 'At-Home Blood Sugar Testing',
            subtitle: 'Using a glucose meter for frequent monitoring, especially for Type 1 diabetes.',
            icon: Icons.healing,
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({required String title, required String subtitle, required IconData icon}) {
    return ListTile(
      leading: Icon(icon, color: Colors.redAccent),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[800]),
      ),
    );
  }

  Widget _buildSymptomsDiabetes(){
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ExpansionTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/result.png'),
        ),
        title: const Text(
          'Blood Glucose Symptoms',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          ListTile(
            title: const Text(
              'When would I need a blood glucose test?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                const Text(
                  '1. Your doctor orders routine blood tests.',
                ),
                const Text(
                  '2. You have symptoms of high or low blood sugar.',
                ),
                const Text(
                  '3. You take medications that affect blood sugar levels.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'A blood glucose test is commonly used to check for Type 2 diabetes, especially if you are at risk. It is also ordered if you have symptoms of high or low blood sugar.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Symptoms of diabetes and high blood sugar include:',
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSymptom('Feeling very thirsty.'),
                    _buildSymptom('Frequent urination.'),
                    _buildSymptom('Fatigue.'),
                    _buildSymptom('Feeling very hungry.'),
                    _buildSymptom('Unexplained weight loss.'),
                    _buildSymptom('Blurred vision.'),
                    _buildSymptom('Slow healing of cuts or sores.'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptom(String symptom) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.arrow_right),
        const SizedBox(width: 8),
        Expanded(child: Text(symptom)),
      ],
    );
  }

  Widget _buildCredits() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[200],
      child: Center(
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
              onPressed: () {
                launch('https://www.mayoclinic.org/');
              },
              child: const Text(
                'Mayo Clinic',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Text(
              ' and ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            TextButton(
              onPressed: () {
                launch('https://medlineplus.gov/');
              },
              child: const Text(
                'MedlinePlus',
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
        maximum: 300, // Adjusted for typical blood glucose range
        axisLine: AxisLine(width: 0),
        majorTickLines: MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(width: 0.5),
      ),
      series: <CartesianSeries<_ChartData, DateTime>>[
        LineSeries<_ChartData, DateTime>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.time,
          yValueMapper: (_ChartData data, _) => data.glucose,
          color: Colors.purpleAccent,
          width: 2,
          markerSettings: const MarkerSettings(
            isVisible: true,
            width: 4,
            height: 4,
            color: Colors.purple,
            borderColor: Colors.white,
            borderWidth: 2,
          ),
          animationDuration: 1500,
        ),
      ],
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }

  Widget _buildGraphForDate(DateTime selectedDate) {
    // Filter chart data based on the selected date
    List<_ChartData> filteredData = chartData.where((data) {
      // Extract date from data point
      DateTime dataDate = DateTime(data.time.year, data.time.month, data.time.day);
      // Compare with selected date
      return dataDate.isAtSameMomentAs(selectedDate);
    }).toList();

    // Create a LineSeries for the filtered data
    final lineSeries = LineSeries<_ChartData, DateTime>(
      dataSource: filteredData,
      xValueMapper: (_ChartData data, _) => data.time,
      yValueMapper: (_ChartData data, _) => data.glucose,
      color: Colors.purpleAccent,
      width: 2,
      markerSettings: const MarkerSettings(
        isVisible: true,
        width: 4,
        height: 4,
        color: Colors.purple,
        borderColor: Colors.white,
        borderWidth: 2,
      ),
      animationDuration: 1500,
    );

    // Wrap the LineSeries in a SfCartesianChart
    return Container(
      width: double.infinity, // Make the container take full width
      child: Card(
        margin: const EdgeInsets.all(8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            width: double.infinity, // Make the container take full width
            height: 300, // Adjust the height as needed
            child: SfCartesianChart(
              // Customize your chart here with the filtered data
              primaryXAxis: DateTimeAxis(
                edgeLabelPlacement: EdgeLabelPlacement.shift,
                dateFormat: DateFormat('h:mm a'),
                intervalType: DateTimeIntervalType.auto,
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: const NumericAxis(
                minimum: 0,
                maximum: 300, // Adjusted for typical blood glucose range
                axisLine: AxisLine(width: 0),
                majorTickLines: MajorTickLines(size: 0),
                majorGridLines: MajorGridLines(width: 0.5),
              ),
              series: [lineSeries],
              tooltipBehavior: TooltipBehavior(enable: true),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartData {
  final DateTime time;
  final int glucose;

  _ChartData(this.time, this.glucose);
}
