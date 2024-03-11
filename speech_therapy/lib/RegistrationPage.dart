import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'therapist_home_page.dart'; // Import the therapist homepage file

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  bool _isTherapist = false;
  bool _isParent = false;
  bool _isChild = false;

  void _register() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Registration successful, you can now navigate to another page or perform other actions.
      print('Registration successful: ${userCredential.user}');
      MaterialPageRoute(builder: (context) => TherapistHomePage());
    } catch (e) {
      // Registration failed, handle the error appropriately.
      print('Registration failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 20.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
              ),
            ),
            SizedBox(height: 20.0),
            CheckboxListTile(
              title: Text('Are you a therapist?'),
              value: _isTherapist,
              onChanged: (value) {
                setState(() {
                  _isTherapist = value!;
                  _isParent = false;
                  _isChild = false;
                });
              },
            ),
            CheckboxListTile(
              title: Text('Are you a parent?'),
              value: _isParent,
              onChanged: (value) {
                setState(() {
                  _isParent = value!;
                  _isTherapist = false;
                  _isChild = false;
                });
              },
            ),
            CheckboxListTile(
              title: Text('Are you a child?'),
              value: _isChild,
              onChanged: (value) {
                setState(() {
                  _isChild = value!;
                  _isTherapist = false;
                  _isParent = false;
                });
              },
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _register,
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
