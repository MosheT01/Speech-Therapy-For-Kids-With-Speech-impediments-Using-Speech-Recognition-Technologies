import 'package:flutter/material.dart';
import 'AddPatientScreen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'PatientDashboardScreen.dart';

class PatientManagementScreen extends StatefulWidget {
  final String userId;
  const PatientManagementScreen({super.key, required this.userId});

  @override
  // ignore: library_private_types_in_public_api
  _PatientManagementScreenState createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  late DatabaseReference patientsRef;

  @override
  void initState() {
    super.initState();
    print("Initializing PatientManagementScreen...");
    patientsRef = FirebaseDatabase.instance
        .ref("users")
        .child(widget.userId)
        .child("patients");
    fetchPatients();
    setupRealtimeUpdates();
  }

  void setupRealtimeUpdates() {
    patientsRef.onChildChanged.listen((event) {
      print("Real-time update detected.");
      fetchPatients();
    });
  }

  Future<void> fetchPatients() async {
    print("Fetching patients...");
    setState(() {
      isLoading = true;
    });

    try {
      final dataSnapshot = await patientsRef.once();
      final values = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        patients = values.entries.map((entry) {
          Map<String, dynamic> patientWithKey = Map.from(entry.value);
          patientWithKey['key'] = entry.key;
          return patientWithKey;
        }).toList();
        filteredPatients = List.from(patients);
        print("Patients data fetched successfully.");
      } else {
        patients = [];
        filteredPatients = [];
        print("No patients found.");
      }
    } catch (e) {
      print("Error fetching patients: $e");
      displayError(
          'An error occurred while fetching the patient list from the database. Please try again later.');
    } finally {
      setState(() {
        isLoading = false;
      });
      print("Fetching patients completed.");
    }
  }

  void filterPatients(String query) {
    setState(() {
      filteredPatients = patients
          .where((patient) =>
              patient['firstName']
                  .toLowerCase()
                  .contains(query.toLowerCase()) ||
              patient['lastName'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _navigateToAddPatientScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPatientScreen(userId: widget.userId),
      ),
    );
    print("Returned from AddPatientScreen.");
    fetchPatients();
  }

  Future<void> _navigateToPatientDashboard(String patientKey) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDashboardScreen(
          userId: widget.userId,
          patientKey: patientKey,
        ),
      ),
    );
    print("Returned from PatientDashboardScreen.");
    fetchPatients();
  }

  void displayError(String errorToDisplay) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorToDisplay),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Building PatientManagementScreen...");
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Patients'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: 'Search patients',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: filterPatients,
            ),
          ),
          Expanded(
            child: false //isloading
                // ignore: dead_code
                ? const Center(child: CircularProgressIndicator())
                : filteredPatients.isEmpty
                    ? const Center(
                        child: Text(
                          'No patients found.',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredPatients.length,
                        itemBuilder: (context, index) {
                          final patient = filteredPatients[index];
                          return GestureDetector(
                            onTap: () =>
                                _navigateToPatientDashboard(patient['key']),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    child: Icon(
                                      patient['gender'] == 'Male'
                                          ? Icons.man
                                          : Icons.woman,
                                      color: patient['gender'] == 'Male'
                                          ? Colors.blue
                                          : Colors.pinkAccent,
                                    ),
                                  ),
                                  title: Text(
                                    '${patient['firstName']} ${patient['lastName']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Age: ${patient['age']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                ),
                                const Divider(),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPatientScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}
