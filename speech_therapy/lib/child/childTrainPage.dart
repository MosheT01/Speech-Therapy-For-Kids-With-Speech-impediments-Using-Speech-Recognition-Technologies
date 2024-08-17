import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'childHomePage.dart';
import 'childExercise.dart';

class CustomCacheManager {
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'customCacheKey',
      stalePeriod: const Duration(days: 30), // Cache duration
      maxNrOfCacheObjects: 100, // Max number of objects to cache
    ),
  );

  static CacheManager get instance => _cacheManager;
}

class ChildTrainPage extends StatefulWidget {
  final String userId;

  const ChildTrainPage({super.key, required this.userId});

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

    try {
      // Fetch the therapist ID asynchronously
      String? therapistId = await fetchTherapistIdFromChildId(widget.userId);

      // Check if therapistId is not null
      if (therapistId == null) {
        throw Exception("Therapist ID not found");
      }

      DatabaseReference trainingPlansRef = FirebaseDatabase.instance
          .ref("users")
          .child(therapistId)
          .child("patients")
          .child(widget.userId)
          .child("trainingPlans");
      final dataSnapshot = await trainingPlansRef.once();
      final values = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        String? activePlanKey;
        Map<dynamic, dynamic>? activePlanData;

        // Find the active plan
        values.forEach((key, value) {
          final planData = value as Map<dynamic, dynamic>;
          if (planData['active'] == true) {
            activePlanKey = key;
            activePlanData = planData;
          }
        });

        if (activePlanKey != null && activePlanData != null) {
          List<Map<String, dynamic>> videoList = [];
          final videosData =
              activePlanData!['videos'] as Map<dynamic, dynamic>?;

          if (videosData != null) {
            videosData.forEach((key, value) {
              Map<String, dynamic> videoData =
                  Map<String, dynamic>.from(value as Map<dynamic, dynamic>);
              videoData['key'] = key; // Add the video key to the video data

              // Cache the video URL
              if (!kIsWeb) {
                String? downloadURL = videoData['downloadURL'];
                if (downloadURL != null) {
                  CustomCacheManager.instance
                      .downloadFile(downloadURL)
                      // ignore: body_might_complete_normally_catch_error
                      .catchError((e) {
                    debugPrint('Error caching video URL: $e');
                  });
                }
              }

              videoList.add(videoData);
            });
          }

          setState(() {
            videos = videoList;
          });
        } else {
          // No active plan found
          setState(() {
            videos = [];
          });
        }
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
                      onTap: () async {
                        var therapistId =
                            await fetchTherapistIdFromChildId(widget.userId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlaybackPage(
                              videoUrl: video['downloadURL'] ?? '',
                              videoTitle: video['word'] ?? 'No Title',
                              therapistID: therapistId!,
                              userId: widget.userId,
                              videoKey: video['key'] ?? 'No Key',
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
