import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

bool _isLoading = false;

Future<bool> addPatientToDataBase({
  required String therapistId,
  required String email,
  required String firstName,
  required String lastName,
  required int age,
  required String gender,
}) async {
  try {
    DatabaseReference ref = FirebaseDatabase.instance.ref("users");

    DataSnapshot dataSnapshot =
        (await ref.orderByChild('email').equalTo(email).once()).snapshot;
    Map<dynamic, dynamic>? users = dataSnapshot.value as Map<dynamic, dynamic>?;

    if (users != null && users.isNotEmpty) {
      String userId = users.keys.first;
      await ref
          .child(userId)
          .update({'hasTherapist': true, 'therapistId': therapistId});

      DatabaseReference patientsRef =
          FirebaseDatabase.instance.ref("users/$therapistId/patients");
      await patientsRef.child(userId).set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'gender': gender,
      });

      return true;
    } else {
      print("User with email $email not found.");
      return false;
    }
  } catch (e) {
    print("Error adding patient data: $e");
    return false;
  }
}

class AddPatientScreen extends StatefulWidget {
  final String userId;
  const AddPatientScreen({super.key, required this.userId});

  @override
  _AddPatientScreenState createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  int _currentStep = 0;
  final _formKeyEmail = GlobalKey<FormState>();
  final _formKeyPersonal = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _ageController;
  late String _selectedGender;
  late TextEditingController _emailController;

  void displayError(String errorToDisplay) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorToDisplay),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<bool> emailIsInUseAndDoesntHaveTherapist(String email) async {
    DatabaseReference databaseReference =
        FirebaseDatabase.instance.ref().child('users');

    DataSnapshot dataSnapshot;
    try {
      dataSnapshot =
          await databaseReference.once().then((snapshot) => snapshot.snapshot);
    } catch (e) {
      return false;
    }

    Map<dynamic, dynamic>? values =
        dataSnapshot.value as Map<dynamic, dynamic>?;

    if (values != null) {
      var userWithGivenEmail = values.values
          .firstWhere((value) => value['email'] == email, orElse: () => null);
      if (userWithGivenEmail == null) {
        displayError("No Child With Email $email is Registered.");
        return false;
      }
      if (userWithGivenEmail != null) {
        if (userWithGivenEmail['hasTherapist'] == false &&
            userWithGivenEmail['isTherapist'] == false) {
          return true;
        } else if (userWithGivenEmail['hasTherapist'] == true) {
          displayError("User with email $email already has a therapist.");
          return false;
        } else if (userWithGivenEmail['isTherapist'] == true) {
          displayError("User with email $email is a therapist.");
          return false;
        }
      }
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _ageController = TextEditingController();
    _emailController = TextEditingController();
    _selectedGender = 'Male';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Patient'),
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () async {
          if (_isLoading) {
            return;
          }
          setState(() {
            _isLoading = true;
          });

          if (_currentStep == 0) {
            if (_formKeyEmail.currentState!.validate()) {
              bool isInUse = await emailIsInUseAndDoesntHaveTherapist(
                  _emailController.text);
              if (isInUse) {
                setState(() {
                  _currentStep += 1;
                });
              }
            }
          } else if (_currentStep == 1) {
            if (_formKeyPersonal.currentState!.validate()) {
              setState(() {
                _currentStep += 1;
              });
            }
          } else if (_currentStep < 2) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            bool success = await addPatientToDataBase(
              therapistId: widget.userId,
              email: _emailController.text,
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
              age: int.tryParse(_ageController.text) ?? 0,
              gender: _selectedGender,
            );
            if (success) {
              Navigator.pop(context);
            } else {
              displayError("Failed to add patient data. Please try again.");
            }
          }

          setState(() {
            _isLoading = false;
          });
        },
        onStepCancel: () {
          setState(() {
            if (_currentStep > 0) {
              _currentStep -= 1;
            } else {
              _currentStep = 0;
            }
          });
        },
        steps: <Step>[
          Step(
            title: const Text("Email Of The Patient"),
            content: Form(
              key: _formKeyEmail,
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: "name@mail.com",
                ),
                validator: (value) {
                  final RegExp emailRegex =
                      RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$');
                  if (value == null ||
                      value.isEmpty ||
                      !emailRegex.hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
            ),
            isActive: _currentStep == 0,
          ),
          Step(
            title: const Text('Personal Information'),
            content: Form(
              key: _formKeyPersonal,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid first name';
                      } else if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                        return 'Names Cant Contain Numbers or Special Characters';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a valid last name';
                      } else if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
                        return 'Names Cant Contain Numbers or Special Characters';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _ageController,
                    decoration: const InputDecoration(labelText: 'Age'),
                    keyboardType: TextInputType.number,
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
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    onChanged: (newValue) {
                      setState(() {
                        _selectedGender = newValue!;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                    ),
                    items: <String>['Male', 'Female']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            isActive: _currentStep == 1,
          ),
          Step(
            title: const Text('Confirmation'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Email: ${_emailController.text}'),
                Text('First Name: ${_firstNameController.text}'),
                Text('Last Name: ${_lastNameController.text}'),
                Text('Age: ${_ageController.text}'),
                Text('Gender: $_selectedGender'),
              ],
            ),
            isActive: _currentStep == 2,
          ),
        ],
      ),
    );
  }
}
