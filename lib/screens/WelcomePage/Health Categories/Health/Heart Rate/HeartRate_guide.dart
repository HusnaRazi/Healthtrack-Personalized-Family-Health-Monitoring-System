import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class HeartRateGuide extends StatefulWidget {
  const HeartRateGuide({super.key});

  @override
  State<HeartRateGuide> createState() => _HeartRateGuideState();
}

class _HeartRateGuideState extends State<HeartRateGuide> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4, // Adds shadow to the card for better visual separation
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: Colors.white,
      child: ExpansionTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Image.asset('images/chart.png'),
        ),
        title: const Text(
          'Heart Rate Guide',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Table(
              border: TableBorder.all(color: Colors.grey[300]!), // Lighter border color for the table
              columnWidths: const {
                0: FlexColumnWidth(1),
                1: FlexColumnWidth(3),
              },
              children: List<TableRow>.generate(11, (index) {
                if (index == 0) {
                  return TableRow( // Header row with a different style
                    decoration: BoxDecoration(
                      color: Colors.grey[200], // Background color for the header
                    ),
                    children: [
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Age',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Beats per Minute',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  return TableRow( // Data rows
                    children: [
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            '${20 + (index - 1) * 5}', // Dynamically generated age
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      TableCell(
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            '${100 - (index - 1) * 2}–${170 - (index - 1) * 2}', // Dynamically generated BPM range
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              }),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
