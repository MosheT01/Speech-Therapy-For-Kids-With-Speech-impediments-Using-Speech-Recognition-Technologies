import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_therapy/child/Games/GeminiChat.dart';
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

class ChildHomePage extends StatefulWidget {
  final String userId;

  const ChildHomePage({super.key, required this.userId});

  @override
  _ChildHomePageState createState() => _ChildHomePageState();
}

class _ChildHomePageState extends State<ChildHomePage> {
  String? childName;
  String? therapistId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Load data asynchronously after the widget is initialized
  Future<void> _loadData() async {
    therapistId = await fetchTherapistIdFromChildId(widget.userId);
    if (therapistId != null) {
      String? name = await fetchChildName(widget.userId, therapistId!);
      setState(() {
        childName = name;
      });
    }
  }

  // Fetch the child's name from the database
  Future<String?> fetchChildName(String childId, String therapistId) async {
    try {
      DatabaseReference userRef = FirebaseDatabase.instance
          .ref('users/$therapistId/patients/$childId/firstName');
      DataSnapshot nameSnapshot = (await userRef.once()).snapshot;
      String? childName = nameSnapshot.value as String?;
      return childName;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              bool? confirmLogout = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );

              if (confirmLogout == true) {
                await FirebaseAuth.instance.signOut();
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
            Text(
              childName != null ? 'Welcome, $childName!' : 'Welcome, Child!',
              style: const TextStyle(fontSize: 24.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChildTrainPage(userId: widget.userId),
                  ),
                );
              },
              child: const Text('Let\'s Train!👩‍🏫'),
            ),
            const SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(userId: widget.userId),
                  ),
                );
              },
              child: const Text('Let\'s Play Games!🎮'),
            ),
            const SizedBox(height: 10.0), // Added space between buttons
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GeminiChatPage(),
                  ),
                );
              },
              child: const Text('Lets Chat!🗣️🗨️'),
            ),
          ],
        ),
      ),
    );
  }
}
