import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import '../childExercise.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../childHomePage.dart'; // Import the ChildHomePage

class CustomCacheManager {
  static final CacheManager _cacheManager = CacheManager(
    Config(
      'customCacheKey',
      stalePeriod: const Duration(days: 30), // Cache duration
      maxNrOfCacheObjects: 100, // Max number of objects to cache
    ),
  );

  static CacheManager get instance => _cacheManager;
}

class MemoryPairMatchingGame extends StatelessWidget {
  final String userId;

  const MemoryPairMatchingGame({super.key, required this.userId});

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

  const GameScreen({super.key, required this.userId});

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
  List<Map<String, dynamic>> _videoList = []; // Store fetched videos

  @override
  void initState() {
    super.initState();
    startNewGame();
    _fetchAndCacheVideos(); // Start fetching and caching videos in the background
  }

  Future<void> _fetchAndCacheVideos() async {
    try {
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
        for (var entry in values.entries) {
          Map<String, dynamic> videoData =
              Map<String, dynamic>.from(entry.value as Map);
          videoData['key'] = entry.key;
          videoList.add(videoData);

          // Cache the video in the background if not on web
          if (!kIsWeb) {
            String? videoUrl = videoData['downloadURL'];
            if (videoUrl != null) {
              CustomCacheManager.instance
                  .downloadFile(videoUrl)
                  .catchError((e) {
                print('Error caching video: $e');
              });
            }
          }
        }

        setState(() {
          _videoList = videoList;
        });
      } else {
        throw Exception("No exercises found");
      }
    } catch (e) {
      //_showErrorDialog(
      // 'fetching videos: $e/n/Your Therapist Hasnt Uploaded Any Videos Yet');
    }
  }

  void startNewGame() {
    setState(() {
      // Reset game state variables
      previousIndex = -1;
      flip = false;
      moveCount = 0;
      matchCount = 0;

      // Shuffle the icons and reset the card states
      icons.shuffle();
      cardStateKeys =
          List.generate(icons.length, (_) => GlobalKey<FlipCardState>());
      cardFlipped = List.generate(icons.length, (_) => false);
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
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          cardStateKeys[previousIndex].currentState?.toggleCard();
          cardStateKeys[index].currentState?.toggleCard();
          previousIndex = -1;
          flip = false;
        });
      } else {
        await Future.delayed(const Duration(milliseconds: 300));

        if (_videoList.isNotEmpty) {
          final randomExercise = _getRandomExercise();
          final therapistId =
              await fetchTherapistIdFromChildId(widget.userId) as String;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  _navigateToVideoPlayback(randomExercise, therapistId),
            ),
          ).then((_) {
            setState(() {
              cardFlipped[previousIndex] = true;
              cardFlipped[index] = true;
              matchCount++;
              previousIndex = -1;
              flip = false;
              if (cardFlipped.every((t) => t)) {
                _showCompletionDialog();
              }
            });
          });
        } else {
          // No videos to navigate to, continue the game
          setState(() {
            cardFlipped[previousIndex] = true;
            cardFlipped[index] = true;
            matchCount++;
            previousIndex = -1;
            flip = false;
            if (cardFlipped.every((t) => t)) {
              _showCompletionDialog();
            }
          });
        }
      }
    }
  }

  Widget _navigateToVideoPlayback(
      Map<String, dynamic> exercise, String therapistId) {
    String? videoUrl = exercise['downloadURL'];
    String videoTitle = exercise['word'] ?? 'No Title';
    String videoKey = exercise['key'] ?? 'No Key';

    if (kIsWeb) {
      // On the web, always use the network URL
      return VideoPlaybackPage(
        videoUrl: videoUrl!,
        videoTitle: videoTitle,
        therapistID: therapistId,
        userId: widget.userId,
        videoKey: videoKey,
      );
    } else {
      // On mobile/desktop, attempt to use the cached video
      return FutureBuilder<FileInfo?>(
        future: CustomCacheManager.instance.getFileFromCache(videoUrl!),
        builder: (context, snapshot) {
          String filePath = snapshot.data?.file.path ?? '';
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData &&
              filePath.isNotEmpty) {
            return VideoPlaybackPage(
              videoUrl: filePath,
              videoTitle: videoTitle,
              therapistID: therapistId,
              userId: widget.userId,
              videoKey: videoKey,
            );
          } else {
            return VideoPlaybackPage(
              videoUrl: videoUrl,
              videoTitle: videoTitle,
              therapistID: therapistId,
              userId: widget.userId,
              videoKey: videoKey,
            );
          }
        },
      );
    }
  }

  Map<String, dynamic> _getRandomExercise() {
    if (_videoList.isNotEmpty) {
      final randomIndex = Random().nextInt(_videoList.length);
      return _videoList[randomIndex];
    } else {
      throw Exception("No exercises available");
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Congratulations!'),
          content: const Text('You matched all the icons!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                startNewGame();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('No Videos Yet!'),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
        title: const Text('Memory Pair Matching Game'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                        child: const Center(
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
                            style: const TextStyle(
                              fontSize: 45,
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
