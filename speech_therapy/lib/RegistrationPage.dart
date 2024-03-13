import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'therapist/therapist_home_page.dart'; // Import the therapist homepage file

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _verifyPasswordController =
      TextEditingController();

  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: _currentStep == 3 ?  _buildRegistrationForm():_buildStepper(),
    );
  }

  Widget _buildStepper() {
    return Stepper(
      currentStep: _currentStep,
      onStepContinue: () {
        if (_currentStep == 3) {
          return;
        } else {
          setState(() {
            _currentStep += 1;
          });
        }
      },
      onStepCancel: () {
        if (_currentStep > 0) {
          setState(() {
            _currentStep -= 1;
          });
        }
      },
      steps: [
        Step(
          title: const Text('Enter Email'),
          content: Column(
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
            ],
          ),
          isActive: _currentStep >= 0,
          state: _currentStep >= 0 ? StepState.complete : StepState.disabled,
        ),
        Step(
          title: const Text('Enter Password'),
          content: Column(
            children: [
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
            ],
          ),
          isActive: _currentStep >= 1,
          state: _currentStep >= 1 ? StepState.complete : StepState.disabled,
        ),
        Step(
          title: const Text('Verify Password'),
          content: Column(
            children: [
              TextField(
                controller: _verifyPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Verify Password',
                ),
              ),
            ],
          ),
          isActive: _currentStep >= 2,
          state: _currentStep >= 2 ? StepState.complete : StepState.disabled,
        ),
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email: ${_emailController.text}'),
          const SizedBox(height: 10.0),
          Text('Password: ${_passwordController.text}'),
          const SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: _register,
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  void _register() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Registration successful, navigate to the therapist homepage
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
            errorMessage =
                'An error occurred while registering: ${e.message}';
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
}
