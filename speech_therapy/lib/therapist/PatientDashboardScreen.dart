import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:speech_therapy/VideoPreviewScreen.dart';
import 'Camera.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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

class PatientDashboardScreen extends StatefulWidget {
  final String userId;
  final String patientKey;

  const PatientDashboardScreen({
    super.key,
    required this.patientKey,
    required this.userId,
  });

  @override
  _PatientDashboardScreenState createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late DatabaseReference _patientRef;
  late DatabaseReference _videosRef;
  late StreamSubscription<DatabaseEvent> _patientSubscription;
  late StreamSubscription<DatabaseEvent> _videosSubscription;

  Map<String, dynamic> _patientData = {};
  List<Map<String, dynamic>> _videoExercises = [];

  bool _isLoading = true;
  bool _hasError = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _patientRef = FirebaseDatabase.instance
        .ref("users")
        .child(widget.userId)
        .child("patients")
        .child(widget.patientKey);
    _videosRef = _patientRef.child("videos");

    _initData();
  }

  @override
  void dispose() {
    _patientSubscription.cancel();
    _videosSubscription.cancel();
    super.dispose();
  }

  void _initData() {
    _patientSubscription = _patientRef.onValue.listen(
      (event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          setState(() {
            _patientData = Map<String, dynamic>.from(data);
            _isLoading = false;
            _hasError = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _hasError = true;
          });
        }
      },
      onError: (error) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      },
    );

    _videosSubscription = _videosRef.onValue.listen(
      (event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          setState(() {
            _videoExercises = data.entries.map((entry) {
              final videoData = Map<String, dynamic>.from(entry.value);
              videoData['key'] = entry.key;

              // Cache the video URL
              String? downloadURL = videoData['downloadURL'];
              if (downloadURL != null) {
                CustomCacheManager.instance
                    .downloadFile(downloadURL)
                    .catchError((e) {
                  debugPrint('Error caching video URL: $e');
                });
              }

              return videoData;
            }).toList();
          });
        }
      },
      onError: (error) {
        setState(() {
          _hasError = true;
        });
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    String firstName = _patientData['firstName'] ?? 'N/A';
    String lastName = _patientData['lastName'] ?? 'N/A';
    int age = _patientData['age'] ?? 0;
    String gender = _patientData['gender'] ?? 'N/A';

    final firstNameController = TextEditingController(text: firstName);
    final lastNameController = TextEditingController(text: lastName);
    final ageController = TextEditingController(text: age.toString());

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Patient Details'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a valid first name';
                    }
                    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                      return 'Please enter a valid first name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a valid last name';
                    }
                    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                      return 'Please enter a valid last name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: ageController,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a valid age';
                    }
                    int? age = int.tryParse(value);
                    if (age == null || age < 1 || age > 150) {
                      return 'Please enter a valid age';
                    }
                    return null;
                  },
                ),
                DropdownButtonFormField<String>(
                  value: gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                  ),
                  items: ['Male', 'Female']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      gender = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final DatabaseReference ref = _patientRef;

                  ref.update({
                    'firstName': firstNameController.text,
                    'lastName': lastNameController.text,
                    'age': int.parse(ageController.text),
                    'gender': gender,
                  }).then((_) {
                    Navigator.of(context).pop();
                  }).catchError((error) {
                    debugPrint('Error updating patient details: $error');
                  });
                }
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Patient'),
          content: const Text(
              'Are you sure you want to delete this patient? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (_isUploading) {
                  Fluttertoast.showToast(
                    msg: 'Cannot delete patient while video is uploading.',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                  return;
                }

                await _deletePatient();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePatient() async {
    try {
      await deleteAllPatientVideos(widget.userId, widget.patientKey);

      await _patientRef.remove();

      DatabaseReference patientHasTherapistRef = FirebaseDatabase.instance
          .ref("users/${widget.patientKey}/hasTherapist");
      await patientHasTherapistRef.set(false);

      DatabaseReference patientTherapistIdRef = FirebaseDatabase.instance
          .ref("users/${widget.patientKey}/therapistId");
      await patientTherapistIdRef.remove();

      debugPrint(
          'Patient removed from care and their videos deleted successfully');
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error deleting patient: $e');
    }
  }

  Future<void> deleteAllPatientVideos(String userId, String patientKey) async {
    try {
      var ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('/$userId/$patientKey/');

      var listResult = await ref.listAll();

      for (var item in listResult.items) {
        await item.delete();
      }

      await ref.delete();

      debugPrint('All patient videos deleted successfully');
    } catch (e) {
      debugPrint('Error deleting patient videos: $e');
    }
  }

  void _navigateToVideoPreviewScreen({required String videoUrl}) async {
    try {
      final file = await CustomCacheManager.instance.getSingleFile(videoUrl);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPreviewScreen(
            videoUrl: videoUrl,
            filePath: file.path,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to video preview screen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Patient Details:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    if (_patientData.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _showEditDialog(context);
                                },
                                child: const Text('Edit Patient Details'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () {
                                  _showDeleteWarningDialog(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete Patient'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Name: ${_patientData['firstName'] ?? 'N/A'} ${_patientData['lastName'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Age: ${_patientData['age']?.toString() ?? 'N/A'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'Gender: ${_patientData['gender'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    const Divider(
                      color: Colors.black,
                      thickness: 1,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await availableCameras().then((cameras) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CameraExampleHome(
                                camera: cameras,
                                userId: widget.userId,
                                patientKey: widget.patientKey,
                                onUploadStart: () {
                                  setState(() {
                                    _isUploading = true;
                                  });
                                },
                                onUploadComplete: () {
                                  setState(() {
                                    _isUploading = false;
                                  });
                                },
                              ),
                            ),
                          );
                        });
                      },
                      child: const Text('Add Video Exercise'),
                    ),
                    const Text(
                      'Patient Video Exercises:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    _buildVideoList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildVideoList() {
    if (_videoExercises.isEmpty) {
      return const Text('No videos found for this patient.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _videoExercises.length,
      itemBuilder: (context, index) {
        final video = _videoExercises[index];

        final String word = video['word'] ?? 'N/A';
        final int difficulty = video['difficulty'] ?? 0;
        final String status = video['status'] ?? 'N/A';
        final int overallGrade = video['overallGrade'] ?? 0;
        final int averageSessionTime = video['averageSessionTime'] ?? 0;
        final int totalAttempts = video['totalAttempts'] ?? 0;
        final int totalSuccessfulAttempts =
            video['totalSuccessfulAttempts'] ?? 0;

        // Determine the color based on overall grade or if no attempts were made
        Color tileColor;
        Icon statusIcon;

        if (totalAttempts == 0) {
          tileColor = Colors.grey.withOpacity(0.3); // Not yet attempted
          statusIcon =
              Icon(Icons.access_time, color: Colors.grey); // Clock icon
        } else if (overallGrade < 50) {
          tileColor = Colors.red.withOpacity(0.3); // Poor performance
          statusIcon = Icon(Icons.cancel, color: Colors.red); // Red cross icon
        } else if (overallGrade >= 50 && overallGrade < 65) {
          tileColor =
              Colors.orange.withOpacity(0.3); // Moderate to good performance
          statusIcon = Icon(Icons.check_circle,
              color: Colors.orange); // Orange check icon
        } else {
          tileColor = Colors.green.withOpacity(0.3); // Perfect performance
          statusIcon =
              Icon(Icons.check_circle, color: Colors.green); // Green check icon
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: tileColor, // Move the color into BoxDecoration
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            title: Text(
              word,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Difficulty: $difficulty'),
                    Spacer(),
                    statusIcon,
                  ],
                ),
                Text('Total Attempts: $totalAttempts'),
                Text('Successful Attempts: $totalSuccessfulAttempts'),
                Text(
                  'Average Session Time: ${Duration(seconds: averageSessionTime).inMinutes}m ${Duration(seconds: averageSessionTime).inSeconds.remainder(60)}s',
                ),
                Text('Overall Grade: $overallGrade%'),
              ],
            ),
            leading: const Icon(Icons.video_library, size: 40.0),
            onTap: () {
              String? downloadURL = video['downloadURL'];
              if (downloadURL != null) {
                _navigateToVideoPreviewScreen(videoUrl: downloadURL);
              } else {
                debugPrint('Download URL is null for video at index $index');
              }
            },
          ),
        );
      },
    );
  }
}
