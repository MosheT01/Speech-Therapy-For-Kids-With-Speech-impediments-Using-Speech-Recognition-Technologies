import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

//TODO register thhe child in backend...1)make has therapist=true2)make therapist have the child as a patient
bool _isLoading = false;

Future<bool> emailIsInUseAndDoesntHaveTherapist(String email) async {
  DatabaseReference databaseReference =
      FirebaseDatabase.instance.ref().child('users');

  DataSnapshot dataSnapshot;
  try {
    dataSnapshot =
        await databaseReference.once().then((snapshot) => snapshot.snapshot);
  } catch (e) {
    return false; // Assuming no error means the email is not in use
  }

  Map<dynamic, dynamic>? values = dataSnapshot.value as Map<dynamic, dynamic>?;

  if (values != null) {
    // Check if any user has the provided email
    var userWithGivenEmail = values.values
        .firstWhere((value) => value['email'] == email, orElse: () => null);
    if (userWithGivenEmail != null) {
      if (userWithGivenEmail['hasTherapist'] == false &&
          userWithGivenEmail['isTherapist'] == false) {
        return true;
      } else {
        return false;
      }
    }
  }

  // User with the provided email does not exist or has no therapist
  return false;
}

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

    // Find the user with the provided email
    DataSnapshot dataSnapshot =
        (await ref.orderByChild('email').equalTo(email).once()).snapshot;
    Map<dynamic, dynamic>? users = dataSnapshot.value as Map<dynamic, dynamic>?;

    if (users != null && users.isNotEmpty) {
      String userId =
          users.keys.first; // Assuming email is unique, get the first user's ID
      // Update the user's data to set hasTherapist to true
      await ref.child(userId).update({'hasTherapist': true});

      // Add the patient's data under the therapist's patients
      DatabaseReference patientsRef =
          FirebaseDatabase.instance.ref("users/$therapistId/patients");
      await patientsRef.push().set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'gender': gender,
      });

      return true; // Successfully added patient data
    } else {
      print("User with email $email not found.");
      return false; // User not found
    }
  } catch (e) {
    print("Error adding patient data: $e");
    return false; // Failed to add patient data
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

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _ageController = TextEditingController();
    _emailController = TextEditingController();
    _selectedGender = 'Male'; // Set initial value to 'Male'
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
            bool isInUse =
                await emailIsInUseAndDoesntHaveTherapist(_emailController.text);
            if (!isInUse) {
              displayError(
                  "Either No Child Is Registered To This Email! Or The Child Is Registered To Another Therapist!\nMake Them Register First.");
            } else {
              setState(() {
                _currentStep += 1;
              });
            }
          } else if (_currentStep == 1) {
            if (_firstNameController.text.isEmpty ||
                _lastNameController.text.isEmpty ||
                _ageController.text.isEmpty ||
                _selectedGender.isEmpty) {
              displayError(
                  "Some Of The Feilds Are Empty!\nPlease Fill The Whole Form!");
            } else if (int.tryParse(_ageController.text) == null ||
                int.tryParse(_ageController.text)! < 1 ||
                int.tryParse(_ageController.text)! > 150) {
              displayError("Age Should Be Between 1 And 150.");
            } else {
              setState(() {
                _currentStep += 1;
              });
            }
          } else if (_currentStep < 2) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            // Handle submission of patient data
            bool success = await addPatientToDataBase(
              therapistId: widget.userId,
              email: _emailController.text,
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
              age: int.tryParse(_ageController.text) ?? 0,
              gender: _selectedGender,
            );
            if (success) {
              // Patient data added successfully, navigate back
              Navigator.pop(context);
            } else {
              // Error adding patient data, display error message
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
            content: TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: "name@mail.com",
              ),
            ),
            isActive: _currentStep == 0,
          ),
          Step(
            title: const Text('Personal Information'),
            content: Column(
              children: <Widget>[
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
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
