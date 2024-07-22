import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarMedicine extends StatefulWidget {
  @override
  _CalendarMedicineState createState() => _CalendarMedicineState();
}

class _CalendarMedicineState extends State<CalendarMedicine> {
  List<Appointment> _meetings = [];
  CalendarView _view = CalendarView.month;
  MeetingDataSource? _calendarDataSource;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Stream<QuerySnapshot> _medicineStream() {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('Medication Reminder')
          .doc(user.uid)
          .collection('Medicine')
          .snapshots();
    } else {
      return Stream.empty();
    }
  }

  void _fetchAppointments() {
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('Medication Reminder')
          .doc(user.uid)
          .collection('Medicine')
          .snapshots()
          .listen((QuerySnapshot snapshot) {
        List<Appointment> appointments = [];
        print("Documents fetched: ${snapshot.docs.length}");

        for (var doc in snapshot.docs) {
          try {
            var data = doc.data() as Map<String, dynamic>;
            DateTime startDate = (data['startDate'] as Timestamp).toDate();
            int durationDays = _parseDuration(data['duration']);
            String medicineName = data['medicineName'];
            String dosage = data['dosage'];
            List<dynamic> reminderTimes = data['reminderTimes'];

            for (int i = 0; i < durationDays; i++) {
              for (var time in reminderTimes) {
                if (time is Map<String, dynamic>) {
                  DateTime doseTime = DateTime(
                      startDate.year,
                      startDate.month,
                      startDate.day + i,
                      time['hour'],
                      time['minute']
                  );

                  appointments.add(Appointment(
                    startTime: doseTime,
                    endTime: doseTime.add(Duration(minutes: 30)),
                    subject: '$medicineName $dosage - ${durationDays - i} days left',
                    color: Colors.blue,
                  ));
                }
              }
            }
          } catch (e) {
            print("Error processing document ${doc.id}: $e");
          }
        }

        setState(() {
          _meetings = appointments;
          _calendarDataSource = MeetingDataSource(_meetings);
        });
      }, onError: (e) {
        print("Error listening to snapshot: $e");
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to fetch medication data: $e'))
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No user logged in!'))
      );
    }
  }


  int _parseDuration(String duration) {
    duration = duration.toLowerCase();
    int number = int.tryParse(duration.split(' ')[0]) ?? 0;

    if (duration.contains('week')) {
      return number * 7;
    } else if (duration.contains('month')) {
      return number * 30;
    } else if (duration.contains('day')) {
      return number;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicine Calendar'),
        actions: [
          IconButton(
            icon: Icon(Icons.view_week),
            onPressed: () => setState(() {
              _view = _view == CalendarView.month ? CalendarView.week : CalendarView.month;
            }),
          )
        ],
        centerTitle: true,
        elevation: 0,
      ),
      body: _calendarDataSource != null
          ? SfCalendar(
        view: _view,
        dataSource: _calendarDataSource!,
        monthViewSettings: const MonthViewSettings(
          appointmentDisplayMode: MonthAppointmentDisplayMode.indicator,
          showAgenda: true,
        ),
        headerStyle: const CalendarHeaderStyle(
          textAlign: TextAlign.center,
          backgroundColor: Colors.blue,
          textStyle: TextStyle(color: Colors.white, fontSize: 18),
        ),
        todayHighlightColor: Colors.orange,
        selectionDecoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.deepOrange, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}
