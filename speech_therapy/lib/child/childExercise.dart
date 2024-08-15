import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import 'package:rive/rive.dart';
import 'package:flutter/material.dart';
import 'package:speech_therapy/googleCloudAPIs/g2p_api.dart';
import 'package:speech_therapy/googleCloudAPIs/gemini_api.dart';
import 'package:speech_therapy/googleCloudAPIs/text_to_speech_api.dart';
import 'package:speech_therapy/speech_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';
//TODO  if the child fails more than four time we nav out(remeber to udatae database on last attempt)

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

class Attempt {
  final String recognizedWord;
  final double grade;
  final bool success;

  Attempt({
    required this.recognizedWord,
    required this.grade,
    required this.success,
  });

  Map<String, dynamic> toJson() {
    return {
      'recognizedWord': recognizedWord,
      'grade': grade,
      'success': success,
    };
  }

  static Attempt fromJson(Map<String, dynamic> json) {
    return Attempt(
      recognizedWord: json['recognizedWord'] as String,
      grade: json['grade'] as double,
      success: json['success'] as bool,
    );
  }
}

class _VideoPlaybackPageState extends State<VideoPlaybackPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isListening = false;
  bool _isLoading = true;
  bool _isPlaying = false;
  String _recognizedText = '';
  bool _showCelebration = false;
  bool aboveSimilarityThreshhold = false;
  bool _useIPA = true;
  bool micToggle = false;
  late AnimationController _micAnimationController;
  late Animation<double> _micAnimation;
  late RiveAnimationController _riveController;
  SMIInput<bool>? _talkInput;
  SMIInput<bool>? _hearInput;
  SMIInput<bool>? _checkInput;
  SMIInput<bool>? _successInput;
  SMIInput<bool>? _failInput;
  late Map<String, dynamic> patientData;
  final stt.SpeechToText _speech =
      SpeechService().speech; // Access the singleton

  // Use the current timestamp as the session ID
  String sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  DateTime startTime = DateTime.now();

  List<Attempt> _attempts = [];

  late List<String> encouragementMessages;

  num similarityThreshhold = 0.80;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    fetchPatientData();
    _riveController = SimpleAnimation('idle'); // Initial animation state
    _micAnimationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _micAnimation =
        Tween<double>(begin: 1, end: 1.25).animate(_micAnimationController)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              _micAnimationController.reverse();
            } else if (status == AnimationStatus.dismissed) {
              _micAnimationController.forward();
            }
          });
    // Set the status and error callbacks
    SpeechService().setStatusCallback((status) {
      print("Status: $status");
      if ((status.contains('done') || status.contains('notListening')) &&
          _recognizedText.isEmpty) {
        return;
      }
      if ((status.contains('done') ||
          (status.contains('notListening')) && _recognizedText.isEmpty)) {
        _stopListening();
      }
    });

    SpeechService().setErrorCallback((error) {
      print("Error: $error");
      _stopListening();
    });
  }

  Future<void> _updateExerciseStatus(String status) async {
    DatabaseReference videoRef = FirebaseDatabase.instance.ref(
        'users/${widget.therapistID}/patients/${widget.userId}/videos/${widget.videoKey}');

    await videoRef.update({
      'status': status,
    }).catchError((error) {
      Fluttertoast.showToast(
        msg: "Failed to update video status: $error",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    });
  }

  void _onRiveInit(Artboard artboard) {
    final controller =
        StateMachineController.fromArtboard(artboard, 'State Machine 1');
    if (controller != null) {
      artboard.addController(controller);
      _talkInput = controller.findInput<bool>('Talk');
      _hearInput = controller.findInput<bool>('Hear');
      _checkInput = controller.findInput<bool>('Check');
      _successInput = controller.findInput<bool>('success');
      _failInput = controller.findInput<bool>('fail');
    }
  }

  void _triggerRiveState(String state) {
    _resetRiveInputs(); // Reset all inputs before setting a new one

    // Set the appropriate input to trigger the state change
    switch (state) {
      case 'Talk':
        _talkInput?.value = true;
        break;
      case 'Hear':
        _hearInput?.value = true;
        break;
      case 'success':
        _successInput?.value = true;
        break;
      case 'fail':
        _failInput?.value = true;
        break;
      default:
        // No need to deactivate/reactivate the controller unnecessarily
        _riveController.isActive = true; // Default to 'idle'
    }

    // Immediately trigger the state by forcing an update
    _riveController.isActive = false; // Deactivate to reset the state machine
    _riveController.isActive = true; // Reactivate to start the new state
  }

  void _resetRiveInputs() {
    _talkInput?.value = false;
    _hearInput?.value = false;
    _checkInput?.value = false;
    _successInput?.value = false;
    _failInput?.value = false;
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (kIsWeb) {
        _controller =
            VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else {
        final file =
            await CustomCacheManager.instance.getSingleFile(widget.videoUrl);

        if (file.existsSync()) {
          _controller = VideoPlayerController.file(file);
        } else {
          _controller =
              VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        }
      }

      await _controller.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _controller,
        autoPlay: true,
        looping: false,
        allowPlaybackSpeedChanging:
            !_isListening, // Disable controls when mic is active
        allowFullScreen: !_isListening,
        showControls: !_isListening,
        allowMuting: false,
      );

      setState(() {
        _isLoading = false;
      });

      // Listen to the video playing state
      _controller.addListener(() {
        setState(() {
          _isPlaying = _controller.value.isPlaying;
          if (_isPlaying && _isListening) {
            _stopListening();
          }
        });
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Error loading video: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    _speech.stop();
    _audioPlayer.dispose();
    _micAnimationController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isPlaying) {
      return;
    }
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (_isPlaying || !_speech.isAvailable) {
      print("Cannot start listening.");
      return;
    }

    setState(() => _isListening = true);
    _triggerRiveState('Hear');
    _micAnimationController.forward();
    _chewieController.setVolume(0);
    _controller.pause();
    _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
      ),
      pauseFor: kIsWeb ? Duration(seconds: 2) : null,
      onResult: (val) {
        setState(() {
          _recognizedText = val.recognizedWords;
        });
      },
      localeId: 'en_US',
    );
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _triggerRiveState('idle');
      });
      _micAnimationController.stop();
      _chewieController.setVolume(1);
      if (_recognizedText.isNotEmpty) {
        await _evaluateSpeech(_recognizedText);
        setState(() {
          _recognizedText = '';
        });
      }
    }
  }

  Future<void> fetchPatientData() async {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref("users")
        .child(widget.therapistID)
        .child("patients")
        .child(widget.userId);

    try {
      final dataSnapshot = await ref.once();
      final value = dataSnapshot.snapshot.value as Map<dynamic, dynamic>?;

      if (value != null) {
        setState(() {
          patientData = Map<String, dynamic>.from(value);
        });
      }
    } catch (e) {
      debugPrint('Error fetching patient data: $e');
    }
    encouragementMessages = [
      "Great work, ${patientData['firstName']}!",
      "Well done, ${patientData['firstName']}!",
      "You nailed it, ${patientData['firstName']}!",
      "Awesome job, ${patientData['firstName']}!",
      "Fantastic, ${patientData['firstName']}!",
      "You're amazing, ${patientData['firstName']}!",
      "Keep it up, ${patientData['firstName']}!",
      "You're a star, ${patientData['firstName']}!",
      "Brilliant, ${patientData['firstName']}!",
      "Superb effort, ${patientData['firstName']}!",
      "You did it, ${patientData['firstName']}!",
      "Excellent, ${patientData['firstName']}!",
      "You're unstoppable, ${patientData['firstName']}!",
      "Impressive, ${patientData['firstName']}!",
      "Outstanding, ${patientData['firstName']}!",
      "You're doing great, ${patientData['firstName']}!",
      "Way to go, ${patientData['firstName']}!",
      "You're a champ, ${patientData['firstName']}!",
      "You rock, ${patientData['firstName']}!",
      "Great job, ${patientData['firstName']}!"
    ];
  }

  Future<void> _evaluateSpeech(String recognizedText) async {
    setState(() {
      _isPlaying = true;
    });

    String recognizedTextLower = recognizedText.toLowerCase();
    String videoTitleLower = widget.videoTitle.toLowerCase();

    String g2pExpected = videoTitleLower;
    String g2pRecognized = recognizedTextLower;

    if (_useIPA && !recognizedTextLower.contains(videoTitleLower)) {
      g2pExpected = await G2PAPI().getIPA(videoTitleLower);
      g2pRecognized = await G2PAPI().getIPA(recognizedTextLower);

      if (g2pExpected.isEmpty) g2pExpected = videoTitleLower;
      if (g2pRecognized.isEmpty) g2pRecognized = recognizedTextLower;
    }

    double similarity = _calculateSimilarity(g2pExpected, g2pRecognized);
    aboveSimilarityThreshhold = similarity >= similarityThreshhold;

    int grade = (similarity * 100).toInt();
    if (recognizedTextLower.contains(videoTitleLower)) {
      aboveSimilarityThreshhold = true;
      grade = 95;
    }

    _attempts.add(Attempt(
      recognizedWord: recognizedText,
      grade: grade.toDouble(),
      success: aboveSimilarityThreshhold,
    ));

    // If this attempt is successful, calculate session metrics and save
    if (aboveSimilarityThreshhold) {
      _playCelebrationAnimation();
      await _playFeedbackSound('win.wav', success: true);
      // Choose a random string from encouragementMessages array
      String randomEncouragement =
          encouragementMessages[Random().nextInt(encouragementMessages.length)];
      await Future.delayed(Duration(seconds: 1));
      await _playAudio(randomEncouragement);
      await _updateOverallGradeAndSessionMetrics(widget.videoKey, "success");
      Navigator.pop(context);
    } else if (_attempts.length >= 3) {
      await _playFeedbackSound('lose.wav', success: false);
      String encouragement = "It's okay! You can get it next time!";
      await _playAudio(encouragement);
      _updateOverallGradeAndSessionMetrics(widget.videoKey, "failed");
      Navigator.pop(context);
    } else {
      await _playFeedbackSound('lose.wav', success: false);
      try {
        String encouragement = await GeminiAPI().getEncouragement(
            "Therapist Said: '$videoTitleLower' , Child Said: '$recognizedTextLower' , Grade By Therapist: '$grade%', success(exercise passed we go to the next level):'$aboveSimilarityThreshhold', child name: ${patientData['firstName']}");
        await _playAudio(
          encouragement,
        );
        print('Encouragement: $encouragement');
      } catch (e) {
        print("error in gemini api $e");
        String errorMessage = "Try again, I didn't catch that.";
        await _playAudio(errorMessage);
      }
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _playCelebrationAnimation() async {
    // Play celebration animation using Lottie
    setState(() {
      _showCelebration = true;
    });
    // Play the celebration sound
    await _audioPlayer.play(AssetSource('woo-hoo.mp3'));

    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _showCelebration = false;
    });
  }

  Future<void> _playFeedbackSound(String soundFilePath,
      {required bool success}) async {
    try {
      await Future.delayed(Duration(milliseconds: 1500));
      setState(() {
        _triggerRiveState(
            success ? 'success' : 'fail'); // Trigger success or fail state
      });
      _audioPlayer.play(AssetSource(soundFilePath));
    } catch (e) {
      _showErrorDialog('Error playing sound: $e');
    }
  }

  Future<void> _playAudio(String text) async {
    try {
      String audioContent = await TextToSpeechAPI().getSpeechAudio(text);
      final bytes = base64Decode(audioContent);
      setState(() {
        _triggerRiveState('Talk'); // Trigger Rive state to 'Talk'
      });

      final completer = Completer<void>();

      // Listen for the completion of the audio
      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _triggerRiveState('idle'); // Reset Rive state to 'idle' after audio
        });
        completer.complete(); // Complete the future
      });

      await _audioPlayer.play(BytesSource(bytes));
      await completer.future; // Wait until the audio is finished playing
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
        _triggerRiveState('idle'); // Reset Rive state to 'idle' on error
      });
    }
  }

  double _calculateSimilarity(String s1, String s2) {
    int editDistance = _calculateEditDistance(s1, s2);
    double maxLen =
        s1.length > s2.length ? s1.length.toDouble() : s2.length.toDouble();
    double similarity = 1.0 - (editDistance / maxLen);
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

  Future<void> _updateOverallGradeAndSessionMetrics(
      String videoId, String status) async {
    try {
      // Calculate the average grade for the current session
      int sessionTotalGrade =
          _attempts.fold(0, (sum, attempt) => sum + attempt.grade.toInt());
      int sessionAverageGrade =
          _attempts.isNotEmpty ? sessionTotalGrade ~/ _attempts.length : 0;

      // Calculate the session duration (time spent on the video playback page)
      int sessionTimeSpent = _totalTimeSpent.inSeconds;

      // Update session metrics in Firebase
      DatabaseReference sessionRef = FirebaseDatabase.instance.ref(
          'users/${widget.therapistID}/patients/${widget.userId}/videos/$videoId/sessions/$sessionId');

      final sessionMetrics = {
        'attempts': _attempts.map((attempt) => attempt.toJson()).toList(),
        'successfulAttempts':
            _attempts.where((attempt) => attempt.success).length,
        'totalAttempts': _attempts.length,
        'timeSpentInSession': sessionTimeSpent,
        'status': status,
        'sessionAverageGrade': sessionAverageGrade,
      };

      await sessionRef.set(sessionMetrics);

      // Update the overall video stats (including overall grade and average session time)
      int overallGrade = await _calculateAndUpdateOverallGrade(videoId);
      int overallSessionTime = await _calculateAverageSessionTime(videoId);

      // Determine the overall video status
      String overallStatus = overallGrade >= (50) ? 'success' : 'failed';

      // Update the overall video status and grade in Firebase
      DatabaseReference videoRef = FirebaseDatabase.instance.ref(
          'users/${widget.therapistID}/patients/${widget.userId}/videos/$videoId');

      await videoRef.update({
        'status': overallStatus,
        'overallGrade': overallGrade,
        'averageSessionTime': overallSessionTime,
      });
    } catch (e) {
      print('Error updating session metrics: $e');
      Fluttertoast.showToast(
        msg: "Failed to update database: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  Future<int> _calculateAndUpdateOverallGrade(String videoId) async {
    try {
      int totalGrade = 0;
      int totalAttemptCount = 0;

      DatabaseReference sessionsRef = FirebaseDatabase.instance.ref(
          'users/${widget.therapistID}/patients/${widget.userId}/videos/$videoId/sessions');

      DataSnapshot snapshot = await sessionsRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> sessions =
            snapshot.value as Map<dynamic, dynamic>;

        for (var sessionData in sessions.values) {
          if (sessionData['attempts'] != null) {
            List<dynamic> attempts = sessionData['attempts'];
            for (var attempt in attempts) {
              int attemptGrade = (attempt['grade'] ?? 0).toInt();
              totalGrade += attemptGrade;
              totalAttemptCount++;
            }
          }
        }
      }

      int overallGrade =
          totalAttemptCount > 0 ? totalGrade ~/ totalAttemptCount : 0;

      // Update the overall grade in Firebase
      DatabaseReference videoRef = FirebaseDatabase.instance.ref(
          'users/${widget.therapistID}/patients/${widget.userId}/videos/$videoId');

      await videoRef.update({
        'overallGrade': overallGrade,
      });

      return overallGrade;
    } catch (e) {
      print('Error calculating overall grade: $e');
      Fluttertoast.showToast(
        msg: "Failed to calculate overall grade: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return 0;
    }
  }

  Duration get _totalTimeSpent => DateTime.now().difference(startTime);
  Future<int> _calculateAverageSessionTime(String videoId) async {
    try {
      int totalTimeSpent = 0;
      int sessionCount = 0;

      DatabaseReference sessionsRef = FirebaseDatabase.instance.ref(
          'users/${widget.therapistID}/patients/${widget.userId}/videos/$videoId/sessions');

      DataSnapshot snapshot = await sessionsRef.get();

      if (snapshot.exists) {
        Map<dynamic, dynamic> sessions =
            snapshot.value as Map<dynamic, dynamic>;

        for (var sessionData in sessions.values) {
          int sessionTime = sessionData['timeSpentInSession'] ?? 0;
          totalTimeSpent += sessionTime;
          sessionCount++;
        }
      }

      return sessionCount > 0 ? totalTimeSpent ~/ sessionCount : 0;
    } catch (e) {
      print('Error calculating average session time: $e');
      return 0;
    }
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Video player expands to fill available space
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: Chewie(controller: _chewieController!),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'What Did You Hear?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (_recognizedText.isEmpty)
                            const Text(
                              'Please speak into the microphone to start the exercise',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          if (_recognizedText.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                _recognizedText,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          // This row should adapt and space evenly
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: GestureDetector(
                                  onTap: _isPlaying ? null : _toggleListening,
                                  child: ScaleTransition(
                                    scale: _micAnimation,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isPlaying
                                            ? Colors.grey
                                            : _isListening
                                                ? Colors.redAccent
                                                : Colors.blue,
                                      ),
                                      child: Icon(
                                        _isListening
                                            ? Icons.mic
                                            : Icons.mic_none,
                                        color: Colors.white,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(
                                  width:
                                      20), // Add space between the mic and animation
                              Flexible(
                                child: SizedBox(
                                  height: 100, // Adjust the size dynamically
                                  width: 100,
                                  child: RiveAnimation.asset(
                                    'assets/wave,_hear_and_talk.riv',
                                    controllers: [_riveController],
                                    fit: BoxFit.contain,
                                    onInit: _onRiveInit,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
                if (_showCelebration)
                  Center(
                    child: Lottie.asset(
                      'assets/celebration.json',
                      width: 1000,
                      height: 1000,
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
    );
  }
}
