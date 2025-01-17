import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

bool _isLoading = false;

Future<bool> emailIsInUse(String email) async {
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
    return values.values.any((value) => value['email'] == email);
  } else {
    return false;
  }
}

Future<bool> validateTherapistCode(String code) async {
  try {
    DatabaseReference therapistCodesRef =
        FirebaseDatabase.instance.ref('therapistCode');
    DataSnapshot therapistCodesSnapshot =
        (await therapistCodesRef.once()).snapshot;
    Object? therapistCode = therapistCodesSnapshot.value;

    // If snapshot or therapistCode is null, or if code doesn't match, return false
    if (therapistCodesSnapshot.value == null ||
        therapistCode == null ||
        therapistCode != int.tryParse(code)) {
      return false;
    } else {
      return true; // Therapist code is valid
    }
  } catch (e) {
    return false; // Error occurred, code is not valid
  }
}

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController verifyPasswordController =
      TextEditingController();
  final TextEditingController therapistCodeController = TextEditingController();
  final DatabaseReference _userRef =
      FirebaseDatabase.instance.ref().child('users');
  // ignore: unused_field
  final DatabaseReference _therapistCodeRef =
      FirebaseDatabase.instance.ref().child('therapist_codes');

  int currentStep = 0;
  bool _isTherapist = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: currentStep == 5 ? buildRegistrationForm() : buildStepper(),
    );
  }

  Widget buildStepper() {
    return Stepper(
      currentStep: currentStep,
      onStepContinue: () async {
        if (_isLoading) {
          return;
        }
        setState(() {
          _isLoading = true;
        });

        if (currentStep == 0) {
          bool emailUsed = await emailIsInUse(emailController.text);
          final RegExp emailRegex = RegExp(r'^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$');
          if (emailUsed) {
            displayError(
                "This Email Is Already Registered,try resetting the password!");
          } else if (emailController.text == '' ||
              emailRegex.hasMatch(emailController.text) == false) {
            displayError("Enter A Valid Email!\nEmail Should Be All Lower-Case!");
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
        } else if (currentStep == 2) {
          if (passwordController.text != verifyPasswordController.text) {
            displayError("The Two Passwords Must Match!");
          } else {
            setState(() {
              currentStep += 1;
            });
          }
        } else if (currentStep == 3) {
          if (_isTherapist) {
            setState(() {
              currentStep += 1;
            });
          }
          if (!_isTherapist) {
            setState(() {
              currentStep += 2;
            });
          }
        } else if (currentStep == 4) {
          // Check if the user is a therapist and handle the step accordingly
          if (_isTherapist) {
            bool isValidCode =
                await validateTherapistCode(therapistCodeController.text);
            if (!isValidCode) {
              displayError("Invalid therapist code!");
              return;
            }
            if (isValidCode) {
              setState(() {
                currentStep += 1;
              });
            }
          } else {
            setState(() {
              currentStep += 1;
            });
          }
        }
        setState(() {
          _isLoading = false;
        });
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
        Step(
          title: const Text('Are you a therapist?'),
          content: Column(
            children: [
              CheckboxListTile(
                title: const Text('Yes'),
                value: _isTherapist,
                onChanged: (value) {
                  setState(() {
                    _isTherapist = value!;
                  });
                },
              ),
            ],
          ),
          isActive: currentStep >= 3,
          state: currentStep >= 3 ? StepState.complete : StepState.disabled,
        ),
        Step(
          title: const Text('Enter Therapist Code'),
          content: Column(
            children: [
              TextField(
                controller: therapistCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Therapist Code',
                ),
              ),
            ],
          ),
          isActive: currentStep >= 4,
          state: currentStep >= 4 ? StepState.complete : StepState.disabled,
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
                const Text(
                  'Register?',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Email: ${emailController.text}'),
                const SizedBox(height: 10.0),
                Text('Password: ${passwordController.text}'),
                if (_isTherapist)
                  Text('Therapist Code: ${therapistCodeController.text}'),
                const SizedBox(height: 20.0),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentStep = 3;
                        });
                      },
                      child: const Text('Back'),
                    ),
                    const SizedBox(height: 10.0),
                    ElevatedButton(
                      onPressed: _isLoading ? null : () => register(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator() // Show loading indicator if isLoading is true
                          : const Text('Click To Register!'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void register() async {
    setState(() {
      _isLoading = true;
    });

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
      _userRef.child(userId).set(
          {'email': email, 'isTherapist': _isTherapist, 'hasTherapist': false});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email Registered! Please Login!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
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
      displayError(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool isStrongPassword(String password) {
    // Check if the password meets the minimum length requirement
    if (password.length < 6) {
      displayError("Password Should Be At Least 6 Characters Long!");
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
}
