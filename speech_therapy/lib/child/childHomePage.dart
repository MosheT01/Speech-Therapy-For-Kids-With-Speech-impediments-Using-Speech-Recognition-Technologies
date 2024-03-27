import 'package:flutter/material.dart';

class ChildHomePage extends StatelessWidget {
  final String userId;

  const ChildHomePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Child Home Page'),
      ),
      body: const Center(
        child: Text(
          'Welcome to the Child Home Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
