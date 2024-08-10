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
  late Map<String, dynamic> patientData = {};

  List<Map<String, dynamic>> videoExercises = [];

  bool isLoading = false;
  bool _isUploading = false; // Track video upload status

  //fetch patient data from the database
  Future<void> fetchPatientData() async {
    setState(() {
      isLoading = true;
    });
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("users")
        .child(widget.userId)
        .child("patients")
        .child(widget.patientKey);

    try {
      final dataSnapshot = await ref.once();
      final value = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (value != null) {
        setState(() {
          patientData = Map<String, dynamic>.from(value);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching patient data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchVideoExercises();
    fetchPatientData();
    // Set up the listener for real-time updates
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("users")
        .child(widget.userId)
        .child("patients")
        .child(widget.patientKey)
        .child("videos");

    ref.onValue.listen((event) {
      fetchVideoExercises();
      fetchPatientData();
    });
  }

  Future<List<Map<String, dynamic>>> fetchVideoExercises() async {
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
          videoData['key'] = key; // Add the video key to the video data

          // Cache the video URL
          String? downloadURL = videoData['downloadURL'];
          if (downloadURL != null) {
            CustomCacheManager.instance
                .downloadFile(downloadURL)
                .catchError((e) {
              debugPrint('Error caching video URL: $e');
            });
          }

          videos.add(videoData);
        });

        return videos;
      }
    } catch (e) {
      debugPrint('Error fetching video exercises: $e');
    }
    return [];
  }

  void _showEditDialog(BuildContext context) {
    String firstName = patientData['firstName'];
    String lastName = patientData['lastName'];
    int age = patientData['age'];
    String gender = patientData['gender'];

    final firstNameController = TextEditingController(text: firstName);
    final lastNameController = TextEditingController(text: lastName);
    final ageController = TextEditingController(text: age.toString());

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Patient Details'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
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
                        onChanged: (value) {
                          setState(() {
                            firstName = value;
                          });
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
                        onChanged: (value) {
                          setState(() {
                            lastName = value;
                          });
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
                        onChanged: (value) {
                          setState(() {
                            age = int.tryParse(value) ?? 0;
                          });
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
                      )
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      // Update the patient details in the database
                      final DatabaseReference ref = FirebaseDatabase.instance
                          .ref()
                          .child('users')
                          .child(widget.userId)
                          .child('patients')
                          .child(widget.patientKey);

                      ref.update({
                        'firstName': firstName,
                        'lastName': lastName,
                        'age': age,
                        'gender': gender,
                      }).then((_) {
                        debugPrint('Patient details updated successfully');
                        setState(() {
                          // Update local state
                          patientData['firstName'] = firstName;
                          patientData['lastName'] = lastName;
                          patientData['age'] = age;
                          patientData['gender'] = gender;
                        });
                        // Dismiss the dialog
                        Navigator.of(context).pop();
                        fetchPatientData();
                      }).catchError((error) {
                        debugPrint('Error updating patient details: $error');
                      });
                    }
                  },
                  child: const Text('Save'),
                ),
                TextButton(
                  onPressed: () {
                    // Dismiss the dialog without updating
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
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
            Row(
              children: [
                Align(
                  alignment: Alignment.bottomLeft,
                  child: TextButton(
                    onPressed: () async {
                      if (_isUploading) {
                        Fluttertoast.showToast(
                          msg:
                              'Cannot delete patient while video is uploading.',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                        return;
                      }

                      // Confirm deletion
                      Navigator.of(context).pop();
                      // Show deleting toast
                      Fluttertoast.showToast(
                        msg: 'Deleting patient...',
                        toastLength: Toast.LENGTH_LONG,
                        timeInSecForIosWeb: 6,
                        gravity: ToastGravity.BOTTOM,
                      );
                      //show loading
                      setState(() {
                        isLoading = true;
                      });
                      await _deletePatient();
                      //hide loading
                      setState(() {
                        isLoading = false;
                      });
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () {
                      // Cancel deletion
                      Navigator.of(context).pop();
                    },
                    autofocus: true,
                    //make button green fill
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // Function to delete all patient videos
  Future<void> deleteAllPatientVideos(String userId, String patientKey) async {
    try {
      // Create a reference to the patient's folder in Firebase Storage
      var ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('/$userId/$patientKey/');

      // List all files in the patient's folder
      var listResult = await ref.listAll();

      // Delete each file in the folder
      for (var item in listResult.items) {
        await item.delete();
      }
      //delete the folder
      await ref.delete();

      print('All patient videos deleted successfully');
    } catch (e) {
      print('Error deleting patient videos: $e');
    }
  }

  Future<void> _deletePatient() async {
    try {
      // Delete all patient videos
      await deleteAllPatientVideos(widget.userId, widget.patientKey);

      // Delete patient from therapist's patients list
      DatabaseReference therapistRef = FirebaseDatabase.instance
          .ref("users")
          .child(widget.userId)
          .child("patients")
          .child(widget.patientKey);
      await therapistRef.remove();

      // Set hasTherapist as false
      DatabaseReference patientHasTherapistRef = FirebaseDatabase.instance
          .ref("users")
          .child(widget.patientKey)
          .child("hasTherapist");
      await patientHasTherapistRef.set(false);

      // Delete therapistId from patient
      DatabaseReference patientTherapistIdRef = FirebaseDatabase.instance
          .ref("users")
          .child(widget.patientKey)
          .child("therapistId");
      await patientTherapistIdRef.remove();

      debugPrint(
          'Patient removed from care and their videos deleted successfully');
      Navigator.of(context).pop();
    } catch (e) {
      debugPrint('Error deleting patient: $e');
    }
  }

  void _navigateToVideoPreviewScreen({String? videoUrl}) async {
    if (videoUrl != null) {
      try {
        // Try to get the cached file
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
    } else {
      debugPrint('Download URL is null for video');
    }
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
                    isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        // Call _showEditDialog within setState
                                        _showEditDialog(context);
                                      });
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
                                'Name: ${patientData['firstName']} ${patientData['lastName']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Age: ${patientData['age']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                'Gender: ${patientData['gender']}',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                    const Divider(
                      color: Colors.black,
                      thickness: 1,
                    ),
                    const Text(
                      'Patient Video Exercises:',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    FutureBuilder(
                      future: fetchVideoExercises(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          if (videoExercises.isEmpty) {
                            return const Text(
                                'No videos found for this patient');
                          } else {
                            return const CircularProgressIndicator();
                          }
                        } else {
                          videoExercises = snapshot.data ?? [];
                          //sort the video exercises by key
                          videoExercises
                              .sort((a, b) => a['key'].compareTo(b['key']));

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: videoExercises.length,
                            itemBuilder: (context, index) {
                              Map<String, dynamic>? video =
                                  videoExercises[index];
                              return ListTile(
                                title: Text("${video['word'] ?? 'Unknown'}"),
                                subtitle: Text(
                                    'Video Exercise ${index + 1}\nDifficulty: ${video['difficulty'] ?? 'Unknown'}\nGrade: ${video['grade'] ?? 'N/A'}'),
                                leading: const Icon(Icons.video_library),
                                onTap: () {
                                  String? downloadURL = video['downloadURL'];
                                  if (downloadURL != null) {
                                    _navigateToVideoPreviewScreen(
                                        videoUrl: downloadURL);
                                  } else {
                                    debugPrint(
                                        'Download URL is null for video at index $index');
                                  }
                                },
                              );
                            },
                          );
                        }
                      },
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
                                  onUploadStart: () {
                                    setState(() {
                                      _isUploading = true;
                                    });
                                  },
                                  onUploadComplete: () {
                                    setState(() {
                                      _isUploading = false;
                                      // Fetch the videos again to update the list
                                      fetchVideoExercises();
                                    });
                                  },
                                ),
                              ),
                            ).then((_) {
                              setState(() {
                                // Refresh the UI after returning from the CameraExampleHome page
                                fetchVideoExercises();
                              });
                            });
                          },
                        );
                      },
                      child: const Text('Add Video Exercise'),
                    ),
                    //add divider
                    const Divider(
                      color: Colors.black,
                      thickness: 1,
                    ),
                    // //schedule appointment section
                    // const Text(
                    //   'Schedule Appointment:',
                    //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    // ),
                    // const SizedBox(height: 10),

                    // ElevatedButton(
                    //   onPressed: () {
                    //     // Implement your logic for scheduling an appointment here
                    //   },
                    //   child: const Text('Schedule Appointment'),
                    // ),
                  ],
                ),
              ),
            ),
    );
  }
}
