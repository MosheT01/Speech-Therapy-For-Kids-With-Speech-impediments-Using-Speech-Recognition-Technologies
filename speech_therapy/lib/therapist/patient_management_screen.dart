import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'AddPatientScreen.dart';
import 'PatientDashboardScreen.dart';

class PatientManagementScreen extends StatefulWidget {
  final String userId;

  const PatientManagementScreen({super.key, required this.userId});

  @override
  _PatientManagementScreenState createState() =>
      _PatientManagementScreenState();
}

class _PatientManagementScreenState extends State<PatientManagementScreen> {
  late DatabaseReference _patientsRef;
  late StreamSubscription<DatabaseEvent> _patientsSubscription;
  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _filteredPatients = [];
  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _patientsRef = FirebaseDatabase.instance
        .ref("users")
        .child(widget.userId)
        .child("patients");

    _initData();
  }

  @override
  void dispose() {
    _patientsSubscription.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _initData() {
    // Listen to changes in the database and update the state accordingly
    _patientsSubscription = _patientsRef.onValue.listen(
      (event) {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          _updatePatientList(data);
        } else {
          setState(() {
            _patients = [];
            _filteredPatients = [];
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        debugPrint("Error fetching patients: $error");
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      },
    );
  }

  void _updatePatientList(Map<dynamic, dynamic> data) {
    final List<Map<String, dynamic>> patients = data.entries.map((entry) {
      return Map<String, dynamic>.from(entry.value)
        ..putIfAbsent('key', () => entry.key);
    }).toList();

    setState(() {
      _patients = patients;
      _filteredPatients = patients;
      _isLoading = false;
      _hasError = false;
    });
  }

  void _filterPatients(String query) {
    final filtered = _patients.where((patient) {
      final fullName =
          '${patient['firstName']} ${patient['lastName']}'.toLowerCase();
      return fullName.contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredPatients = filtered;
    });
  }

  Future<void> _navigateToAddPatientScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPatientScreen(userId: widget.userId),
      ),
    );

    if (result == true) {
      // Re-fetch data if a new patient was added
      _initData();
    }
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Patients'),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildPatientList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPatientScreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          labelText: 'Search patients',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: _filterPatients,
      ),
    );
  }

  Widget _buildPatientList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return const Center(child: Text('An error occurred. Please try again.'));
    }

    if (_filteredPatients.isEmpty) {
      return const Center(
        child: Text(
          'No patients found.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = _filteredPatients[index];
        return GestureDetector(
          onTap: () => _navigateToPatientDashboard(patient['key']),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey,
                  child: Icon(
                    patient['gender'] == 'Male' ? Icons.man : Icons.woman,
                    color: patient['gender'] == 'Male'
                        ? Colors.blue
                        : Colors.pinkAccent,
                  ),
                ),
                title: Text(
                  '${patient['firstName']} ${patient['lastName']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
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
    );
  }
}
