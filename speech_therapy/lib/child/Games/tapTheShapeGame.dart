import 'package:flutter/material.dart';
import 'dart:math';
import 'package:random_color/random_color.dart';

void main() {
  runApp(TapTheShapeGame());
}

class TapTheShapeGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap the Shape Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Random _random = Random();
  RandomColor _randomColor = RandomColor();
  int _score = 0;
  Offset _position = Offset(100, 100);
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
        title: Text('Tap the Shape Game'),
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
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
