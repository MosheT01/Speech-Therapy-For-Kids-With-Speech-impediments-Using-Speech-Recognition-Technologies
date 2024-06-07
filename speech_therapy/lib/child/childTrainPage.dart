import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'childHomePage.dart';
import 'childExercise.dart';

class ChildTrainPage extends StatefulWidget {
  final String userId;

  ChildTrainPage({super.key, required this.userId});

  @override
  _ChildTrainPageState createState() => _ChildTrainPageState();
}

class _ChildTrainPageState extends State<ChildTrainPage> {
  List<Map<String, dynamic>> videos = []; // List to store video data
  bool _isLoading = true; // Loading state indicator

  @override
  void initState() {
    super.initState();
    fetchVideoExercises(); // Fetch videos when the widget is initialized
  }

  Future<void> fetchVideoExercises() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    // Fetch the therapist ID asynchronously
    String? therapistId = await fetchTherapistIdFromChildId(widget.userId);

    // Check if therapistId is not null
    if (therapistId == null) {
      throw Exception("Therapist ID not found");
    }

    DatabaseReference ref = FirebaseDatabase.instance
        .ref("users")
        .child(therapistId)
        .child("patients")
        .child(widget.userId)
        .child("videos");

    try {
      final dataSnapshot = await ref.once();
      final values = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        List<Map<String, dynamic>> videoList = [];
        values.forEach((key, value) {
          Map<String, dynamic> videoData =
              Map<String, dynamic>.from(value as Map);
          videoData['key'] = key; // Add the video key to the video data
          videoList.add(videoData);
        });
        setState(() {
          videos = videoList;
        });
      }
    } catch (e) {
      debugPrint('Error fetching video exercises: $e');
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Train Page'),
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(), // Show loading indicator while fetching data
            )
          : videos.isEmpty
              ? const Center(
                  child: Text(
                      'No videos available'), // Show message if no videos are available
                )
              : ListView.builder(
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    return ListTile(
                      title: Text(video['word'] ?? 'No Title'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Difficulty: ${video['difficulty']}'),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlaybackPage(
                              videoUrl: video['downloadURL'] ?? '',
                              videoTitle: video['word'] ?? 'No Title',
                            ),
                          ),
                        );
                      },
                    );
                  },
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
