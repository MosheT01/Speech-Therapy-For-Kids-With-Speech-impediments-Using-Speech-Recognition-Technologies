import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'main.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: ResetPasswordForm(),
    );
  }
}

class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({Key? key}) : super(key: key);

  @override
  _ResetPasswordFormState createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('You Will Get An Email Message To Reset Your Link!',
              style: TextStyle(fontSize: 16)),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
            ),
          ),
          const SizedBox(height: 20.0),
          ElevatedButton(
            onPressed: _sendPasswordResetEmail,
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Password reset email sent successfully,check your email!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Navigate back to the previous page
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reset email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
