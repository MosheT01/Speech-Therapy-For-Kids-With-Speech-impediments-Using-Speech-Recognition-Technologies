// ignore_for_file: unused_field, unused_local_variable

import 'dart:async';
import 'package:flutter/foundation.dart';
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
  late DatabaseReference _trainingPlansRef;
  late StreamSubscription<DatabaseEvent> _patientSubscription;
  late StreamSubscription<DatabaseEvent> _trainingPlansSubscription;

  Map<String, dynamic> _patientData = {};
  Map<String, dynamic> _trainingPlans = {};
  bool _isLoading = true;
  bool _hasError = false;
  bool _isUploading = false;
  int retryCount = 0;
  static const int maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _initFirebaseReferences();
    _initializeData();
  }

  void _initFirebaseReferences() {
    _patientRef = FirebaseDatabase.instance
        .ref("users/${widget.userId}/patients/${widget.patientKey}");
    _trainingPlansRef = _patientRef.child("trainingPlans");
  }

  void _initializeData() {
    _patientSubscription = _patientRef.onValue.listen(
      (event) {
        final data = event.snapshot.value as Map?;
        if (data != null) {
          setState(() {
            _patientData = _parseMap(data);
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

    _trainingPlansSubscription = _trainingPlansRef.onValue.listen(
      (event) {
        final data = event.snapshot.value as Map?;
        if (data != null) {
          setState(() {
            _trainingPlans = _parseMap(data);
            _cacheAllVideos();
          });
        } else {
          setState(() {
            _hasError = true;
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

  Map<String, dynamic> _parseMap(Map<dynamic, dynamic> input) {
    final Map<String, dynamic> parsedMap = {};
    input.forEach((key, value) {
      if (key is String && value is Map) {
        parsedMap[key] = _parseMap(value);
      } else if (key is String) {
        parsedMap[key] = value;
      }
    });
    return parsedMap;
  }

  void _cacheAllVideos() {
    _trainingPlans.forEach((planKey, planData) {
      final videos = planData['videos'] as Map<String, dynamic>? ?? {};
      videos.forEach((videoKey, videoData) {
        final String? downloadURL = videoData['downloadURL'];
        if (downloadURL != null) {
          // ignore: body_might_complete_normally_catch_error
          CustomCacheManager.instance.downloadFile(downloadURL).catchError((e) {
            debugPrint('Error caching video URL: $e');
          });
        }
      });
    });
  }

  void _togglePlanActivation(String planKey, bool isActive) {
    DatabaseReference planRef = _trainingPlansRef.child(planKey);
    planRef.update({'active': isActive}).then((_) {
      if (isActive) {
        _trainingPlans.forEach((key, _) {
          if (key != planKey) {
            _trainingPlansRef.child(key).update({'active': false});
          }
        });
      }
    }).catchError((error) {
      debugPrint('Error updating plan activation: $error');
    });
  }

  void _showAddPlanDialog(BuildContext context) {
    final planNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Plan Name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: planNameController,
              decoration: const InputDecoration(
                labelText: 'Plan Name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a plan name';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _addNewTrainingPlan(planNameController.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add Plan'),
            ),
          ],
        );
      },
    );
  }

  void _addNewTrainingPlan(String planName) {
    final newPlanRef = _trainingPlansRef.push();
    newPlanRef.set({'name': planName, 'active': false, 'videos': {}}).then((_) {
      debugPrint('New training plan added successfully');
    }).catchError((error) {
      debugPrint('Error adding new training plan: $error');
    });
  }

  void _showEditPlanNameDialog(BuildContext context, String planKey) {
    final planNameController = TextEditingController(
        text: _trainingPlans[planKey]['name'] ?? 'Unnamed Plan');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Plan Name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: planNameController,
              decoration: const InputDecoration(
                labelText: 'Plan Name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a plan name';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _editPlanName(planKey, planNameController.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _editPlanName(String planKey, String newName) {
    _trainingPlansRef.child(planKey).update({'name': newName}).then((_) {
      debugPrint('Plan name updated successfully');
    }).catchError((error) {
      debugPrint('Error updating plan name: $error');
    });
  }

  void _deletePlan(String planKey) {
    _showDeleteConfirmationDialog(
      context: context,
      title: 'Delete Training Plan',
      content:
          'Are you sure you want to delete this training plan? This action cannot be undone.',
      onConfirm: () async {
        try {
          DatabaseReference planRef = _trainingPlansRef.child(planKey);
          final snapshot = await planRef.child('videos').get();
          if (snapshot.exists) {
            final videosData = snapshot.value as Map?;
            if (videosData != null) {
              for (var videoData in videosData.entries) {
                final String? downloadURL = videoData.value['downloadURL'];
                if (downloadURL != null) {
                  await firebase_storage.FirebaseStorage.instance
                      .refFromURL(downloadURL)
                      .delete();
                }
              }
            }
          }
          await planRef.remove();
          debugPrint(
              'Plan and associated videos deleted successfully from database and storage.');
          setState(() {
            _trainingPlans.remove(planKey);
          });
        } catch (error) {
          debugPrint('Error deleting plan: $error');
        }
      },
    );
  }

  void _deleteVideo(String planKey, String videoKey) {
    _showDeleteConfirmationDialog(
      context: context,
      title: 'Delete Video',
      content:
          'Are you sure you want to delete this video? This action cannot be undone.',
      onConfirm: () async {
        try {
          DatabaseReference videoRef =
              _trainingPlansRef.child(planKey).child('videos').child(videoKey);
          final snapshot = await videoRef.get();
          if (snapshot.exists) {
            final videoData = snapshot.value as Map?;
            final String? downloadURL = videoData?['downloadURL'];
            if (downloadURL != null) {
              await firebase_storage.FirebaseStorage.instance
                  .refFromURL(downloadURL)
                  .delete();
            }
          }
          await videoRef.remove();
          debugPrint('Video deleted successfully from database and storage.');
        } catch (error) {
          debugPrint('Error deleting video: $error');
        }
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
      // Delete all training plans (and associated videos) first
      for (String planKey in _trainingPlans.keys) {
        DatabaseReference planRef = _trainingPlansRef.child(planKey);
        final snapshot = await planRef.child('videos').get();
        if (snapshot.exists) {
          final videosData = snapshot.value as Map?;
          if (videosData != null) {
            for (var videoData in videosData.entries) {
              final String? downloadURL = videoData.value['downloadURL'];
              if (downloadURL != null) {
                await firebase_storage.FirebaseStorage.instance
                    .refFromURL(downloadURL)
                    .delete();
              }
            }
          }
        }
        await planRef.remove();
      }

      // Remove patient data from Realtime Database
      await _patientRef.remove();

      // Update the patient's `hasTherapist` field and remove `therapistId`
      final DatabaseReference patientHasTherapistRef = FirebaseDatabase.instance
          .ref("users/${widget.patientKey}/hasTherapist");
      await patientHasTherapistRef.set(false);

      final DatabaseReference patientTherapistIdRef = FirebaseDatabase.instance
          .ref("users/${widget.patientKey}/therapistId");
      await patientTherapistIdRef.remove();

      debugPrint(
          'Patient and all associated data deleted successfully from database and storage.');

      // Navigate out of the current screen
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      debugPrint('Error deleting patient: $error');
    }
  }

  void _showEditDialogPtDetails(BuildContext context) {
    String firstName = _patientData['firstName'];
    String lastName = _patientData['lastName'];
    int age = _patientData['age'];
    String gender = _patientData['gender'];

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
                          _patientData['firstName'] = firstName;
                          _patientData['lastName'] = lastName;
                          _patientData['age'] = age;
                          _patientData['gender'] = gender;
                        });
                        // Dismiss the dialog
                        Navigator.of(context).pop();
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
                                  _showEditDialogPtDetails(context);
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
                      onPressed: () {
                        _showAddPlanDialog(context);
                      },
                      child: const Text('Add New Training Plan'),
                    ),
                    const SizedBox(height: 20),
                    _buildTrainingPlansList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTrainingPlansList() {
    if (_trainingPlans.isEmpty) {
      return const Text('No training plans found for this patient.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _trainingPlans.length,
      itemBuilder: (context, index) {
        final planKey = _trainingPlans.keys.elementAt(index);
        final planData = _trainingPlans[planKey];
        final isActive = planData['active'] ?? false;

        return ExpansionTile(
          title: Text(
            planData['name'] ?? 'Unnamed Plan',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
          ),
          subtitle: Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              color: isActive ? Colors.green : Colors.red,
            ),
          ),
          trailing: Switch(
            value: isActive,
            onChanged: (value) => _togglePlanActivation(planKey, value),
          ),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _showEditPlanNameDialog(context, planKey),
                  child: const Text('Edit Plan Name'),
                ),
                ElevatedButton(
                  onPressed: () => _deletePlan(planKey),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Delete Plan'),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () => _navigateToCameraScreen(planKey),
              child: const Text('Add New Video to Plan'),
            ),
            ..._buildVideoList(planKey, planData['videos'] ?? {}),
          ],
        );
      },
    );
  }

  List<Widget> _buildVideoList(String planKey, Map<String, dynamic> videos) {
    if (videos.isEmpty) {
      return [const ListTile(title: Text('No videos found in this plan.'))];
    }

    return videos.entries.map((entry) {
      final videoKey = entry.key;
      final videoData = entry.value as Map?;

      if (videoData == null) {
        return const ListTile(title: Text('Invalid video data.'));
      }

      final String word = videoData['word'] ?? 'N/A';
      final int difficulty = videoData['difficulty'] ?? 0;
      final String status = videoData['status'] ?? 'N/A';
      final int overallGrade = videoData['overallGrade'] ?? 0;
      final int averageSessionTime = videoData['averageSessionTime'] ?? 0;
      final int totalAttempts = videoData['totalAttempts'] ?? 0;
      final int totalSuccessfulAttempts =
          videoData['totalSuccessfulAttempts'] ?? 0;

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: _getTileColor(overallGrade, totalAttempts),
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
            style: const TextStyle(
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
                  const Spacer(),
                  _getStatusIcon(overallGrade, totalAttempts),
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
            String? downloadURL = videoData['downloadURL'];
            if (downloadURL != null) {
              _navigateToVideoPreviewScreen(videoUrl: downloadURL);
            } else {
              debugPrint('Download URL is null for video with key $videoKey');
            }
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditDialog(context, videoKey, planKey);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _deleteVideo(planKey, videoKey);
                },
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Color _getTileColor(int overallGrade, int totalAttempts) {
    if (totalAttempts == 0) {
      return Colors.grey.withOpacity(0.3); // Not yet attempted
    } else if (overallGrade < 50) {
      return Colors.red.withOpacity(0.3); // Poor performance
    } else if (overallGrade >= 50 && overallGrade < 65) {
      return Colors.orange.withOpacity(0.3); // Moderate to good performance
    } else {
      return Colors.green.withOpacity(0.3); // Perfect performance
    }
  }

  Icon _getStatusIcon(int overallGrade, int totalAttempts) {
    if (totalAttempts == 0) {
      return Icon(Icons.access_time, color: Colors.grey); // Clock icon
    } else if (overallGrade < 50) {
      return Icon(Icons.cancel, color: Colors.red); // Red cross icon
    } else if (overallGrade >= 50 && overallGrade < 65) {
      return Icon(Icons.check_circle,
          color: Colors.orange); // Orange check icon
    } else {
      return Icon(Icons.check_circle, color: Colors.green); // Green check icon
    }
  }

  void _showDeleteConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_isUploading) {
                  Fluttertoast.showToast(
                    msg: 'Cannot delete item while video is uploading.',
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                  return;
                }
                onConfirm();
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, String videoKey, String planKey) {
    String word = _trainingPlans[planKey]['videos'][videoKey]['word'] ?? '';
    int difficulty =
        _trainingPlans[planKey]['videos'][videoKey]['difficulty'] ?? 5;

    final wordController = TextEditingController(text: word);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Video Details'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: wordController,
                      decoration: const InputDecoration(labelText: 'Word'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a word';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Difficulty:'),
                    Slider(
                      value: difficulty.toDouble(),
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      label: difficulty.toString(),
                      onChanged: (value) {
                        setState(() {
                          difficulty = value.toInt();
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
                      final DatabaseReference videoRef = _trainingPlansRef
                          .child(planKey)
                          .child("videos")
                          .child(videoKey);

                      videoRef.update({
                        'word': wordController.text,
                        'difficulty': difficulty,
                      }).then((_) {
                        Navigator.of(context).pop();
                      }).catchError((error) {
                        debugPrint('Error updating video details: $error');
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
      },
    );
  }

  void _navigateToCameraScreen(String planKey) async {
    await availableCameras().then((cameras) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraExampleHome(
            camera: cameras,
            userId: widget.userId,
            patientKey: widget.patientKey,
            planKey: planKey,
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
  }

  void _navigateToVideoPreviewScreen({required String videoUrl}) async {
    if (kIsWeb) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPreviewScreen(
            videoUrl: videoUrl,
            filePath: null,
          ),
        ),
      );
    } else {
      try {
        final file =
            await CustomCacheManager.instance.getFileFromCache(videoUrl);
        String? filePath = file?.file.path;

        if (filePath != null && filePath.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPreviewScreen(
                videoUrl: videoUrl,
                filePath: filePath,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPreviewScreen(
                videoUrl: videoUrl,
                filePath: null,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error navigating to video preview screen: $e');
      }
    }
  }
}
