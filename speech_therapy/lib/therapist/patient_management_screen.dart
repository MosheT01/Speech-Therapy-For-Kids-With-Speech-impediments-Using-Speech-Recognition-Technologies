import 'package:flutter/material.dart';
import 'AddPatientScreen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'PatientDashboardScreen.dart';
//TODO fix the ininite loading after returning from dashboard on web

class PatientManagementScreen extends StatefulWidget {
  final String userId;
  const PatientManagementScreen({super.key, required this.userId});

  @override
  _PatientManagementScreenState createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  void displayError(String errorToDisplay) {
    print(errorToDisplay);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorToDisplay),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  bool isLoading = false;
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

    // Set up the listener for real-time updates
    patientsRef.onValue.listen((event) async {
      print("Real-time update detected.");
      await fetchPatients();
    });
  }

  Future<void> fetchPatients() async {
    print("Fetching patients...");

    setState(() {
      isLoading = true;
    });

    try {
      var dataSnapshot = await patientsRef.once();
      var values = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        print("Patients data fetched successfully.");
        // Map patients including their keys
        patients = values.entries.map((entry) {
          Map<String, dynamic> patientWithKey = Map.from(entry.value);
          patientWithKey['key'] = entry.key;
          return patientWithKey;
        }).toList();
        // Set filtered patients initially to all patients
        filteredPatients = List.from(patients);
      } else {
        print("No patients found.");
        patients = [];
        filteredPatients = [];
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
    setState(() {
      isLoading = false;
    });
    isLoading = false;
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
    await fetchPatients();
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
    await fetchPatients();
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
              onChanged: (value) {
                filterPatients(value);
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
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
                          return GestureDetector(
                            onTap: () async {
                              // Navigate to patient dashboard screen
                              await _navigateToPatientDashboard(
                                  filteredPatients[index]['key']);
                            },
                            child: Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    child: Icon(
                                      filteredPatients[index]['gender'] ==
                                              'Male'
                                          ? Icons.man
                                          : Icons.woman,
                                      color: filteredPatients[index]
                                                  ['gender'] ==
                                              'Male'
                                          ? Colors.blue
                                          : Colors.pinkAccent,
                                    ),
                                  ),
                                  title: Text(
                                    '${filteredPatients[index]['firstName']} ${filteredPatients[index]['lastName']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    'Age: ${filteredPatients[index]['age']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                ),
                                const Divider(), // Add divider
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to add patient screen
          await _navigateToAddPatientScreen();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
