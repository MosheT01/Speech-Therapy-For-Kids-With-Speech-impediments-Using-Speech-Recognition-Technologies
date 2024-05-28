import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:camera/camera.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'Camera.dart';

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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Patient Details'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                      onChanged: (value) {
                        setState(() {
                          firstName = value;
                        });
                      },
                    ),
                    TextField(
                      controller: lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                      ),
                      onChanged: (value) {
                        setState(() {
                          lastName = value;
                        });
                      },
                    ),
                    TextField(
                      controller: ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                      ),
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
              actions: [
                TextButton(
                  onPressed: () {
                    if (firstName.isEmpty ||
                        lastName.isEmpty ||
                        !RegExp(r'^[a-zA-Z]+$').hasMatch(firstName) ||
                        !RegExp(r'^[a-zA-Z]+$').hasMatch(lastName)) {
                      // Validation errors
                      return;
                    } else if (age < 1 || age > 150) {
                      // Validation errors
                      return;
                    }

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Patient Details:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Call _showEditDialog within setState
                  _showEditDialog(context);
                });
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
            FutureBuilder(
              future: fetchVideoExercises(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  if (videoExercises.isEmpty) {
                    return const Text('No videos found for this patient');
                  } else {
                    return const CircularProgressIndicator();
                  }
                } else {
                  videoExercises = snapshot.data ?? [];
                  //sort the video exercises by key
                  videoExercises.sort((a, b) => a['key'].compareTo(b['key']));

                  return Expanded(
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: videoExercises.length,
                            itemBuilder: (context, index) {
                              Map<String, dynamic>? video =
                                  videoExercises[index];
                              return ListTile(
                                title: Text("${video['word'] ?? 'Unknown'}"),
                                subtitle: Text(
                                    'Video Exercise ${index + 1}\nDifficulty: ${video['difficulty'] ?? 'Unknown'}'),
                                leading: const Icon(Icons.video_library),
                                onTap: () {
                                  String? downloadURL = video['downloadURL'];
                                  if (downloadURL != null) {
                                    _launchURL(downloadURL);
                                  } else {
                                    debugPrint(
                                        'Download URL is null for video at index $index');
                                  }
                                },
                              );
                            },
                          ),
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
                        ),
                      ),
                    ).then((_) {
                      setState(
                          () {}); // Refresh the UI after returning from the CameraExampleHome page
                    });
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
