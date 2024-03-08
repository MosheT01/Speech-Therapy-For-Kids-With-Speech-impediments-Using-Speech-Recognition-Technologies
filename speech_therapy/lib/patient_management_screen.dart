import 'package:flutter/material.dart';

class PatientManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Patients'),
      ),
      body: Center(
        child: Text(
          'This is the Patient Management Screen',
          style: TextStyle(fontSize: 20.0),
        ),
      ),
    );
  }
}
