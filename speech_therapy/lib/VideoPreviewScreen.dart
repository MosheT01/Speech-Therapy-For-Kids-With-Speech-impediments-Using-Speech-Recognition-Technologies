import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String? videoUrl;
  final String? filePath;

  const VideoPreviewScreen({super.key, this.videoUrl, this.filePath});

  @override
  _VideoPreviewScreenState createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    if (kIsWeb && widget.videoUrl != null) {
      // On the web, prefer the video URL if available
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
    } else if (!kIsWeb && widget.filePath != null) {
      // On mobile or desktop, prefer the file if available
      _videoPlayerController =
          VideoPlayerController.file(File(widget.filePath!));
    } else if (widget.videoUrl != null) {
      // Fallback to video URL if file is not available
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
    }

    // Initialize the video player
    await _videoPlayerController.initialize();

    // Initialize Chewie controller
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
    );

    // Update the state to stop loading and show the video player
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Chewie(controller: _chewieController!),
    );
  }
}
