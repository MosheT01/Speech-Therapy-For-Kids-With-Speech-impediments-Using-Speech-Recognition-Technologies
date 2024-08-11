import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speech_therapy/googleCloudAPIs/g2p_api.dart';
import 'package:speech_therapy/googleCloudAPIs/gemini_api.dart';
import 'package:speech_therapy/googleCloudAPIs/text_to_speech_api.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:audioplayers/audioplayers.dart';

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

class VideoPlaybackPage extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String therapistID;
  final String userId;
  final String videoKey;

  const VideoPlaybackPage({
    super.key,
    required this.videoUrl,
    required this.videoTitle,
    required this.therapistID,
    required this.userId,
    required this.videoKey,
  });

  @override
  _VideoPlaybackPageState createState() => _VideoPlaybackPageState();
}

class _VideoPlaybackPageState extends State<VideoPlaybackPage> {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;
  late stt.SpeechToText _speech;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isListening = false;
  bool _isLoading = true;
  String _recognizedText = '';
  bool _showCelebration = false;
  bool aboveSimilarityThreshhold = false;
  bool _useIPA = true; // Toggle for using IPA

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _initializeSpeechToText();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (kIsWeb) {
        // On the web, always use the network URL
        _controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else {
        // Attempt to cache the video first, then use the cached file
        final file =
            await CustomCacheManager.instance.getSingleFile(widget.videoUrl);

        if (file.existsSync()) {
          _controller = VideoPlayerController.file(file);
        } else {
          _controller =
              VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        }
      }

      // Initialize the video player
      await _controller.initialize();

      // Initialize Chewie controller
      _chewieController = ChewieController(
        videoPlayerController: _controller,
        aspectRatio: _controller.value.aspectRatio,
        autoPlay: true,
        looping: false,
      );

      // Update the state to stop loading and show the video player
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error loading video: $e');
    }
  }

  void _initializeSpeechToText() {
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    _speech.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    _recognizedText = '';
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'doneListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (val) {
          print('onError: $val');
          setState(() {
            _isListening = false;
          });
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            partialResults: false,
          ),
          onResult: (val) {
            setState(() {
              _recognizedText = val.recognizedWords;
            });
          },
          localeId: 'en_US',
        );
      }
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
    }
    if (_recognizedText.isNotEmpty) {
      await _evaluateSpeech(_recognizedText);
    }
  }

  Future<void> _evaluateSpeech(String recognizedText) async {
    String recognizedTextLower = recognizedText.toLowerCase();
    String videoTitleLower = widget.videoTitle.toLowerCase();

    String g2pExpected = videoTitleLower;
    String g2pRecognized = recognizedTextLower;

    if (_useIPA) {
      // G2P conversion
      g2pExpected = await G2PAPI().getIPA(videoTitleLower);
      g2pRecognized = await G2PAPI().getIPA(recognizedTextLower);

      // Use the original text if G2P conversion fails
      if (g2pExpected.isEmpty) g2pExpected = videoTitleLower;
      if (g2pRecognized.isEmpty) g2pRecognized = recognizedTextLower;
    }

    print('Expected: $g2pExpected');
    print('Recognized: $g2pRecognized');
    double similarity = _calculateSimilarity(g2pExpected, g2pRecognized);
    aboveSimilarityThreshhold = similarity >= 0.80;
    int grade = (similarity * 100).toInt();

    if (true) {
      _updateDatabase(true, grade);
      _showCelebrationAnimation();
      // Use Gemini and Text-to-Speech APIs
      String encouragement = await GeminiAPI().getEncouragement(
          "Your Job Is To Encourage A Child That Is Doing Speech Therapy Exercises,The Exercises Are Presented To The Child As Part Of A Game Once He Does This Exercise Close Enough He Can Continue To The Next Level, don't give too specific advice, Therapist Said: $videoTitleLower, Child Said: $recognizedTextLower, Grade By Therapist: $grade%");
      String audioContent =
          await TextToSpeechAPI().getSpeechAudio(encouragement);
      _playAudio(audioContent);
    } else {
      _updateDatabase(false, grade);
    }
  }

  Future<void> _playAudio(String audioContent) async {
    try {
      final bytes = base64Decode(audioContent);
      await _audioPlayer.play(BytesSource(bytes));
    } catch (e) {
      _showErrorDialog('Error playing audio: $e');
    }
  }

  double _calculateSimilarity(String s1, String s2) {
    int editDistance = _calculateEditDistance(s1, s2);
    double maxLen =
        s1.length > s2.length ? s1.length.toDouble() : s2.length.toDouble();
    double similarity = 1.0 - (editDistance / maxLen);
    print(similarity.toStringAsFixed(2));
    return similarity;
  }

  int _calculateEditDistance(String s1, String s2) {
    List<List<int>> dp =
        List.generate(s1.length + 1, (_) => List<int>.filled(s2.length + 1, 0));

    for (int i = 0; i <= s1.length; i++) {
      for (int j = 0; j <= s2.length; j++) {
        if (i == 0) {
          dp[i][j] = j;
        } else if (j == 0) {
          dp[i][j] = i;
        } else if (s1[i - 1] == s2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 + _min(dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]);
        }
      }
    }

    return dp[s1.length][s2.length];
  }

  int _min(int a, int b, int c) {
    return a < b ? (a < c ? a : c) : (b < c ? b : c);
  }

  void _updateDatabase(bool completed, int grade) {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref(
        'users/${widget.therapistID}/patients/${widget.userId}/videos/${widget.videoKey}');
    databaseReference.update({
      'status': completed ? 'childAttempted' : 'childDidNotAttempt',
      'grade': grade,
    }).catchError((error) {
      Fluttertoast.showToast(
          msg: "Failed to update database: $error",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
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

  void _showCelebrationAnimation() {
    setState(() {
      _showCelebration = true;
    });
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _showCelebration = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.videoTitle),
        actions: [
          Switch(
            value: _useIPA,
            onChanged: (value) {
              setState(() {
                _useIPA = value;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: Chewie(controller: _chewieController),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'What Did You Hear?',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      GestureDetector(
                        onTapDown: (_) => _startListening(),
                        onTapUp: (_) => _stopListening(),
                        child: FloatingActionButton(
                          onPressed:
                              () {}, // Required parameter, not used here.
                          child:
                              Icon(_isListening ? Icons.mic : Icons.mic_none),
                        ),
                      ),
                      if (_recognizedText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Recognized Text: $_recognizedText',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  aboveSimilarityThreshhold
                                      ? const Icon(Icons.check,
                                          color: Colors.green, size: 30)
                                      : const Icon(Icons.close,
                                          color: Colors.red, size: 30),
                                  const SizedBox(width: 10),
                                  Text(widget.videoTitle.toLowerCase(),
                                      style: const TextStyle(fontSize: 20)),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
          if (_showCelebration)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, color: Colors.green, size: 200),
                  Text('Congratulations!', style: TextStyle(fontSize: 24)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
