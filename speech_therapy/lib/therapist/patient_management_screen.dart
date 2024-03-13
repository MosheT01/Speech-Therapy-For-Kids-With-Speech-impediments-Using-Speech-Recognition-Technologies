import 'package:flutter/material.dart';

class PatientManagementScreen extends StatelessWidget {
  const PatientManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Patients'),
      ),
      body: const Center(
        child: Text(
          'This is the Patient Management Screen',
          style: TextStyle(fontSize: 20.0),
        ),
      ),
    );
  }
}
