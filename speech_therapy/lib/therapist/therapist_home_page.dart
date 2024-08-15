import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'patient_management_screen.dart'; // Import the patient management screen
import 'schedule_appointment_screen.dart'; // Import the schedule appointment screen
import 'speechRecPrototype.dart';
import '../main.dart';

class TherapistHomePage extends StatelessWidget {
  final String userId;

  const TherapistHomePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Therapist Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Show a confirmation dialog before logging out
              bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pop(false); // Dismiss the dialog
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true); // Confirm logout
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                // If confirmed, sign out from Firebase
                await FirebaseAuth.instance.signOut();

                // Navigate back to the login screen and remove all previous routes
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              }
            },
          ),
        ],
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
            // const SizedBox(height: 10.0),
            // ElevatedButton(
            //   onPressed: () {
            //     // Navigate to the screen for scheduling appointments
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //           builder: (context) => ScheduleAppointmentScreen(
            //                 userId: userId,
            //               )),
            //     );
            //   },
            //   child: const Text('Schedule Appointment'),
            // ),
            // // Add more buttons and functionality as needed
            // const SizedBox(height: 10.0), // Added space between buttons
            // ElevatedButton(
            //   onPressed: () {
            //     Navigator.push(
            //       context,
            //       MaterialPageRoute(
            //           builder: (context) => const SpeechRecPrototype()),
            //     );
            //   },
            //   child: const Text('Speech Rec Prototype'),
            // ),
          ],
        ),
      ),
    );
  }
}
