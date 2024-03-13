import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'therapist/therapist_home_page.dart'; // Import the therapist homepage file

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController verifyPasswordController =
      TextEditingController();
  final DatabaseReference _userRef =
      FirebaseDatabase.instance.ref().child('users');

  int currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: currentStep == 3 ? buildRegistrationForm() : buildStepper(),
    );
  }

  Widget buildStepper() {
    return Stepper(
      currentStep: currentStep,
      onStepContinue: () async {
        if (currentStep == 3) {
          return;
        } else if (currentStep == 0) {
          bool emailUsed = await emailIsInUse(emailController.text);
          if (emailUsed) {
            displayError(
                "This Email Is Already Registered,try reseting the password!");
          } else {
            setState(() {
              currentStep += 1;
            });
          }
        } else if (currentStep == 1) {
          if (isStrongPassword(passwordController.text)) {
            setState(() {
              currentStep += 1;
            });
          }
        } else if (currentStep == 2 &&
            passwordController.text != verifyPasswordController.text) {
          displayError("The Two Passwords Must Match!");
        } else {
          setState(() {
            currentStep += 1;
          });
        }
      },
      onStepCancel: () {
        if (currentStep > 0) {
          setState(() {
            currentStep -= 1;
          });
        }
      },
      steps: [
        Step(
          title: const Text('Enter Email'),
          content: Column(
            children: [
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                    labelText: 'Email', hintText: "example@email.com"),
              ),
            ],
          ),
          isActive: currentStep >= 0,
          state: currentStep >= 0 ? StepState.complete : StepState.disabled,
        ),
        Step(
          title: const Text('Enter Password'),
          content: Column(
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
            ],
          ),
          isActive: currentStep >= 1,
          state: currentStep >= 1 ? StepState.complete : StepState.disabled,
        ),
        Step(
          title: const Text('Verify Password'),
          content: Column(
            children: [
              TextField(
                controller: verifyPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Verify Password',
                ),
              ),
            ],
          ),
          isActive: currentStep >= 2,
          state: currentStep >= 2 ? StepState.complete : StepState.disabled,
        ),
      ],
    );
  }

  Widget buildRegistrationForm() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Register?',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Email: ${emailController.text}'),
                const SizedBox(height: 10.0),
                Text('Password: ${passwordController.text}'),
                const SizedBox(height: 20.0),
                Center(
                  child: ElevatedButton(
                    onPressed: register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Click To Register!'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void register() async {
    String email = emailController.text;
    String password = passwordController.text;

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Registration successful, navigate to the therapist homepage
      String userId = userCredential.user!.uid; // Get the user ID

      // Save user email along with user ID to the database
      _userRef.child(userId).set({'email': email});
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => TherapistHomePage()),
      );
    } catch (e) {
      // Registration failed, handle the error appropriately.
      String errorMessage = 'Registration failed';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'email-already-in-use':
            errorMessage = 'The email address is already in use.';
            break;
          case 'weak-password':
            errorMessage = 'The password provided is too weak.';
            break;
          default:
            errorMessage = 'An error occurred while registering: ${e.message}';
            break;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool isStrongPassword(String password) {
    // Check if the password meets the minimum length requirement
    if (password.length < 6) {
      displayError("Password Should Be At Leaset 6 Characters Long!");
      return false;
    }

    // Check if the password contains at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      displayError("Password should contain at least one uppercase letter!");
      return false;
    }

    // Check if the password contains at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      displayError("Password should contain at least one lowercase letter!");
      return false;
    }

    // Check if the password contains at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) {
      displayError("Password should contain at least one number digit!");
      return false;
    }

    // Check if the password contains at least one special character
    //if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {return false;}

    // If all conditions pass, then the password is strong
    return true;
  }

  void displayError(String errorToDisplay) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorToDisplay),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<bool> emailIsInUse(String email) async {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref().child('users');

    DataSnapshot dataSnapshot;
    try {
      dataSnapshot =
          await databaseReference.once().then((snapshot) => snapshot.snapshot);
    } catch (e) {
      return false; // Assuming no error means the email is not in use
    }

    Map<dynamic, dynamic>? values =
        dataSnapshot.value as Map<dynamic, dynamic>?;

    if (values != null) {
      return values.values.any((value) => value['email'] == email);
    } else {
      return false;
    }
  }
}
