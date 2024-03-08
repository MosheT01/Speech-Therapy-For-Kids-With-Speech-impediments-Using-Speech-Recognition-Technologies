import 'package:flutter/material.dart';

class ScheduleAppointmentScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Appointment'),
      ),
      body: Center(
        child: Text(
          'This is the Schedule Appointment Screen',
          style: TextStyle(fontSize: 20.0),
        ),
      ),
    );
  }
}
