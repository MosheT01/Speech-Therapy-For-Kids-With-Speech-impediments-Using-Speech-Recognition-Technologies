import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:speech_therapy/googleCloudAPIs/gemini_chat_api.dart';
import 'package:speech_therapy/googleCloudAPIs/text_to_speech_api.dart';
import 'package:speech_therapy/speech_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart'; // To generate unique session IDs

class GeminiChatPage extends StatefulWidget {
  const GeminiChatPage({
    super.key,
  });

  @override
  _GeminiChatPageState createState() => _GeminiChatPageState();
}

class _GeminiChatPageState extends State<GeminiChatPage>
    with SingleTickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final stt.SpeechToText _speech =
      SpeechService().speech; // Access the singleton
  late RiveAnimationController _riveController;
  SMIInput<bool>? _talkInput;
  SMIInput<bool>? _hearInput;
  SMIInput<bool>? _idleInput;
  bool _isListening = false;
  bool _isPlaying = false; // Manage the state of the animation
  late AnimationController _micAnimationController;
  late Animation<double> _micAnimation;
  String _recognizedText = '';
  final String _sessionId = const Uuid().v4(); // Generate a unique session ID

  @override
  void initState() {
    super.initState();
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

    SpeechService().setStatusCallback((status) {
      print("Status: $status");
      if ((status.contains('done') || status.contains('notListening'))) {
        _stopListening();
      }
    });

    SpeechService().setErrorCallback((error) {
      print("Error: $error");
      _stopListening();
    });
  }

  void _onRiveInit(Artboard artboard) {
    final controller =
        StateMachineController.fromArtboard(artboard, 'State Machine 1');
    if (controller != null) {
      artboard.addController(controller);
      _talkInput = controller.findInput<bool>('Talk');
      _hearInput = controller.findInput<bool>('Hear');
      _idleInput = controller.findInput<bool>('idle');
    }
  }

  void _triggerRiveState(String state) {
    _resetRiveInputs(); // Reset all inputs before setting a new one

    switch (state) {
      case 'Talk':
        _talkInput?.value = true;
        break;
      case 'Hear':
        _hearInput?.value = true;
        break;
      case 'idle':
        _idleInput?.value = true;
        break;
    }

    _riveController.isActive = false; // Deactivate to reset the state machine
    _riveController.isActive = true; // Reactivate to start the new state
  }

  void _resetRiveInputs() {
    _talkInput?.value = false;
    _hearInput?.value = false;
    _idleInput?.value = false;
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!_speech.isAvailable || _isPlaying) {
      print("Cannot start listening.");
      return;
    }

    setState(() => _isListening = true);
    _triggerRiveState('Hear');
    _micAnimationController.forward();
    _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
      ),
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

      if (_recognizedText.isNotEmpty) {
        await _sendMessage(_recognizedText);
        setState(() {
          _recognizedText = '';
        });
      }
    }
  }

  Future<void> _sendMessage(String message) async {
    setState(() {
      _isPlaying = true;
    });

    try {
      String response =
          await GeminiChatAPI().getChatResponse(message, _sessionId);

      // Play the response using Text-to-Speech
      await _playAudio(response);
    } catch (e) {
      print("Error: ${e.toString()}");
    } finally {
      setState(() {
        _isPlaying = false;
      });
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

      _audioPlayer.onPlayerComplete.listen((event) {
        setState(() {
          _triggerRiveState('idle'); // Reset Rive state to 'idle' after audio
        });
        completer.complete();
      });

      await _audioPlayer.play(BytesSource(bytes));
      await completer.future;

      // After Gemini's speech is done, start listening again
      setState(() {
        _isPlaying = false;
      });
      const Duration delay = Duration(seconds: 1);
      await Future.delayed(delay);
      _startListening();
    } catch (e) {
      print('Error playing audio: $e');
      setState(() {
        _triggerRiveState('idle');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat With Gemini'),
      ),
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      flex: 5, // Adjust flex as needed
                      child: SizedBox(
                        width: double.infinity,
                        child: RiveAnimation.asset(
                          'assets/wave,_hear_and_talk.riv',
                          controllers: [_riveController],
                          fit: BoxFit.contain,
                          onInit: _onRiveInit,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      flex: 1,
                      child: _recognizedText.isEmpty
                          ? const Text(
                              'Chat With Gemini',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Padding(
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
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _toggleListening,
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
                          const SizedBox(width: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _micAnimationController.dispose();
    _speech.stop();
    _audioPlayer.dispose();
    super.dispose();
  }
}
