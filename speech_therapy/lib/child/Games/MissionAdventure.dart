import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';

void main() {
  runApp(MemoryPairMatchingGame());
}

class MemoryPairMatchingGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Memory Pair Matching Game',
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

  void flipCard(int index) {
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
        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            cardStateKeys[previousIndex].currentState?.toggleCard();
            cardStateKeys[index].currentState?.toggleCard();
            previousIndex = -1;
            flip = false;
          });
        });
      } else {
        Future.delayed(Duration(milliseconds: 300), () {
          showDialog(
            context: context,
            barrierDismissible: false, // Disable dismissing by tapping outside
            builder: (context) {
              return AlertDialog(
                title: Text('Say the icon name: ${icons[index]}'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      setState(() {
                        cardFlipped[previousIndex] = true;
                        cardFlipped[index] = true;
                        matchCount++;
                        previousIndex = -1;
                        flip = false;
                        if (cardFlipped.every((t) => t)) {
                          showDialog(
                            context: context,
                            barrierDismissible:
                                false, // Disable dismissing by tapping outside
                            builder: (context) {
                              return AlertDialog(
                                title: Text('Congratulations!'),
                                content: Text('You matched all the icons!'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      });
                    },
                    child: Text('I said it!'),
                  ),
                ],
              );
            },
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Pair Matching Game'),
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
                  childAspectRatio:
                      0.75, // Adjusted aspect ratio to make cards taller
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
