import 'package:flutter/material.dart';

class BloodPressureLevel extends StatelessWidget {
  const BloodPressureLevel({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          children: [
            Image.asset(
              'images/speedometer.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 10), // Space between the icon and text
            const Text(
              'Categories or Level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Table(
              border: TableBorder.all(color: Colors.grey[300]!),
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
              },
              children: [
                _buildTableRow('Categories', 'Systolic (mm Hg)', 'Diastolic (mm Hg)', isHeader: true),
                _buildTableRow('Low', '0-90', '0-60', bgColor: Colors.blue[100]),
                _buildTableRow('Normal', '90-120', '60-80', bgColor: Colors.green[100]),
                _buildTableRow('Elevated', '120-129', '60-80', bgColor: Colors.yellow[100]),
                _buildTableRow('Hypertension Stage 1', '130-139', '80-89', bgColor: Colors.orange[100]),
                _buildTableRow('Hypertension Stage 2', '140-180', '90-120', bgColor: Colors.red[100]),
                _buildTableRow('Hypertension Crisis', '180 or higher', '120 or higher', bgColor: Colors.red[300]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String systolic, String diastolic, {bool isHeader = false, Color? bgColor}) {
    final headerStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );
    final cellStyle = TextStyle(
      fontSize: 16,
      color: Colors.black87,
    );

    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? Colors.deepOrange : bgColor,
      ),
      children: [
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(label, style: isHeader ? headerStyle : cellStyle),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(systolic, style: isHeader ? headerStyle : cellStyle),
          ),
        ),
        TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(diastolic, style: isHeader ? headerStyle : cellStyle),
          ),
        ),
      ],
    );
  }
}
