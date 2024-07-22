import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Fever/FeverAllData.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class FeverDetails extends StatefulWidget {
  const FeverDetails({super.key});

  @override
  State<FeverDetails> createState() => _FeverDetailsState();
}

class _FeverDetailsState extends State<FeverDetails> {
  late ScrollController _scrollController;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
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

  Stream<List<FeverData>> getFeverDataStream() {
    // Set start of the day (midnight)
    DateTime startOfDay = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day);
    // Set end of the day (just before midnight of the next day)
    DateTime endOfDay = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);

    return FirebaseFirestore.instance.collection('Fever')
        .where(
        'dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('dateTime', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return FeverData.fromFirestore(data);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fever Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlue[100],
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.list_sharp),
            onPressed: () { // Correct method is onPressed, not onTap
              Navigator.push(
                context,
                MaterialPageRoute(builder: (
                    context) => const FeverAllData()), // Assuming CoughDetails is the correct destination widget
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
              onPressed: () => showFeverDetails(context),
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            buildDateSelector(),
            const SizedBox(height: 10),
            Container(
              height: 300,
              child: buildGraphCard(),
            ),
            const SizedBox(height: 10),
            buildDefinitionFever(),
            const SizedBox(height: 10),
            buildSymptomsOfFever(),
            const SizedBox(height: 15),
            buildCausesOfFever(),
            const SizedBox(height: 5),
            buildTemperatureTakingMethods(),
            const SizedBox(height: 5),
            buildEmergencyFever(),
            const SizedBox(height: 10),
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

  Widget buildGraphCard() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      child: Container(
        height: 400,
        padding: const EdgeInsets.all(8),
        child: StreamBuilder<List<FeverData>>(
          stream: getFeverDataStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            } else if (snapshot.hasData) {
              return SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  edgeLabelPlacement: EdgeLabelPlacement.shift,
                  dateFormat: DateFormat('hh:mm a'),
                  intervalType: DateTimeIntervalType.auto,
                  majorTickLines: MajorTickLines(size: 0),
                  axisLine: AxisLine(width: 2),
                  labelStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                primaryYAxis: const NumericAxis(
                  labelFormat: '{value}°C',
                  axisLine: AxisLine(width: 2),
                  majorTickLines: MajorTickLines(size: 2),
                  labelStyle: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  rangePadding: ChartRangePadding.none,
                  minimum: 32,
                  // Start range at 32
                  maximum: 42,
                  // End range at 42
                  interval: 2, // Set an interval to control the frequency of labels
                ),
                series: <LineSeries<FeverData, DateTime>>[
                  LineSeries<FeverData, DateTime>(
                    dataSource: snapshot.data!,
                    xValueMapper: (FeverData data, _) => data.dateTime,
                    yValueMapper: (FeverData data, _) => data.temperature,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                    enableTooltip: true,
                    markerSettings: MarkerSettings(isVisible: true),
                    width: 2,
                    color: Colors.redAccent,
                  )
                ],
                tooltipBehavior: TooltipBehavior(enable: true),
              );
            } else {
              return const Text('No data available');
            }
          },
        ),
      ),
    );
  }

  Widget buildDefinitionFever() {
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
                'A fever indicates a body temperature that is higher than normal. It is not an illness itself but a symptom often linked to infections, certain medications, or vaccines.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 16, color: Colors.indigo[800]),
              ),
              SizedBox(height: 8),
              Text(
                'Normal body temperature is typically about 98.6°F (37°C), but it can vary throughout the day. It tends to be lower in the morning and higher in the evening, and can also increase with exercise or during menstruation.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 16, color: Colors.indigo[800]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSymptomsOfFever() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.symmetric(horizontal: 12),
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/type symptom.png'),
        ),
        title: Text(
          'Symptoms of Fever',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildFeverSymptomDetail(
              'Common Symptoms',
              'Fever can often be accompanied by sweating, chills, shivering, headaches, muscle aches, a lack of appetite, irritability, dehydration, and general weakness.'
          ),
          buildFeverSymptomDetail(
              'Temperature Ranges',
              'While normal body temperature is about 98.6°F (37°C), temperatures of 100°F (37.8°C) or higher when measured orally are generally considered fevers.'
          ),
        ],
      ),
    );
  }

  Widget buildFeverSymptomDetail(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 30, color: Colors.blueGrey)),
          // Bullet point as a text
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

  Widget buildTemperatureTakingMethods() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.symmetric(horizontal: 12),
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/Test Option.png'),
        ),
        title: const Text(
          'Test Option',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildTemperatureMethodDetail(
              'Oral Thermometer',
              'Placed in the mouth, oral thermometers are highly accurate for measuring core body temperature.'
          ),
          buildTemperatureMethodDetail(
              'Rectal Thermometer',
              'Inserted into the rectum, this method is considered very accurate, especially suitable for infants.'
          ),
          buildTemperatureMethodDetail(
              'Ear (Tympanic) Thermometer',
              'Measure temperature from the eardrum and might be less accurate than oral or rectal methods.'
          ),
          buildTemperatureMethodDetail(
              'Forehead (Temporal Artery) Thermometer',
              'Swiping across the forehead, but may provide less precise measurements compared to core body methods.'
          ),
          buildTemperatureMethodDetail(
              'Reporting Tips',
              'Always report both the reading and the type of thermometer used to your healthcare provider for accurate assessment.'
          ),
        ],
      ),
    );
  }

  Widget buildTemperatureMethodDetail(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 30, color: Colors.blueGrey)),
          // Bullet point as a text
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

  Widget buildCausesOfFever() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Theme(
        data: ThemeData(
          dividerColor: Colors.transparent, // Keeps the divider invisible
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: SizedBox(
            width: 24,
            height: 24,
            child: Image.asset('images/infection-cause.png'),
          ),
          title: const Text(
            'Causes of Fever',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          childrenPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 5),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildSection(
              icon: Icons.thermostat_auto,
              // New icon for body temperature regulation
              title: 'Body Temperature Regulation',
              description: 'Your body’s temperature is regulated by the hypothalamus, which acts like a thermostat. Normal fluctuations occur, with temperatures lower in the morning and higher in the evening.',
            ),
            buildSection(
              icon: Icons.bug_report, // New icon for causes of fever
              title: 'Factors of Fever',
              description: 'Fever can be triggered by a range of factors, including viral and bacterial infections, heat exhaustion, inflammatory conditions like rheumatoid arthritis, some cancers, certain medications, and reactions to vaccines such as DTaP or COVID.',
            ),
            buildSection(
              icon: Icons.local_hospital, // New icon for benefits of fever
              title: 'Common Fever',
              description: 'Fevers up to 104°F (40°C) may help the immune system fight infections like the flu and are typically not harmful.',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSection({required IconData icon, required String title, required String description}) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      // Icons in list tiles
      title: Text(
          title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(description),
      contentPadding: EdgeInsets.all(8),
      isThreeLine: true,
    );
  }

  Widget buildEmergencyFever() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ExpansionTile(
        initiallyExpanded: false,
        leading: Icon(Icons.emergency, color: Colors.red,),
        title: Text(
          'Emergency Guide',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        children: [
          buildFeverDetail(
              'Infants and Toddlers',
              'Click for more details',
              'Under 3 months: temp ≥ 38°C. \n\n3-6 months: temp ≥ 39°C or if irritable or sluggish. \n\n7-24 months: temp ≥ 39°C lasts more than a day or sooner with symptoms.',
              Icons.baby_changing_station),
          buildFeverDetail(
              'Children',
              'Click for more details',
              'Responsive and playful is fine. Call if: \n- irritable \n- vomiting \n- severe headache \n- discomfort. \n\nImmediate care for fever after heat exposure or seizures.',
              Icons.child_care),
          buildFeverDetail(
              'Adults',
              'Click for more details',
              'Call for fever ≥ 39°C. Immediate help for: \n- severe headache \n- rash \n- light sensitivity \n- neck stiffness \n- confusion \n- vomiting \n- breathing difficulty \n- abdominal pain \n- painful urination \n- seizures.',
              Icons.person_outline),
        ],
      ),
    );
  }

  Widget buildFeverDetail(String title, String briefDetails, String fullDetails,
      IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal, size: 40),
      title: Text(
          title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: Text(briefDetails),
      onTap: () => showDetailDialog(title, fullDetails, phoneNumber: ''),
    );
  }

  void showDetailDialog(String title, String details, {required String phoneNumber}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold)),
          content: Text(details),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.phone_in_talk, color: Colors.green),
              onPressed: () => _launchURL('tel:999'),
              tooltip: 'Call Emergency Number',
            ),
            TextButton(
              child: Text('Understood', style: TextStyle(color: Colors.blue[700])),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void showFeverDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return StreamBuilder<List<FeverData>>(
          stream: getFeverDataStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                FeverData fever = snapshot.data![index];
                return ListTile(
                  title: Text('Fever: ${fever.temperature.toStringAsFixed(1)}°C'),
                  subtitle: Text('Recorded at: ${DateFormat('hh:mm a').format(fever.dateTime)}'),
                  leading: Icon(Icons.thermostat, color: Colors.red),
                  trailing: Text('${fever.temperature >= 37.5 ? "High" : "Normal"}'),
                );
              },
            );
          },
        );
      },
    );
  }
}

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }


  class FeverData {
  final DateTime dateTime;
  final double temperature;

  FeverData({required this.dateTime, required this.temperature});

  factory FeverData.fromFirestore(Map<String, dynamic> data) {
    DateTime dateTime = (data['dateTime'] as Timestamp).toDate();
    double temperature = data['temperature'];
    return FeverData(dateTime: dateTime, temperature: temperature);
  }
}
