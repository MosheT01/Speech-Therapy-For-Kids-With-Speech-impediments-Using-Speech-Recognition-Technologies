import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:speech_therapy/VideoPreviewScreen.dart';
import 'Camera.dart';

class CustomCacheManager {
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'customCacheKey',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 100,
    ),
  );

  static CacheManager get instance => _cacheManager;
}

class PatientDashboardScreen extends StatefulWidget {
  final String userId;
  final String patientKey;

  const PatientDashboardScreen({
    super.key,
    required this.userId,
    required this.patientKey,
  });

  @override
  _PatientDashboardScreenState createState() => _PatientDashboardScreenState();
}

class _PatientDashboardScreenState extends State<PatientDashboardScreen> {
  late Map<String, dynamic> patientData = {};
  List<Map<String, dynamic>> videoExercises = [];
  bool isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    fetchInitialData();
    setupRealtimeUpdates();
  }

  Future<void> fetchInitialData() async {
    setState(() {
      isLoading = true;
    });

    await Future.wait([
      fetchPatientData(),
      fetchVideoExercises(),
    ]);

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchPatientData() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .ref("users/${widget.userId}/patients/${widget.patientKey}");

      final dataSnapshot = await ref.once();
      final value = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (value != null) {
        setState(() {
          patientData = Map<String, dynamic>.from(value);
        });
        debugPrint('Patient data fetched successfully: $patientData');
      } else {
        debugPrint('No patient data found.');
      }
    } catch (e) {
      debugPrint('Error fetching patient data: $e');
    }
  }

  Future<void> fetchVideoExercises() async {
    try {
      DatabaseReference ref = FirebaseDatabase.instance
          .ref("users/${widget.userId}/patients/${widget.patientKey}/videos");

      final dataSnapshot = await ref.once();
      final values = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        List<Map<String, dynamic>> videos = [];
        for (var entry in values.entries) {
          Map<String, dynamic> videoData = Map.from(entry.value);
          videoData['key'] = entry.key;

          // Cache the video URL
          String? downloadURL = videoData['downloadURL'];
          if (downloadURL != null) {
            await CustomCacheManager.instance.downloadFile(downloadURL);
          }

          if (videoData.containsKey('sessions')) {
            Map<dynamic, dynamic> sessions = videoData['sessions'];
            int totalAttempts = 0;
            int successfulAttempts = 0;
            int totalTimeSpent = 0;

            for (var sessionData in sessions.values) {
              totalAttempts += (sessionData['totalAttempts'] ?? 0) as int;
              successfulAttempts +=
                  (sessionData['successfulAttempts'] ?? 0) as int;
              totalTimeSpent += (sessionData['timeSpentInSession'] ?? 0) as int;
            }

            videoData['totalAttempts'] = totalAttempts;
            videoData['successfulAttempts'] = successfulAttempts;
            videoData['averageTimeSpent'] =
                totalTimeSpent > 0 ? totalTimeSpent ~/ sessions.length : 0;
          }

          videos.add(videoData);
        }

        setState(() {
          videoExercises = videos;
        });
        debugPrint('Video exercises fetched successfully.');
      } else {
        debugPrint('No video exercises found.');
      }
    } catch (e) {
      debugPrint('Error fetching video exercises: $e');
    }
  }

  void setupRealtimeUpdates() {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("users/${widget.userId}/patients/${widget.patientKey}/videos");

    ref.onChildChanged.listen((event) {
      debugPrint('Real-time database update detected, fetching data...');
      fetchVideoExercises();
      fetchPatientData();
    });
  }

  void _showEditDialog(BuildContext context) {
    final firstNameController =
        TextEditingController(text: patientData['firstName'] ?? '');
    final lastNameController =
        TextEditingController(text: patientData['lastName'] ?? '');
    final ageController =
        TextEditingController(text: patientData['age']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    String gender = patientData['gender'] ?? 'Male';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Patient Details'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  controller: firstNameController,
                  label: 'First Name',
                  validator: _validateName,
                ),
                _buildTextField(
                  controller: lastNameController,
                  label: 'Last Name',
                  validator: _validateName,
                ),
                _buildTextField(
                  controller: ageController,
                  label: 'Age',
                  keyboardType: TextInputType.number,
                  validator: _validateAge,
                ),
                DropdownButtonFormField<String>(
                  value: gender,
                  items: ['Male', 'Female'].map((String value) {
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
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _savePatientDetails(
                    firstName: firstNameController.text,
                    lastName: lastNameController.text,
                    age: int.parse(ageController.text),
                    gender: gender,
                  );
                  Navigator.of(context).pop();
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

  void _savePatientDetails({
    required String firstName,
    required String lastName,
    required int age,
    required String gender,
  }) async {
    try {
      final DatabaseReference ref = FirebaseDatabase.instance
          .ref("users/${widget.userId}/patients/${widget.patientKey}");

      await ref.update({
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'gender': gender,
      });

      setState(() {
        patientData['firstName'] = firstName;
        patientData['lastName'] = lastName;
        patientData['age'] = age;
        patientData['gender'] = gender;
      });

      debugPrint('Patient details updated successfully.');
    } catch (e) {
      debugPrint('Error updating patient details: $e');
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a valid name';
    }
    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
      return 'Please enter a valid name';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a valid age';
    }
    int? age = int.tryParse(value);
    if (age == null || age < 1 || age > 150) {
      return 'Please enter a valid age';
    }
    return null;
  }

  void _showDeleteWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
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

      DatabaseReference therapistRef = FirebaseDatabase.instance
          .ref("users/${widget.userId}/patients/${widget.patientKey}");

      await therapistRef.remove();

      DatabaseReference patientHasTherapistRef = FirebaseDatabase.instance
          .ref("users/${widget.patientKey}/hasTherapist");
      await patientHasTherapistRef.set(false);

      DatabaseReference patientTherapistIdRef = FirebaseDatabase.instance
          .ref("users/${widget.patientKey}/therapistId");

      await patientTherapistIdRef.remove();

      debugPrint(
          'Patient removed from care and their videos deleted successfully.');
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
        debugPrint('Deleted video: ${item.name}');
      }

      await ref.delete();
      debugPrint('All patient videos deleted successfully.');
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
      debugPrint('Navigated to VideoPreviewScreen with URL: $videoUrl');
    } catch (e) {
      debugPrint('Error navigating to video preview screen: $e');
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Patient Details:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (patientData.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildPatientDetails(),
                  ],
                  const Divider(color: Colors.black, thickness: 1),
                  const Text(
                    'Patient Video Exercises:',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildVideoExercises(),
                  ElevatedButton(
                    onPressed: () async {
                      debugPrint('Navigating to Camera screen...');
                      await availableCameras().then(
                        (cameras) {
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
                                    fetchVideoExercises();
                                  });
                                },
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

  Widget _buildPatientDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ElevatedButton(
              onPressed: () => _showEditDialog(context),
              child: const Text('Edit Patient Details'),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () => _showDeleteWarningDialog(context),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete Patient'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Name: ${patientData['firstName']} ${patientData['lastName']}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          'Age: ${patientData['age']?.toString()}',
          style: const TextStyle(fontSize: 16),
        ),
        Text(
          'Gender: ${patientData['gender']}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildVideoExercises() {
    if (videoExercises.isEmpty) {
      return const Text('No videos found for this patient.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: videoExercises.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> video = videoExercises[index];

        final String word = video['word'] ?? 'N/A';
        final int difficulty = video['difficulty'] ?? 0;
        final int grade = video['grade'] ?? 0;
        final int overallGrade = video['overallGrade'] ?? 0;
        final int totalAttempts = video['totalAttempts'] ?? 0;
        final int averageTimeSpentInSeconds = video['averageTimeSpent'] ?? 0;
        final Duration averageTimeSpent =
            Duration(seconds: averageTimeSpentInSeconds);
        final String status = video['status'] ?? 'N/A';

        return ListTile(
          title: Text(word),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Video Exercise ${index + 1}'),
              Text(
                  'Difficulty: ${difficulty != 0 ? difficulty.toString() : 'N/A'}'),
              Text('Grade: ${grade != 0 ? grade.toString() : 'N/A'}'),
              Text(
                  'Overall Grade: ${overallGrade != 0 ? overallGrade.toString() : 'N/A'}'),
              Text(
                  'Total Attempts: ${totalAttempts != 0 ? totalAttempts.toString() : 'N/A'}'),
              Text(
                  'Average Time Spent: ${averageTimeSpent.inMinutes}m ${averageTimeSpent.inSeconds.remainder(60)}s'),
              Text('Status: $status'),
            ],
          ),
          leading: const Icon(Icons.video_library),
          onTap: () {
            String? downloadURL = video['downloadURL'];
            if (downloadURL != null) {
              _navigateToVideoPreviewScreen(videoUrl: downloadURL);
            } else {
              debugPrint('Download URL is null for video at index $index');
            }
          },
        );
      },
    );
  }
}
