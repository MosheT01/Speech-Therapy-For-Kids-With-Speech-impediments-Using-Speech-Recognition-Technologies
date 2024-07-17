import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_database/firebase_database.dart';
import 'package:fluttertoast/fluttertoast.dart';

class VideoPlaybackPage extends StatefulWidget {
  final String videoUrl;
  final String videoTitle;
  final String therapistID;
  final String userId;
  final String videoKey;

  VideoPlaybackPage({
    Key? key,
    required this.videoUrl,
    required this.videoTitle,
    required this.therapistID,
    required this.userId,
    required this.videoKey,
  }) : super(key: key);

  @override
  _VideoPlaybackPageState createState() => _VideoPlaybackPageState();
}

class _VideoPlaybackPageState extends State<VideoPlaybackPage> {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isLoading = true;
  String _recognizedText = '';
  bool _showCelebration = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _initializeSpeechToText();
  }

  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
        });
        _controller.play();
      }).catchError((error) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Error loading video: $error');
      });

    _chewieController = ChewieController(
      videoPlayerController: _controller,
      aspectRatio: _controller.value.aspectRatio,
      autoPlay: true,
      looping: false,
    );
  }

  void _initializeSpeechToText() {
    _speech = stt.SpeechToText();
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
          ),
          onResult: (val) => setState(() {
            _recognizedText = val.recognizedWords;
            double similarity = _calculateSimilarity();
            int grade = (similarity * 100).toInt();
            if (similarity >= 0.5) {
              // Update the database to mark the exercise as completed
              _updateDatabase(true, grade);
              _showCelebrationAnimation();
              Navigator.of(context).pop();
            } else {
              _updateDatabase(false, grade);
            }
          }),
          localeId: 'en_US',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _updateDatabase(bool completed, int grade) {
    DatabaseReference databaseReference = FirebaseDatabase.instance.ref(
        'users/${widget.therapistID}/patients/${widget.userId}/videos/${widget.videoKey}');
    databaseReference.update({
      'status': completed ? 'childAttempted' : 'childDidNotAttempt',
      'grade': grade,
    }).then((_) {
      Fluttertoast.showToast(
          msg: "Database updated successfully",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);
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
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              child: Text('OK'),
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
    Future.delayed(Duration(seconds: 3), () {
      setState(() {
        _showCelebration = false;
      });
    });
  }

  double _calculateSimilarity() {
    String recognizedTextLower = _recognizedText.toLowerCase();
    String videoTitleLower = widget.videoTitle.toLowerCase();

    int editDistance =
        _calculateEditDistance(recognizedTextLower, videoTitleLower);
    double maxLen = recognizedTextLower.length > videoTitleLower.length
        ? recognizedTextLower.length.toDouble()
        : videoTitleLower.length.toDouble();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.videoTitle),
      ),
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: Chewie(controller: _chewieController),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'What Did You Hear?',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      FloatingActionButton(
                        onPressed: _listen,
                        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      ),
                      if (_recognizedText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Recognized Text: $_recognizedText',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _calculateSimilarity() >= 0.5
                                      ? Icon(Icons.check,
                                          color: Colors.green, size: 30)
                                      : Icon(Icons.close,
                                          color: Colors.red, size: 30),
                                  SizedBox(width: 10),
                                  Text(widget.videoTitle.toLowerCase(),
                                      style: TextStyle(fontSize: 20)),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
          if (_showCelebration)
            Center(
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
