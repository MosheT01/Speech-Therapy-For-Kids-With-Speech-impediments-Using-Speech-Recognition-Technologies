import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:camera/camera.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'Camera.dart';

class PatientDashboardScreen extends StatefulWidget {
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
  _PatientDashboardScreenState createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  List<Map<String, dynamic>> videoExercises = [];

  @override
  void initState() {
    super.initState();
    fetchVideoExercises();
  }

  Future<void> fetchVideoExercises() async {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("users")
        .child(widget.userId)
        .child("patients")
        .child(widget.patientKey)
        .child("videos");

    try {
      final dataSnapshot = await ref.once();
      final values = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        List<Map<String, dynamic>> videos = [];
        values.forEach((key, value) {
          Map<String, dynamic> videoData = Map.from(value);
          videos.add(videoData);
        });
        setState(() {
          videoExercises = videos;
        });
      }
    } catch (e) {
      print('Error fetching video exercises: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Details:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Name: ${widget.patientData['firstName']} ${widget.patientData['lastName']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Age: ${widget.patientData['age']}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Gender: ${widget.patientData['gender']}',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add your functionality here, for example, navigating to another screen or performing an action.
              },
              child: const Text('Edit Patient Details'),
            ),
            const Divider(
              color: Colors.black,
              thickness: 1,
            ),
            const Text(
              'Patient Video Exercises:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: videoExercises.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic>? video =
                      videoExercises[index]; // Adding null safety
                  // Checking if video is not null
                  return ListTile(
                    title: Text(
                        "${video['word'] ?? 'Unknown'}"), // Adding null check for 'word' property
                    subtitle: Text(
                        'Video Exercise ${index + 1}\nDifficulty: ${video['difficulty'] ?? 'Unknown'}' // Adding null check for 'difficulty' property
                        ),
                    leading: Icon(Icons.video_library),
                    onTap: () {
                      // Add your functionality here, for example, navigating to the download URL.
                      String? downloadURL =
                          video['downloadURL']; // Adding null safety
                      if (downloadURL != null) {
                        // Adding null check
                        // Navigate to the download URL
                        _launchURL(downloadURL);
                      } else {
                        // Handle case where downloadURL is null
                        print('Download URL is null for video at index $index');
                      }
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await availableCameras().then(
                  (value) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CameraExampleHome(
                          camera: value,
                          userId: widget.userId,
                          patientKey: widget.patientKey,
                        ),
                      ),
                    );
                  },
                );
              },
              child: const Text('Add Video Exercise'),
            ),
          ],
        ),
      ),
    );
  }
}

// Define the _launchURL function
void _launchURL(String url) async {
  if (await canLaunchUrlString(url)) {
    await launchUrlString(url);
  } else {
    throw 'Could not launch $url';
  }
}
