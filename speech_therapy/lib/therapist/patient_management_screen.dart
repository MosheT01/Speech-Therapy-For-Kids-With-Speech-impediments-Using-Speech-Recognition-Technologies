import 'package:flutter/material.dart';
import 'AddPatientScreen.dart';
import 'package:firebase_database/firebase_database.dart';
//TODO: Once A New Patint is added we should refresh the patint mangment list 

class PatientManagementScreen extends StatefulWidget {
  final String userId;
  const PatientManagementScreen({super.key, required this.userId});

  @override
  _PatientManagementScreenState createState() => _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  List<String> patients = [];

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("users").child(widget.userId).child("patients");

    DataSnapshot dataSnapshot;
    try {
      dataSnapshot = await ref.once().then((event) => event.snapshot);
    } catch (e) {
      print("An error occurred while fetching patients: $e");
      return;
    }

    if (dataSnapshot.value != null) {
      Map<dynamic, dynamic>? values = dataSnapshot.value as Map<dynamic, dynamic>?;
      if (values != null) {
        setState(() {
          patients = values.values
              .map((patient) => Map<String, dynamic>.from(patient))
              .map((patient) => '${patient['firstName']} ${patient['lastName']}')
              .toList();
        });
        print(patients);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Patients'),
      ),
      body: ListView.builder(
        itemCount: patients.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(patients[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPatientScreen(userId: widget.userId)),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
