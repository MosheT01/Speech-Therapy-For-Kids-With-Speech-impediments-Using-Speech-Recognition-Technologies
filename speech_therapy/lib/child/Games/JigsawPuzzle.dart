import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(JigsawPuzzleApp());
}

class JigsawPuzzleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jigsaw Puzzle',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: JigsawPuzzle(),
    );
  }
}

class JigsawPuzzle extends StatefulWidget {
  @override
  _JigsawPuzzleState createState() => _JigsawPuzzleState();
}

class _JigsawPuzzleState extends State<JigsawPuzzle> {
  final int rows = 3;
  final int cols = 3;
  List<Widget> pieces = [];

  @override
  void initState() {
    super.initState();
    generatePuzzle();
  }

  void generatePuzzle() {
    List<Widget> tempPieces = [];
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        tempPieces.add(
          Draggable(
            data: '$i-$j',
            child: PuzzlePiece(
              key: Key('$i-$j'),
              imagePath: 'assets/therapist_treating_kid.png',
              row: i,
              col: j,
              rows: rows,
              cols: cols,
            ),
            feedback: PuzzlePiece(
              imagePath: 'assets/therapist_treating_kid.png',
              row: i,
              col: j,
              rows: rows,
              cols: cols,
            ),
            childWhenDragging: Container(),
          ),
        );
      }
    }
    tempPieces.shuffle(Random());
    setState(() {
      pieces = tempPieces;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jigsaw Puzzle'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: cols,
                children: pieces,
              ),
            ),
            ElevatedButton(
              onPressed: generatePuzzle,
              child: Text('Shuffle'),
            ),
          ],
        ),
      ),
    );
  }
}

class PuzzlePiece extends StatelessWidget {
  final String imagePath;
  final int row;
  final int col;
  final int rows;
  final int cols;

  const PuzzlePiece({
    Key? key,
    required this.imagePath,
    required this.row,
    required this.col,
    required this.rows,
    required this.cols,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          alignment: FractionalOffset(
            col / (cols - 1),
            row / (rows - 1),
          ),
        ),
      ),
    );
  }
}
