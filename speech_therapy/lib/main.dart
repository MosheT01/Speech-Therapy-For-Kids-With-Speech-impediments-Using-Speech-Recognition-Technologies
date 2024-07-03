import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:speech_therapy/child/childHomePage.dart';
import 'ResetPasswordPage.dart';
import 'therapist/therapist_home_page.dart'; // Import the therapist homepage file
import 'registrationPage.dart'; // Import the registration page file
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

bool _isLoading = false;

void main() async {
  // Ensure Firebase initialization completes before running the app
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  //
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech Therapy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Added for password visibility toggle

  void displayError(String errorToDisplay) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorToDisplay),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<Object?> isUserTherapist(String uid) async {
    try {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('users/$uid/isTherapist');
      DataSnapshot isTherapistSnapshot = (await userRef.once()).snapshot;
      Object? isTherapist = isTherapistSnapshot.value;
      return isTherapist;
    } catch (e) {
      return null;
    }
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _usernameController.text,
        password: _passwordController.text,
      );

      // If login is successful, navigate to the relevant user homepage
      // Extract user ID
      String userId = userCredential.user!.uid;
      Object? isTherapist = await isUserTherapist(userCredential.user!.uid);
      if (isTherapist != null && isTherapist == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => TherapistHomePage(userId: userId)),
        );
      } else if (isTherapist != null && isTherapist == false) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => ChildHomePage(userId: userId)),
        );
      } else {
        displayError("Something Went Wrong While Loging In");
      }
    } catch (e) {
      // Handle login failure here
      if (e is FirebaseAuthException) {
        displayError("Incorrect Email Or Password!");
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToRegistration() {
    // Navigate to the registration page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrationPage()),
    );
  }

  void _navigateToResetPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResetPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'example@mail.com', // Add preview text here
              ),
            ),
            const SizedBox(height: 20.0),
            TextField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible, // Toggle the obscuring of text
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            ElevatedButton(
              onPressed:
                  _isLoading ? null : _login, // Disable button when loading,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
            const SizedBox(height: 10.0), // Add some spacing
            GestureDetector(
              onTap: _navigateToRegistration,
              child: const Text.rich(
                TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(
                    color: Colors.black, // Change the color of the regular text
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: "Register Here!",
                      style: TextStyle(
                        color: Colors.blue, // Change the color of the blue link
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: _navigateToResetPassword,
              child: const Text.rich(
                TextSpan(
                  text: "Forgot your password? ",
                  style: TextStyle(
                    color: Colors.black, // Change the color of the regular text
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: "Reset it here!",
                      style: TextStyle(
                        color: Colors.blue, // Change the color of the blue link
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
