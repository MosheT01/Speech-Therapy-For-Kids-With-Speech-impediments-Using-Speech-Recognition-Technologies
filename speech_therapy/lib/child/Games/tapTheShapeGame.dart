import 'package:flutter/material.dart';
import 'dart:math';
import 'package:random_color/random_color.dart';

void main() {
  runApp(const TapTheShapeGame());
}

class TapTheShapeGame extends StatelessWidget {
  const TapTheShapeGame({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap the Shape Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Random _random = Random();
  final RandomColor _randomColor = RandomColor();
  int _score = 0;
  Offset _position = const Offset(100, 100);
  Color _color = Colors.red;

  void _changePositionAndColor() {
    setState(() {
      _position =
          Offset(_random.nextDouble() * 300, _random.nextDouble() * 500);
      _color = _randomColor.randomColor();
      _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap the Shape Game'),
      ),
      body: Stack(
        children: <Widget>[
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: GestureDetector(
              onTap: _changePositionAndColor,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Score: $_score',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
