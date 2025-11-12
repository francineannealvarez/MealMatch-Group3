import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      // asset loc
      _controller = VideoPlayerController.asset(
        'assets/videos/greet_animation.mp4',
      );

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        await _controller.play();

        _controller.addListener(() {
          if (_controller.value.position >= _controller.value.duration) {
            _navigateToWelcome();
          }
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _navigateToWelcome();
      }
    }
  }

  void _navigateToWelcome() {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isVideoInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : CircularProgressIndicator(color: Color(0xFFF39321)),
      ),
    );
  }
}
