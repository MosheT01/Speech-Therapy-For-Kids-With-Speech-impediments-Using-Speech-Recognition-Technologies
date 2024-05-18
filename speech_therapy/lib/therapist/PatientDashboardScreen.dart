import 'package:flutter/material.dart';
https://pub.dev/packages/camera/install

class PatientDashboardScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Patient Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Patient Details:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Name: ${patientData['firstName']} ${patientData['lastName']}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Age: ${patientData['age']}',
                style: TextStyle(fontSize: 16),
              ),
              Text(
                'Gender: ${patientData['gender']}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Add your functionality here, for example, navigating to another screen or performing an action.
                },
                child: Text('Edit Patient Details'),
              ),
              //add devider
              Divider(
                color: Colors.black,
                thickness: 1,
              ),
              //header that says "Patient Video Exercises"
              const Text(
                'Patient Video Exercises:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: 3,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Video Exercise ${index + 1}'),
                    subtitle: Text('Video Placeholder'),
                    leading: Icon(Icons.video_library),
                    onTap: () {
                      // Add your functionality here, for example, playing the video.
                    },
                  );
                },
              ),
              ElevatedButton(
              onPressed: () {
                // Add your functionality here, for example, navigating to another screen or performing an action.
              },
              child: const Text('Add Video Exercise'),
            ),
            ],
          
          ),
        ),
      ),
    );
  }
}
