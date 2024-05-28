import 'package:flutter/material.dart';
import 'AddPatientScreen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'PatientDashboardScreen.dart';

class PatientManagementScreen extends StatefulWidget {
  final String userId;
  const PatientManagementScreen({super.key, required this.userId});

  @override
  _PatientManagementScreenState createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  void displayError(String errorToDisplay) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorToDisplay),
        backgroundColor: Colors.red,
      ),
    );
  }

  List<Map<String, dynamic>> patients = [];
  List<Map<String, dynamic>> filteredPatients = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    filteredPatients.clear();
    patients.clear();
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("users")
        .child(widget.userId)
        .child("patients");

    try {
      final dataSnapshot = await ref.once();
      final values = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        // Map patients including their keys
        values.forEach((key, value) {
          Map<String, dynamic> patientWithKey = Map.from(value);
          patientWithKey['key'] = key;
          patients.add(patientWithKey);
        });
        // Set filtered patients initially to all patients
        filteredPatients = patients;
        //filter the  patients
      }
    } catch (e) {
      displayError(
          'An error occurred while fetching the patient list from database. Please try again later.');
    } finally {
      setState(() {
        isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Patients'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
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
                  child: filteredPatients.isEmpty
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
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PatientDashboardScreen(
                                      userId: widget.userId,
                                      patientKey: filteredPatients[index]
                                          ['key'],
                                    ),
                                  ),
                                );

                                // Refresh the list
                                setState(() {
                                  isLoading = true;
                                });
                                await fetchPatients();
                                setState(() {
                                  isLoading = false;
                                });
                              },
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      //if patient is Male, display person icon with color blue, else display person icon with color pink
                                      child: Icon(
                                          filteredPatients[index]['gender'] ==
                                                  'Male'
                                              ? Icons.man
                                              : Icons.woman,
                                          color: filteredPatients[index]
                                                      ['gender'] ==
                                                  'Male'
                                              ? Colors.blue
                                              : Colors.pinkAccent),
                                    ),
                                    title: Text(
                                      '${filteredPatients[index]['firstName']} ${filteredPatients[index]['lastName']}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                        'Age: ${filteredPatients[index]['age']}'),
                                    trailing:
                                        const Icon(Icons.arrow_forward_ios),
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
        onPressed: () {
          // Navigate to add patient screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPatientScreen(userId: widget.userId),
            ),
          );
          fetchPatients();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
