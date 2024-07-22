import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OverallHealthStatusChart extends StatefulWidget {
  const OverallHealthStatusChart({super.key});

  @override
  State<OverallHealthStatusChart> createState() => _OverallHealthStatusChartState();
}

class _OverallHealthStatusChartState extends State<OverallHealthStatusChart> {
  List<HealthData> chartData = [];

  Future<void> fetchHealthData() async {
    await fetchHeartRateData();
    await fetchBloodOxygenData();
    await fetchBloodGlucoseData();
  }

  Future<void> fetchHeartRateData() async {
    var collection = FirebaseFirestore.instance.collection('Heart Rate');
    var querySnapshot = await collection.orderBy('timestamp', descending: true).limit(1).get();
    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      setState(() {
        chartData.add(HealthData('Heart Rate', double.parse(data['bpm'].toString()), 60, 100));
      });
    }
  }

  Future<void> fetchBloodOxygenData() async {
    var collection = FirebaseFirestore.instance.collection('Blood Oxygen');
    var querySnapshot = await collection.orderBy('timestamp', descending: true).limit(1).get();
    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      setState(() {
        chartData.add(HealthData('Blood Oxygen', double.parse(data['saturation'].toString()), 90, 100));
      });
    }
  }

  Future<void> fetchBloodGlucoseData() async {
    var collection = FirebaseFirestore.instance.collection('Blood Glucose');
    var querySnapshot = await collection.orderBy('timestamp', descending: true).limit(1).get();
    for (var doc in querySnapshot.docs) {
      var data = doc.data();
      setState(() {
        chartData.add(HealthData('Blood Glucose', double.parse(data['glucose'].toString()), 70, 140));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchHealthData();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Overall Health Status",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
              SizedBox(height: 20),
              Container(
                height: 300,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  legend: Legend(isVisible: true, position: LegendPosition.bottom),
                  tooltipBehavior: TooltipBehavior(enable: true),  // Enable tooltips
                  zoomPanBehavior: ZoomPanBehavior(
                    enablePinching: true,
                    enablePanning: true,
                    zoomMode: ZoomMode.x,
                  ),  // Enable zooming and panning
                  series: <CartesianSeries>[
                    ColumnSeries<HealthData, String>(
                      dataSource: chartData,
                      xValueMapper: (HealthData data, _) => data.metric,
                      yValueMapper: (HealthData data, _) => data.actual,
                      name: 'Actual',
                      color: Colors.deepPurple,
                      dataLabelSettings: DataLabelSettings(isVisible: true),  // Show data labels
                      enableTooltip: true,
                    ),
                    RangeColumnSeries<HealthData, String>(
                      dataSource: chartData,
                      xValueMapper: (HealthData data, _) => data.metric,
                      lowValueMapper: (HealthData data, _) => data.min,
                      highValueMapper: (HealthData data, _) => data.max,
                      name: 'Normal Range',
                      color: Colors.grey.withOpacity(0.3),
                      enableTooltip: true,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }
}

class HealthData {
  final String metric;
  final double actual;
  final double min;
  final double max;

  HealthData(this.metric, this.actual, this.min, this.max);
}
