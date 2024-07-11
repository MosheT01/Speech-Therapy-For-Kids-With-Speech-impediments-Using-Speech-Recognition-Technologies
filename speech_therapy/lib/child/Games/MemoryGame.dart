import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import '../childExercise.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import '../childHomePage.dart'; // Import the ChildHomePage

class MemoryPairMatchingGame extends StatelessWidget {
  final String userId;

  MemoryPairMatchingGame({required this.userId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Pair Matching Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: GameScreen(userId: userId), // Pass userId to GameScreen
    );
  }
}

class GameScreen extends StatefulWidget {
  final String userId;

  GameScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<String> icons = [
    '🍎',
    '🍎',
    '🍌',
    '🍌',
    '🍇',
    '🍇',
    '🍓',
    '🍓',
    '🍉',
    '🍉',
    '🍒',
    '🍒',
  ];

  List<GlobalKey<FlipCardState>> cardStateKeys = [];
  List<bool> cardFlipped = [];
  int previousIndex = -1;
  bool flip = false;
  int moveCount = 0;
  int matchCount = 0;

  @override
  void initState() {
    super.initState();
    startNewGame();
  }

  void startNewGame() {
    setState(() {
      icons.shuffle();
      cardStateKeys = [];
      cardFlipped = [];
      moveCount = 0;
      matchCount = 0;
      previousIndex = -1;
      flip = false;
      for (int i = 0; i < icons.length; i++) {
        cardStateKeys.add(GlobalKey<FlipCardState>());
        cardFlipped.add(false);
      }
    });
  }

  Future<void> flipCard(int index) async {
    if (cardFlipped[index] || flip || previousIndex == index) return;

    setState(() {
      flip = true;
      cardStateKeys[index].currentState?.toggleCard();
      moveCount++;
    });

    if (previousIndex == -1) {
      previousIndex = index;
      setState(() {
        flip = false;
      });
    } else {
      if (icons[previousIndex] != icons[index]) {
        await Future.delayed(Duration(seconds: 1));
        setState(() {
          cardStateKeys[previousIndex].currentState?.toggleCard();
          cardStateKeys[index].currentState?.toggleCard();
          previousIndex = -1;
          flip = false;
        });
      } else {
        await Future.delayed(Duration(milliseconds: 300));
        final randomExercise = await fetchRandomExercise();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlaybackPage(
              videoUrl: randomExercise['downloadURL'] ?? '',
              videoTitle: randomExercise['word'] ?? 'No Title',
            ),
          ),
        ).then((_) {
          setState(() {
            cardFlipped[previousIndex] = true;
            cardFlipped[index] = true;
            matchCount++;
            previousIndex = -1;
            flip = false;
            if (cardFlipped.every((t) => t)) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Congratulations!'),
                    content: Text('You matched all the icons!'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          startNewGame();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          });
        });
      }
    }
  }

  Future<Map<String, dynamic>> fetchRandomExercise() async {
    final userId = widget.userId;
    final therapistId = await fetchTherapistIdFromChildId(userId);
    if (therapistId == null) {
      throw Exception("Therapist ID not found");
    }

    DatabaseReference ref = FirebaseDatabase.instance
        .ref("users")
        .child(therapistId)
        .child("patients")
        .child(userId)
        .child("videos");

    final dataSnapshot = await ref.once();
    final values = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

    if (values != null) {
      List<Map<String, dynamic>> videoList = [];
      values.forEach((key, value) {
        Map<String, dynamic> videoData =
            Map<String, dynamic>.from(value as Map);
        videoData['key'] = key; // Add the video key to the video data
        videoList.add(videoData);
      });

      // Select a random video from the list
      if (videoList.isNotEmpty) {
        final randomIndex =
            (videoList.length * (0.5 + 0.5 * Random().nextDouble())).toInt() %
                videoList.length;
        return videoList[randomIndex];
      }
    }

    throw Exception("No exercises found");
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    // Calculate card size to fit in a 4x3 grid
    double cardWidth = (screenWidth - 50) / 4; // 4 cards in a row with padding
    double cardHeight = (screenHeight - 200) / 3; // 3 rows with padding

    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Pair Matching Game'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: startNewGame,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Moves: $moveCount'),
                Text('Matches: $matchCount'),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10.0,
                  crossAxisSpacing: 10.0,
                  childAspectRatio: cardWidth / cardHeight,
                ),
                itemCount: icons.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      if (!flip) {
                        flipCard(index);
                      }
                    },
                    child: FlipCard(
                      key: cardStateKeys[index],
                      flipOnTouch: false,
                      direction: FlipDirection.HORIZONTAL,
                      front: Container(
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: Text(
                            '?',
                            style: TextStyle(
                              fontSize: 32.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      back: Container(
                        width: cardWidth,
                        height: cardHeight,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Center(
                          child: Text(
                            icons[index],
                            style: TextStyle(
                              fontSize: 32.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
