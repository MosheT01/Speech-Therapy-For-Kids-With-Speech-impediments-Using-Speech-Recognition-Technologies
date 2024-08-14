import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_therapy/child/Games/MemoryGame.dart';
import 'package:speech_therapy/main.dart';
import 'childTrainPage.dart';

// Fetch this patient's therapist ID
Future<String?> fetchTherapistIdFromChildId(String childId) async {
  try {
    DatabaseReference userRef =
        FirebaseDatabase.instance.ref('users/$childId/therapistId');
    DataSnapshot therapistIdSnapshot = (await userRef.once()).snapshot;
    String? therapistId = therapistIdSnapshot.value as String?;
    return therapistId;
  } catch (e) {
    return null;
  }
}

class ChildHomePage extends StatelessWidget {
  final String userId;

  const ChildHomePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Home'),
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
              'Welcome, Child!',
              style: TextStyle(fontSize: 24.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to the screen for training
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChildTrainPage(userId: userId),
                  ),
                );
              },
              child: const Text('Let\'s Train!'),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                // Navigate to the screen for Mission Adventure
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(userId: userId),
                  ),
                );
              },
              child: const Text('Let\'s Play Games!'),
            ),
            const SizedBox(height: 10.0), // Added space between buttons
            ElevatedButton(
              onPressed: () {},
              child: const Text('View Progress'),
            ),
          ],
        ),
      ),
    );
  }
}
