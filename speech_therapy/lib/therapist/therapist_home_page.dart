import 'package:flutter/material.dart';
import 'patient_management_screen.dart'; // Import the patient management screen
import 'schedule_appointment_screen.dart'; // Import the schedule appointment screen

class TherapistHomePage extends StatelessWidget {
  const TherapistHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapist Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome, Therapist!',
              style: TextStyle(fontSize: 24.0),
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
            // Add more buttons and functionality as needed
          ],
        ),
      ),
    );
  }
}
