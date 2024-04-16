import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class GraphFile extends StatefulWidget {
  const GraphFile({Key? key}) : super(key: key);

  @override
  State<GraphFile> createState() => _GraphFileState();
}

class _GraphFileState extends State<GraphFile> {
  late List<GDPData> _chartData;
  late TooltipBehavior _tooltipBehavior = TooltipBehavior(enable: true);
  String? selectedFilter = 'Hospital';
  String? selectedHospital;
  String? selectedDoctor;
 String? selectedDateTreatment;

 final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _chartData = [];
    _tooltipBehavior = TooltipBehavior(enable: true);
    fetchChartData();
  }

  void fetchChartData() async {
    Query query = FirebaseFirestore.instance.collection('uploads').where('uid', isEqualTo: user?.uid);

    // Apply filters based on user selection
    if (selectedFilter == 'Hospital' && selectedHospital != null) {
      query = query.where('hospital', isEqualTo: selectedHospital);
    } else if (selectedFilter == 'Doctor' && selectedDoctor != null) {
      query = query.where('doctor', isEqualTo: selectedDoctor);
    } else if (selectedFilter == 'Date Treatment' && selectedDateTreatment != null) {
      query = query.where('Date Treatment', isEqualTo: selectedDateTreatment); // Direct string comparison
    }

    query.snapshots().listen((snapshot) {
      Map<String, int> countMap = {};
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String key;
        switch (selectedFilter) {
          case 'Hospital':
            key = data['hospital'] ?? 'Unknown';
            break;
          case 'Doctor':
            key = data['doctor'] ?? 'Unknown';
            break;
          case 'Date Treatment':
            key = data['Date Treatment'] ?? 'Unknown'; // Use directly
            break;
          default:
            key = 'Unknown';
        }
        countMap[key] = (countMap[key] ?? 0) + 1;
      }

      setState(() {
        _chartData = countMap.entries.map((e) => GDPData(e.key, e.value)).toList();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    int totalFilesUploaded = _chartData.fold(0, (sum, item) => sum + item.gdp);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Text(
                    "Choose A Category: ",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 80),
                DropdownButton<String>(
                  value: selectedFilter,
                  underline: Container(), // Removes the underline of the dropdown
                  items: <String>['Hospital', 'Doctor', 'Date Treatment'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedFilter = value;
                      fetchChartData();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: MediaQuery.of(context).size.height * 0.43,
              width: MediaQuery.of(context).size.width * 0.89,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: _chartData.isNotEmpty ? SfCircularChart(
                title: ChartTitle(
                    text: 'Medical Report Based on ${selectedFilter ?? "Selection"}'),
                legend: const Legend(
                  isVisible: true,
                  overflowMode: LegendItemOverflowMode.wrap,
                  position: LegendPosition.bottom,
                ),
                tooltipBehavior: _tooltipBehavior,
                series: <CircularSeries>[
                  DoughnutSeries<GDPData, String>(
                    explode: true,
                    dataSource: _chartData,
                    xValueMapper: (GDPData data, _) => data.continent,
                    yValueMapper: (GDPData data, _) => data.gdp,
                    dataLabelSettings: const DataLabelSettings(
                      isVisible: true,
                    ),
                    enableTooltip: true,
                  ),
                ],

              annotations: <CircularChartAnnotation>[
                CircularChartAnnotation(
                  widget: Container(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                      '$totalFilesUploaded',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
                      ),
                      const Text("Total",
                        style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                ),
              ],
              ): const Text('No data available'),
            ),
          ],
        ),
      ),
    );
  }
}

class GDPData {
  final String continent;
  final int gdp;

  const GDPData(this.continent, this.gdp);
}
