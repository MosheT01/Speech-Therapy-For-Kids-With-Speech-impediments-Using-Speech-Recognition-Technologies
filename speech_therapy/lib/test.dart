import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: RiveAnimationTestPage(),
    );
  }
}

class RiveAnimationTestPage extends StatefulWidget {
  const RiveAnimationTestPage({super.key});

  @override
  _RiveAnimationTestPageState createState() => _RiveAnimationTestPageState();
}

class _RiveAnimationTestPageState extends State<RiveAnimationTestPage> {
  SMIInput<bool>? _talkInput;
  SMIInput<bool>? _hearInput;
  SMIInput<bool>? _checkInput;
  SMIInput<double>? _lookInput;
  SMIInput<bool>? _successInput;
  SMIInput<bool>? _failInput;

  @override
  void initState() {
    super.initState();
  }

  void _onRiveInit(Artboard artboard) {
    final controller =
        StateMachineController.fromArtboard(artboard, 'State Machine 1');
    if (controller != null) {
      artboard.addController(controller);

      // Assign the inputs to their respective variables
      _talkInput = controller.findInput<bool>('Talk');
      _hearInput = controller.findInput<bool>('Hear');
      _checkInput = controller.findInput<bool>('Check');
      _lookInput = controller.findInput<double>('Look');
      _successInput = controller.findInput<bool>('success');
      _failInput = controller.findInput<bool>('fail');

      // Ensure that the animation starts in 'idle' state
      _resetInputs();
    }
  }

  void _resetInputs() {
    _talkInput?.value = false;
    _hearInput?.value = false;
    _checkInput?.value = false;
    _successInput?.value = false;
    _failInput?.value = false;
    _lookInput?.value = 0;
  }

  void _triggerState(String inputName) {
    setState(() {
      _resetInputs();

      switch (inputName) {
        case 'Talk':
          _talkInput?.value = true;
          break;
        case 'Hear':
          _hearInput?.value = true;
          break;
        case 'Check':
          _checkInput?.value = true;
          break;
        case 'success':
          _successInput?.value = true;
          break;
        case 'fail':
          _failInput?.value = true;
          break;
        case 'idle':
          _resetInputs(); // Reset everything to idle
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rive Animation Test'),
      ),
      body: Center(
        child: SizedBox(
          height: 300,
          width: 300,
          child: RiveAnimation.asset(
            'assets/wave-hear-and-talk.riv',
            onInit: _onRiveInit,
            fit: BoxFit.contain,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _triggerState('idle');
        },
        child: const Icon(Icons.play_arrow),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.record_voice_over),
              onPressed: () => _triggerState('Talk'),
            ),
            IconButton(
              icon: const Icon(Icons.hearing),
              onPressed: () => _triggerState('Hear'),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: () => _triggerState('Check'),
            ),
            IconButton(
              icon: const Icon(Icons.thumb_up),
              onPressed: () => _triggerState('success'),
            ),
            IconButton(
              icon: const Icon(Icons.thumb_down),
              onPressed: () => _triggerState('fail'),
            ),
          ],
        ),
      ),
    );
  }
}
