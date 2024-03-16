import 'package:flutter/material.dart';

class PatientManagementScreen extends StatelessWidget {
  const PatientManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Patients'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Patient Management',
              style: TextStyle(fontSize: 24.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Add functionality to view list of patients
              },
              child: const Text('View Patients'),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                // Add functionality to add new patient
              },
              child: const Text('Add New Patient'),
            ),
            // Add more functionality as needed
          ],
        ),
      ),
    );
  }
}
