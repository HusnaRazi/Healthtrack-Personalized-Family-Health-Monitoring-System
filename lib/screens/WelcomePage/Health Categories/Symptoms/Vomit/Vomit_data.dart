import 'package:flutter/material.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class VomitPage extends StatefulWidget {
  const VomitPage({super.key});

  @override
  State<VomitPage> createState() => _VomitPageState();
}

class _VomitPageState extends State<VomitPage> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.lightBlue[100],
      child: ExpansionTile(
        leading: Icon(LineAwesomeIcons.heartbeat, color: Colors.red[700], size: 30,),
        title: const Text(
          "Vomiting",
          style: TextStyle(
            fontSize: 19,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: <Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: InkWell(
                onTap: () {},
                child: const Text(
                  'Details',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
        ],
      ),
    );
  }
}
