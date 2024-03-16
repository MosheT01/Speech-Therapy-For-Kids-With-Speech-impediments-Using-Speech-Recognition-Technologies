import 'package:flutter/material.dart';
import 'patient_management_screen.dart'; // Import the patient management screen
import 'schedule_appointment_screen.dart'; // Import the schedule appointment screen
// Import additional screens and features as needed

class TherapistHomePage extends StatelessWidget {
  const TherapistHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapist Home'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Welcome, Therapist!',
              style: TextStyle(fontSize: 24.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to the screen for managing patients
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PatientManagementScreen()),
                );
              },
              child: const Text('Manage Patients'),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to the screen for scheduling appointments
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ScheduleAppointmentScreen()),
                );
              },
              child: const Text('Schedule Appointment'),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                // Add functionality for additional feature
                // Navigate to the screen for additional feature
              },
              child: const Text('Additional Feature'),
            ),
            // Add more buttons and functionality as needed
          ],
        ),
      ),
    );
  }
}
