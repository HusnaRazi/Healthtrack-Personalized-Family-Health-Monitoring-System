import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Health/Blood%20Oxygen/BloodOxygen_AllData.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:url_launcher/url_launcher.dart';

class BloodOxygenDetails extends StatefulWidget {
  const BloodOxygenDetails({Key? key}) : super(key: key);

  @override
  State<BloodOxygenDetails> createState() => _BloodOxygenDetailsState();
}

class _BloodOxygenDetailsState extends State<BloodOxygenDetails> {
  List<_ChartData> chartData = [];
  String latestUpdate = "Loading latest update...";
  late StreamSubscription<QuerySnapshot> subscription;
  double latestOxygenProgress = 0;
  int latestOxygen = 0;

  @override
  void initState() {
    super.initState();
    subscription = FirebaseFirestore.instance
        .collection('Blood Oxygen')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final newData = snapshot.docs.map((doc) {
          final Timestamp timestamp = doc['timestamp'];
          final DateTime dateTime = timestamp.toDate().toLocal(); // Convert to local time
          return _ChartData(dateTime, doc['saturation']);
        }).toList();

        final latestDoc = snapshot.docs.first;
        final Timestamp latestTimestamp = latestDoc['timestamp'];
        final DateTime utcDateTime = latestTimestamp.toDate().toLocal(); // Convert to local time
        final latestOxygenValue = latestDoc['saturation'];

        String formattedDateTime = DateFormat('dd/MM/yyyy hh:mm a').format(utcDateTime);

        setState(() {
          latestUpdate = "Latest Data: $latestOxygenValue% at $formattedDateTime";
          latestOxygen = latestOxygenValue;
          latestOxygenProgress = latestOxygenValue / 100.0;
          chartData = newData;
        });
      }
    }, onError: (e) {
      setState(() {
        latestUpdate = "Failed to load data: ${e.toString()}";
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }

  Future<List<_ChartData>> fetchDataForDate(DateTime date) async {
    print("Fetching data for date: $date");
    DateTime startDate = DateTime(date.year, date.month, date.day);
    DateTime endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
    print("Start date: $startDate, End date: $endDate");

    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('Blood Oxygen')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('timestamp')
          .get();

      var data = snapshot.docs.map((doc) {
        Timestamp timestamp = doc['timestamp'];
        DateTime dateTime = timestamp.toDate().toLocal();
        return _ChartData(dateTime, doc['saturation']);
      }).toList();

      print("Data fetched successfully, count: ${data.length}");
      return data;
    } catch (e) {
      print("Error fetching data: $e");
      return [];
    }
  }

  String getOxygenStatus() {
    if (latestOxygen < 90) {
      return "Low Oxygen";
    } else if (latestOxygen >= 98 && latestOxygen <= 100) {
      return "Normal Oxygen";
    } else if (latestOxygen >= 95 && latestOxygen <= 97) {
      return "Tolerable Oxygen";
    } else if (latestOxygen >= 90 && latestOxygen <= 94) {
      return "Decreased";
    } else if (latestOxygen < 80) {
      return "Severe Hypoxia";
    } else if (latestOxygen < 70) {
      return "Danger";
    } else {
      return "Invalid Value";
    }
  }

  Color? getStatusColor() {
    if (latestOxygen < 70) {
      return Colors.red[800]; // Deep red for critical danger
    } else if (latestOxygen < 80) {
      return Colors.red; // Bright red for severe hypoxia
    } else if (latestOxygen <= 94) {
      return Colors.orange; // Orange for decreased oxygen
    } else if (latestOxygen <= 97) {
      return Colors.yellow[800]; // Yellow for tolerable oxygen
    } else if (latestOxygen <= 100) {
      return Colors.green; // Green for normal oxygen levels
    } else {
      return Colors.grey; // Grey for invalid values
    }
  }

  void _showOxygenCalendarPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
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
      List<_ChartData> dataForDate = await fetchDataForDate(picked);
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
                    style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    height: 300,
                    child: buildChart(dataForDate),
                  ),
                  const SizedBox(height: 20.0),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close', style: TextStyle(fontSize: 16.0, color: Colors.blue)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }catch (e) {
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

  Widget buildChart(List<_ChartData> data) {
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
          yValueMapper: (_ChartData data, _) => data.value,
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
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[100],
        title: const Text('Blood Oxygen Report'),
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
          fontSize: 20,
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_calendar_sharp),
            onPressed: () {
              _showOxygenCalendarPicker();
            },
          ),
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BloodOxygenAllData()),
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
                    getOxygenStatus(),
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
                          width: 130 * latestOxygenProgress,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                getStatusColor()?.withOpacity(0.5) ?? Colors.transparent,
                                getStatusColor() ?? Colors.transparent,
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
            const SizedBox(height: 20),
            _buildAboutCard(),
            const SizedBox(height: 20),
            _buildBloodOxygenTest(),
            const SizedBox(height: 20),
            _buildWhyTestBloodOxygen(),
            const SizedBox(height: 20),
            _buildOxygenStatusCard(),
            const SizedBox(height: 20),
            _buildOxygenSymptomsCard(),
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
        autoScrollingMode: AutoScrollingMode.start,
        axisLine: AxisLine(width: 0),
        majorTickLines: MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(width: 0.5),
      ),
      series: <CartesianSeries<_ChartData, DateTime>>[
        LineSeries<_ChartData, DateTime>(
          dataSource: chartData,
          xValueMapper: (_ChartData data, _) => data.time,
          yValueMapper: (_ChartData data, _) => data.value,
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
      tooltipBehavior: TooltipBehavior(enable: true),
    );
  }

  Widget _buildAboutCard() {
    return const Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'About Blood Oxygen',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Refers to the amount of oxygen circulating in your blood. Oxygen enters body when you breathe in through nose or mouth, travels through lungs, and then reaches your blood.'
              ' From there, oxygen is delivered to cells throughout body to produce energy for various functions like digestion and cognition.'
              ' After cells use oxygen, they produce carbon dioxide, which is removed from body when you exhale.'
              ' Maintaining proper blood oxygen levels is crucial as low levels can lead to serious health issues, particularly affecting brain and heart.',
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
}

Widget _buildBloodOxygenTest() {
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
        child: Image.asset('images/oxygen.png'),
      ),
      title: const Text(
        'Blood Oxygen Test',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: const <Widget>[
        ListTile(
          title: Text(
            'Arterial Blood Gas (ABG) Test',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Measures oxygen and carbon dioxide levels, and checks pH balance in your blood. It is a comprehensive test indicating respiratory health.',
          ),
          leading: Icon(Icons.bloodtype, color: Colors.red),
        ),
        ListTile(
          title: Text(
            'Pulse Oximetry',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Uses a small clip on the finger or toe to measure SpO2 levels and heart rate. A quick, non-invasive method to check oxygen saturation.',
          ),
          leading: Icon(Icons.favorite, color: Colors.red),
        ),
      ],
    ),
  );
}

Widget _buildWhyTestBloodOxygen() {
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
      child: Image.asset('images/assessment.png'),
     ),
      title: const Text(
        'Why Test Blood Oxygen?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: const <Widget>[
        ListTile(
          title: Text(
            'Acute Conditions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          subtitle: Text(
            'Trouble breathing, head or neck injuries, COVID-19, pneumonia, carbon monoxide poisoning, smoke inhalation, nausea/vomiting episodes, drug overdose.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          title: Text(
            'Chronic Lung Conditions',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          subtitle: Text(
            'Monitoring and ensuring effective treatment for asthma, COPD, cystic fibrosis, and heart disease.',
            textAlign: TextAlign.justify,
            style: TextStyle(
            fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListTile(
          title: Text(
            'Oxygen Therapy Monitoring',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          subtitle: Text(
            'Regular monitoring in hospital settings to adjust oxygen therapy accurately.',
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildOxygenStatusCard() {
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
      child: Image.asset('images/speedometer.png'),
      ),
      title: const Text(
        'Blood Oxygen Levels',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: <Widget>[
        const ListTile(
          title: Text('Normal Oxygen'),
          subtitle: Text('Oxygen saturation between 98% and 100%. Considered an ideal and healthy range.'),
          leading: Icon(Icons.check_circle_outline, color: Colors.green),
        ),
        const ListTile(
          title: Text('Tolerable Oxygen'),
          subtitle: Text('Oxygen saturation between 95% and 97%. Acceptable but close monitoring is advised.'),
          leading: Icon(Icons.error_outline, color: Colors.amber),
        ),
        const ListTile(
          title: Text('Decreased'),
          subtitle: Text('Oxygen saturation between 90% and 94%. Indicates potential respiratory compromise.'),
          leading: Icon(Icons.warning, color: Colors.orange),
        ),
        const ListTile(
          title: Text('Low Oxygen'),
          subtitle: Text('Oxygen saturation below 90%. Requires immediate medical attention.'),
          leading: Icon(Icons.dangerous, color: Colors.red),
        ),
        ListTile(
          title: const Text('Severe Hypoxia'),
          subtitle: const Text('Oxygen saturation below 80%. Severe lack of oxygen, urgent intervention needed.'),
          leading: Icon(Icons.dangerous, color: Colors.red[900]),
        ),
        const ListTile(
          title: Text('Danger'),
          subtitle: Text('Oxygen saturation below 70%. Extremely critical condition, life-threatening.'),
          leading: Icon(Icons.dangerous, color: Colors.black),
        ),
      ],
    ),
  );
}

Widget _buildOxygenSymptomsCard() {
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
        child: Image.asset('images/symptom.png'), // Replace with a suitable image asset
      ),
      title: const Text(
        'Symptoms Low Oxygen',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      children: const <Widget>[
        ListTile(
          leading: Text('•', style: TextStyle(fontSize: 24)),
          title: Text('Headache'),
        ),
        ListTile(
          leading: Text('•', style: TextStyle(fontSize: 24)),
          title: Text('Shortness of Breath'),
        ),
        ListTile(
          leading: Text('•', style: TextStyle(fontSize: 24)),
          title: Text('Fast Heartbeat'),
        ),
        ListTile(
          leading: Text('•', style: TextStyle(fontSize: 24)),
          title: Text('Coughing'),
        ),
        ListTile(
          leading: Text('•', style: TextStyle(fontSize: 24)),
          title: Text('Wheezing'),
        ),
        ListTile(
          leading: Text('•', style: TextStyle(fontSize: 24)),
          title: Text('Confusion'),
        ),
        ListTile(
          leading: Text('•', style: TextStyle(fontSize: 24)),
          title: Text('Bluish Color in Skin, Fingernails, or Lips'),
        ),
        ListTile(
          leading: Text('•', style: TextStyle(fontSize: 24)),
          title: Text('Cherry Red Color in Skin, Fingernails, or Lips (sign of carbon monoxide poisoning)'),
        ),
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
                launchUrl('https://my.clevelandclinic.org/' as Uri);
              },
              child: const Text(
                'Cleveland Clinic',
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
                launchUrl('https://www.mayoclinic.org/' as Uri);
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
          ],
        ),
      ),
    ),
  );
}

class _ChartData {
  final DateTime time;
  final int value;

  _ChartData(this.time, this.value);
}
