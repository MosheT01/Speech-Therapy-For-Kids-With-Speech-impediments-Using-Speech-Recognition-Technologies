import 'package:flutter/material.dart';


class SpeechRecPrototype extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio Recorder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Audio Recorder'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // First Section
          Container(
            color: Colors.grey[300],
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Logic for recording audio
                  },
                  child: Text('Record Audio'),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    // Logic for adding audio files from system
                  },
                  child: Text('Add Audio from System'),
                ),
              ],
            ),
          ),
          // Second Section
          Container(
            color: Colors.grey[400],
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Logic for recording audio
                  },
                  child: Text('Record Audio'),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () {
                    // Logic for adding audio files from system
                  },
                  child: Text('Add Audio from System'),
                ),
              ],
            ),
          ),
          // Third Section
          Expanded(
            child: Container(
              color: Colors.grey[500],
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Spectrogram',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  // Logic to display spectrogram from recordings
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
