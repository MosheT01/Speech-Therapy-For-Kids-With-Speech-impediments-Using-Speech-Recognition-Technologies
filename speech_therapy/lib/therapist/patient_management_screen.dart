import 'package:flutter/material.dart';
import 'AddPatientScreen.dart';

class PatientManagementScreen extends StatelessWidget {
  const PatientManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Patients'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to a screen to add a new patient
          // For example:
          Navigator.push(
          context,
           MaterialPageRoute(builder: (context) => AddPatientScreen()),
           );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
