import 'package:flutter/material.dart';

class PatientDashboardScreen extends StatelessWidget {
  final String userId;
  final String patientKey;
  final Map<String, dynamic> patientData;

  const PatientDashboardScreen({
    Key? key,
    required this.patientKey,
    required this.patientData,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Dashboard'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient Details:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Name: ${patientData['firstName']} ${patientData['lastName']}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Age: ${patientData['age']}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Gender: ${patientData['gender']}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _editPatientDetails(context);
                },
                child: Text('Edit Patient Details'),
              ),
              SizedBox(height: 20),
              Text(
                'Treatment Plan:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildTreatmentPlanSection(),
            ],
          ),
        ),
      ),
    );
  }

  void _editPatientDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Patient Details'),
          content: Text('This is where you can edit patient details.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTreatmentPlanSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: Text(
            'Milestones:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          title: Text('1. Start rehabilitation program'),
          subtitle: Text('Status: In progress'),
        ),
        ListTile(
          title: Text('2. Complete first set of exercises'),
          subtitle: Text('Status: Pending'),
        ),
        ListTile(
          title: Text('3. Schedule follow-up appointment'),
          subtitle: Text('Status: Pending'),
        ),
        SizedBox(height: 20),
        ListTile(
          title: Text(
            'Exercises:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          title: Text('Exercise 1: Knee Strengthening'),
          subtitle: Text('Sets: 3, Reps: 10'),
        ),
        ListTile(
          title: Text('Exercise 2: Shoulder Stretch'),
          subtitle: Text('Sets: 2, Reps: 12'),
        ),
      ],
    );
  }
}
