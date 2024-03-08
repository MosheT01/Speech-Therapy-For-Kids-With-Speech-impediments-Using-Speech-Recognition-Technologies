import 'package:flutter/material.dart';
import 'patient_management_screen.dart'; // Import the patient management screen
import 'schedule_appointment_screen.dart'; // Import the schedule appointment screen

class TherapistHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Therapist Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, Therapist!',
              style: TextStyle(fontSize: 24.0),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to the screen for managing patients
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PatientManagementScreen()),
                );
              },
              child: Text('Manage Patients'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to the screen for scheduling appointments
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScheduleAppointmentScreen()),
                );
              },
              child: Text('Schedule Appointment'),
            ),
            // Add more buttons and functionality as needed
          ],
        ),
      ),
    );
  }
}
