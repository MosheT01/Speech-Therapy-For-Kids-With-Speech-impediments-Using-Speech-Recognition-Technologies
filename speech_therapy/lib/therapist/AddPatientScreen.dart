import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

//TODO: ADD VALIDATION OF SECOND STEP FEILDS

//TODO register thhe child in backend...1)make has therapist=true2)make therapist have the child as a patient

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

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

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
          if (_currentStep == 0) {
            bool isInUse =
                await emailIsInUseAndDoesntHaveTherapist(_emailController.text);
            if (!isInUse) {
              displayError(
                  "No Child Is Registered To This Email!\nMake Them Register First.");
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
            } else if (_ageController.text.contains(RegExp(r'[A-Z]'))) {//TODO: Continue the validation process for step 2 
              displayError("age Should Only Contain Positive Numbers!");
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
            // For example, you can call a function here to save the patient details
            // This is where you would handle form submission or confirmation
            // For now, let's just navigate back to the previous screen
            Navigator.pop(context);
          }
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
