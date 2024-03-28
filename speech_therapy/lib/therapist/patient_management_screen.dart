import 'package:flutter/material.dart';
import 'AddPatientScreen.dart';

class PatientManagementScreen extends StatelessWidget {
  final String userId;
  const PatientManagementScreen({super.key,required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Patients'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to a screen to add a new patient
          // For example:
          Navigator.push(
          context,
           MaterialPageRoute(builder: (context) =>  AddPatientScreen(userId: userId,)),
           );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
