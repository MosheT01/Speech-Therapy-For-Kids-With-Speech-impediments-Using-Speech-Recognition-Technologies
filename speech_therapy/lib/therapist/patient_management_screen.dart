import 'package:flutter/material.dart';

class PatientManagementScreen extends StatelessWidget {
  const PatientManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Dummy list of patients
    List<String> patients = [
      'Patient 1',
      'Patient 2',
      'Patient 3',
      // Add more patients as needed
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Patients'),
      ),
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text(patients[index]),
            // Add onTap callback to handle selecting a patient
            onTap: () {
              // Add functionality to view patient details
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to a screen to add a new patient
          // For example:
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(builder: (context) => AddPatientScreen()),
          // );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
