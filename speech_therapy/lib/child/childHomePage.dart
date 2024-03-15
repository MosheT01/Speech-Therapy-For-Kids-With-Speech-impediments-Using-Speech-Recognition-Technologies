import 'package:flutter/material.dart';

class ChildHomePage extends StatelessWidget {
  const ChildHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Child Home Page'),
      ),
      body: Center(
        child: Text(
          'Welcome to the Child Home Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
