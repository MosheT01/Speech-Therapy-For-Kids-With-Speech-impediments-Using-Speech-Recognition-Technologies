import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  // Singleton pattern implementation
  static final SpeechService _instance = SpeechService._internal();
  final stt.SpeechToText speech = stt.SpeechToText();

  // Callbacks for status and error
  Function(String)? onStatusCallback;
  Function(String)? onErrorCallback;

  factory SpeechService() {
    return _instance;
  }

  SpeechService._internal();

  Future<void> initialize() async {
    await speech.initialize(
      onStatus: (val) {
        print("Speech status: $val");
        if (onStatusCallback != null) {
          onStatusCallback!(val); // Trigger the status callback
        }
      },
      onError: (val) {
        print('Speech recognition error: $val');
        if (onErrorCallback != null) {
          onErrorCallback!(val.toString()); // Trigger the error callback
        }
      },
    );
  }

  bool get isAvailable => speech.isAvailable;

  // Methods to set the callbacks
  void setStatusCallback(Function(String) callback) {
    onStatusCallback = callback;
  }

  void setErrorCallback(Function(String) callback) {
    onErrorCallback = callback;
  }
}
