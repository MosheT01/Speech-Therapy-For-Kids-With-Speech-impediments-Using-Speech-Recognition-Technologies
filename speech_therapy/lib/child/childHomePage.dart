import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'childTrainPage.dart';

//fetch this patient's therapist id
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
                //navigate to the screen for training
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChildTrainPage(userId: userId),
                  ),
                );
              },
              child: const Text('Lets Train!'),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                //
              },
              child: const Text('Lets Play Games!'),
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
