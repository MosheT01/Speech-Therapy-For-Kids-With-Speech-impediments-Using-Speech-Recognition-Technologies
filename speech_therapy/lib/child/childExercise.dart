import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart';
import 'package:flutter/material.dart';
import 'package:speech_therapy/googleCloudAPIs/g2p_api.dart';
import 'package:speech_therapy/googleCloudAPIs/gemini_api.dart';
import 'package:speech_therapy/googleCloudAPIs/text_to_speech_api.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:fluttertoast/fluttertoast.dart';

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

class _VideoPlaybackPageState extends State<VideoPlaybackPage>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;
  late stt.SpeechToText _speech;
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

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
    _initializeSpeechToText();
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
    _resetRiveInputs();
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
        _riveController.isActive = true; // Default to 'idle'
    }
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

  void _initializeSpeechToText() {
    _speech = stt.SpeechToText();
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
    if (_isPlaying) {
      return;
    }
    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          _toggleListening();
        }
        print(val);
      },
      onError: (val) {
        print('onError: $val');
        setState(() {
          _toggleListening();
        });
      },
    );

    if (available) {
      setState(() => _isListening = true);
      _triggerRiveState('Hear'); // Trigger Rive state to 'Hear'
      _micAnimationController.forward();
      _chewieController.setVolume(0); // Mute the video while listening
      _controller.pause(); // Pause the video while listening
      _speech.listen(
        listenOptions: stt.SpeechListenOptions(partialResults: true),
        onResult: (val) {
          setState(() {
            _recognizedText = val.recognizedWords;
          });
        },
        localeId: 'en_US',
      );
    }
  }

  Future<void> _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _triggerRiveState('idle'); // Reset Rive state to 'idle'
      });
      _micAnimationController.stop();
      _chewieController.setVolume(1); // Unmute the video when done listening
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
  }

  Future<void> _evaluateSpeech(String recognizedText) async {
    setState(() {
      _isPlaying = true;
    });
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

    _updateDatabase(true, grade);

    // Play corresponding sound based on similarity threshold
    if (aboveSimilarityThreshhold) {
      await _playFeedbackSound('win.wav', success: true);
    } else {
      await _playFeedbackSound('lose.wav', success: false);
    }

    // Use Gemini and Text-to-Speech APIs
    try {
      String encouragement = await GeminiAPI().getEncouragement(
          "Therapist Said: '$videoTitleLower' , Child Said: '$recognizedTextLower' , Grade By Therapist: '$grade%', success:'$aboveSimilarityThreshhold', child name: ${patientData['firstName']}");
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

  Future<void> _playFeedbackSound(String soundFilePath,
      {required bool success}) async {
    try {
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
          : Column(
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
                                    _isListening ? Icons.mic : Icons.mic_none,
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
    );
  }
}
