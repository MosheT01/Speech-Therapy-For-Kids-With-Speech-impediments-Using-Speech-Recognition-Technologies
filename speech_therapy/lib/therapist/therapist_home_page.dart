import 'package:flutter/material.dart';
import 'patient_management_screen.dart'; // Import the patient management screen
import 'schedule_appointment_screen.dart'; // Import the schedule appointment screen
import 'speechRecPrototype.dart';

class TherapistHomePage extends StatelessWidget {
  final String userId;

  const TherapistHomePage({super.key, required this.userId});

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
                  MaterialPageRoute(
                      builder: (context) =>
                          PatientManagementScreen(userId: userId)),
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
                  MaterialPageRoute(
                      builder: (context) => ScheduleAppointmentScreen(
                            userId: userId,
                          )),
                );
              },
              child: const Text('Schedule Appointment'),
            ),
            // Add more buttons and functionality as needed
            const SizedBox(height: 10.0), // Added space between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SpeechRecPrototype()),
                );
              },
              child: const Text('Speech Rec Prototype'),
            ),
          ],
        ),
      ),
    );
  }
}
