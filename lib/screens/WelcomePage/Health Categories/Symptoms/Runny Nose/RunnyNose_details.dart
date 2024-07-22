import 'package:flutter/material.dart';
import 'package:healthtrack/screens/WelcomePage/Health%20Categories/Symptoms/Runny%20Nose/RunnyNose_AllData.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class RunnyNoseDetails extends StatefulWidget {
  const RunnyNoseDetails({Key? key}) : super(key: key);

  @override
  _RunnyNoseDetailsState createState() => _RunnyNoseDetailsState();
}

class _RunnyNoseDetailsState extends State<RunnyNoseDetails> {
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

  Stream<List<RunnyNoseData>> getRunnyNoseDataStream() {
    return FirebaseFirestore.instance.collection('RunnyNose')
        .where('startDateTime', isGreaterThanOrEqualTo: DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day))
        .where('startDateTime', isLessThanOrEqualTo: DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 23, 59))
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) =>
            RunnyNoseData.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Color _getColorForSeverity(int severity) {
    switch (severity) {
      case 1:
        return Colors.green; // Not Present
      case 2:
        return Colors.lightGreen; // Mild
      case 3:
        return Colors.orange; // Moderate
      case 4:
        return Colors.redAccent; // Severe
      case 5:
        return Colors.red; // Very Severe
      default:
        return Colors.grey; // Default color if no severity is matched
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Runny Nose Report',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlue[100],
        actions: [
          IconButton(
            icon: const Icon(Icons.list_sharp),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => const RunnyNoseAllData())),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showRunnyNoseDetails(context),
          ),
        ],
      ),
      backgroundColor: Colors.lightBlue[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            buildDateSelector(),
            Container(height: 300, child: buildGraphCard()),
            buildDefinitionRunnyNose(),
            const SizedBox(height: 5),
            buildCausesOfRunnyNose(),
            const SizedBox(height: 5),
            buildRunnyNoseTakingMethods(),
            const SizedBox(height: 5),
            buildRunnyNoseMedications(),
            const SizedBox(height: 5),
            buildRunnyNoseEmergencySection(context),
            const SizedBox(height: 10),
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
    return StreamBuilder<List<RunnyNoseData>>(
      stream: getRunnyNoseDataStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Show loading indicator while waiting
        }

        List<RunnyNoseData> data = snapshot.hasData && snapshot.data!.isNotEmpty
            ? snapshot.data!
            : [RunnyNoseData(
          dateTime: DateTime(
              selectedDate.year, selectedDate.month, selectedDate.day, 12),
          // Midday as default time
          severity: 0, // Default severity as zero to indicate no data
        )
        ];

        return Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15)),
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
              series: <StepLineSeries<RunnyNoseData, DateTime>>[
                StepLineSeries<RunnyNoseData, DateTime>(
                  dataSource: data,
                  xValueMapper: (RunnyNoseData data, _) => data.dateTime,
                  yValueMapper: (RunnyNoseData data, _) => data.severity,
                  name: 'Severity',
                  animationDuration: 1500,
                  markerSettings: MarkerSettings(isVisible: true),
                  dataLabelSettings: DataLabelSettings(isVisible: true),
                )
              ],
              tooltipBehavior: TooltipBehavior(enable: true),
              zoomPanBehavior: ZoomPanBehavior(
                enablePanning: true, // Allows panning
                enablePinching: true, // Allows pinch zooming
                zoomMode: ZoomMode.x, // Only x-axis is zoomable
              ),
            ),
          ),
        );
      },
    );
  }

  void showRunnyNoseDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return StreamBuilder<List<RunnyNoseData>>(
          stream: getRunnyNoseDataStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                RunnyNoseData runnyNose = snapshot.data![index];
                // Adjusted to use severityDescription and a method to determine the textual classification
                return ListTile(
                  title: Text('Runny Nose'),
                  subtitle: Text('Recorded at: ${DateFormat('hh:mm a').format(
                      runnyNose.dateTime)}'),
                  leading: Icon(Icons.water_drop,
                      color: _getColorForSeverity(runnyNose.severity)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                          'Severity: ${runnyNose.severity} - ${classifySeverity(
                              runnyNose.severity)}'),
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

// Helper method to classify severity for additional description
  String classifySeverity(int severity) {
    if (severity >= 4) {
      return "Very Severe"; // Severe or Very Severe
    } else if (severity >= 3) {
      return "Severe";
    } else if (severity >= 2) {
      return "Moderate";
    } else if (severity >= 1) {
      return "Mild";
    } else {
      return "Normal"; // Not Present
    }
  }

  Widget buildDefinitionRunnyNose() {
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
                'Involves fluid leaking from the nose, which can be thin and clear or thick and yellow-green. The fluid may also drip down the back of the throat, a condition called postnasal drip.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 16, color: Colors.indigo[800]),
              ),
              SizedBox(height: 8),
              Text(
                'Rhinorrhea refers to the discharge of thin, clear fluid, while rhinitis refers to irritation and swelling inside the nose, which is a common cause of a runny nose. A runny nose can often be accompanied by nasal congestion.',
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 16, color: Colors.indigo[800]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildCausesOfRunnyNose() {
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
            'Causes of Runny Nose',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildSection(
              icon: Icons.looks_one_outlined,
              // New icon for body temperature regulation
              title: 'Allergies (Allergic Rhinitis)',
              description: 'Common allergens like pollen, pet dander, and dust can trigger allergic reactions, where the immune system releases histamine, causing inflammation and a watery nasal discharge.',
            ),
            buildSection(
              icon: Icons.looks_two_outlined, // New icon for causes of fever
              title: 'Viral Infections',
              description: 'Fever can be triggered by a range of factors, including viral and bacterial infections, heat exhaustion, inflammatory conditions like rheumatoid arthritis, some cancers, certain medications, and reactions to vaccines such as DTaP or COVID.',
            ),
            buildSection(
              icon: Icons.three_k_outlined, // New icon for benefits of fever
              title: 'Environmental and Other Triggers',
              description: '- Cold Temperatures: Cold air can dry and irritate the nasal lining, causing excess mucus production.'
                  '\n\n- Tears (Lacrimation): Excess tears can drain into the nasal cavities, causing a runny nose.'
                  '\n\n- Sinus Infections (Sinusitis): Can cause blocked sinuses, pressure, pain, and a runny nose with thick mucus.'
                  '\n\n- Nasal Polyps: Benign growths in the nasal passages that can obstruct airflow and cause a runny nose.'
                  '\n\n- Foreign Bodies: Objects stuck in the nose can trigger mucus production.'
                  '\n\n- Nonallergic Rhinitis: Triggered by irritants like smoke and strong odors, causing chronic nasal symptoms without an allergic cause.'
                  '\n\n- Gustatory Rhinitis: Triggered by eating spicy or warm foods, causing a runny nose.'
                  '\n\n- Pregnancy Rhinitis: Hormonal changes and increased blood flow during pregnancy can lead to a runny nose.'
                  '\n\n- Medication Side Effects: Certain drugs, including birth control and antidepressants, can cause a runny nose as a side effect.'
                  '\n\n- CSF Leak: Leakage of cerebrospinal fluid can present as clear, watery discharge from one nostril.'
                  '\n\n- Opioid Withdrawal: Stopping opioid use can lead to symptoms including a runny nose and watery eyes.',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSection(
      {required IconData icon, required String title, required String description}) {
    return ListTile(
      leading: Icon(icon, color: Colors.purple),
      // Icons in list tiles
      title: Text(
          title, style: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
      subtitle: Text(description),
      contentPadding: EdgeInsets.all(8),
      isThreeLine: true,
    );
  }

  Widget buildRunnyNoseTakingMethods() {
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
          'Treatment Options',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        childrenPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          buildRunnyNoseMethodDetail(
            'Sinus Infections',
            'If symptoms persist beyond 10 days, treatment might include antibiotics, decongestants, or nasal steroid sprays.',
          ),
          buildRunnyNoseMethodDetail(
              'Chronic Rhinitis',
              'For long-term issues, a specialist might be consulted to explore underlying causes, potentially leading to surgery for issues like nasal polyps or a deviated septum.'
          ),
          buildRunnyNoseMethodDetail(
              'Nasal Foreign Bodies',
              'Objects lodged in the nose need to be professionally removed using techniques like tweezers, forced exhalation, or suction.'
          ),
        ],
      ),
    );
  }

  Widget buildRunnyNoseMethodDetail(String title, String description) {
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

  Widget buildRunnyNoseTreatment() {
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
            child: Image.asset('images/treatment.png'),
          ),
          title: const Text(
            'Treatments for Runny Nose',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            buildSection(
              icon: Icons.healing_outlined,
              title: 'At-Home Remedies',
              description: 'Rest, drink fluids, apply a warm washcloth, inhale steam, use a humidifier, and saline nasal sprays.',
            ),
            buildSection(
              icon: Icons.local_pharmacy_outlined,
              title: 'Medications',
              description: 'Expectorants to thin mucus, decongestants to reduce mucus, and antihistamines for allergies.',
            ),
            buildSection(
              icon: Icons.medical_services_outlined,
              title: 'Medical Intervention',
              description: 'Seek professional help for sinus infections, chronic rhinitis, or objects stuck in the nose. Treatment might include antibiotics, nasal steroids, or surgery for structural issues.',
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRunnyNoseMedications() {
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
            child: Image.asset('images/medicine.png'),
          ),
          title: const Text(
            'Medications',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          childrenPadding: const EdgeInsets.all(16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildMedicationRow(
              Icons.air_outlined,
              'Expectorants',
              'These medications can thin mucus to help clear it from your chest. It may help a runny nose, too.',
            ),
            _buildMedicationRow(
              Icons.remove_circle_outline,
              'Decongestants',
              'These medications shrink and dry up your nasal passages. They may help dry up a runny or stuffy nose.',
            ),
            _buildMedicationRow(
              Icons.all_inclusive,
              'Antihistamines',
              'These medications can help if your runny nose is due to allergies.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationRow(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blueGrey[700],
                  ),
                ),
                const SizedBox(height: 4), // Spacer
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRunnyNoseEmergencySection(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRunnyNoseEmergencyDialog(context),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                'Runny Nose Symptoms',
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

  void _showRunnyNoseEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'When to See a Healthcare Provider',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('• Your runny nose or congestion lasts more than three weeks or is accompanied by a fever.'),
                Text('• The discharge is coming from one nostril, especially if it’s foul-smelling or bloody.'),
                Text('• You have difficulty breathing.'),
                Text('• You have swelling in your forehead, eyes, side of your nose, or cheek.'),
                Text('• You have blurred vision.'),
                Text('• You have nasal discharge following a head injury, especially if it’s clear and watery.'),
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

}

class RunnyNoseData {
  final DateTime dateTime;
  final int severity;

  RunnyNoseData({required this.dateTime, required this.severity});

  factory RunnyNoseData.fromFirestore(Map<String, dynamic> data) {
    return RunnyNoseData(
      dateTime: (data['startDateTime'] as Timestamp).toDate(),
      severity: _mapSeverityToNumber(data['severity'].toString()),
    );
  }

  static int _mapSeverityToNumber(String severity) {
    switch (severity) {
      case 'Not Present': return 1;
      case 'Mild': return 2;
      case 'Moderate': return 3;
      case 'Severe': return 4;
      case 'Very Severe': return 5;
      default: return 0;  // Handle default case safely
    }
  }
}
