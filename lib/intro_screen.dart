/// Theta Audio MVP - Intro Screen (ANDROID PRODUCTION)
/// 
/// VIDEO SEQUENCE:
/// 1. Play intro_video.mov (full duration)
/// 2. Play instruction_vid.mp4 (full duration)
/// 3. Fade to white overlay (800ms)
/// 4. Navigate to main app with fade transition (4000ms)
///
/// FEATURES:
/// - No skip functionality (users must watch entire videos)
/// - Subtle spinner only during load
/// - Black background to prevent white flash
/// - Smooth fade transitions

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'main.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  // Video 1: Intro video
  VideoPlayerController? _introVideoController;
  ChewieController? _introChewieController;
  
  // Video 2: Instruction video
  VideoPlayerController? _instructionVideoController;
  ChewieController? _instructionChewieController;
  
  // State tracking
  bool _isIntroInitialized = false;
  bool _isInstructionInitialized = false;
  bool _showingIntro = true;
  bool _showingInstruction = false;
  bool _hasNavigated = false;
  
  // Fade animation
  double _fadeOverlay = 0.0;
  bool _showFadeOverlay = false;

  @override
  void initState() {
    super.initState();
    _initializeIntroVideo();
  }

  /// Initialize intro video (Video 1)
  Future<void> _initializeIntroVideo() async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🎬 THETA INTRO SCREEN - INITIALIZING VIDEO 1 (INTRO)');
      debugPrint('═══════════════════════════════════════════════════════');
      
      _introVideoController = VideoPlayerController.asset(
        'assets/video/intro_video.mov',
      );
      
      debugPrint('📹 Loading intro_video.mov from assets...');
      
      await _introVideoController!.initialize();
      
      debugPrint('✅ Intro video initialized');
      debugPrint('   Duration: ${_introVideoController!.value.duration.inSeconds} seconds');
      
      _introChewieController = ChewieController(
        videoPlayerController: _introVideoController!,
        autoPlay: true,
        looping: false,
        showControls: false,
        allowFullScreen: false,
        allowMuting: false,
        allowPlaybackSpeedChanging: false,
        showOptions: false,
      );
      
      setState(() {
        _isIntroInitialized = true;
      });
      
      await _introVideoController!.play();
      debugPrint('▶️ Intro video playing...');
      
      // Listen for intro video completion
      _introVideoController!.addListener(_checkIntroProgress);
      
      // Pre-load instruction video while intro plays
      _preloadInstructionVideo();
      
    } catch (e, stack) {
      debugPrint('❌ ERROR LOADING INTRO VIDEO: $e');
      debugPrint('Stack: $stack');
      // Skip to instruction video or main app
      _initializeInstructionVideo();
    }
  }
  
  /// Pre-load instruction video while intro plays
  Future<void> _preloadInstructionVideo() async {
    try {
      debugPrint('📹 Pre-loading instruction_vid.mp4...');
      
      _instructionVideoController = VideoPlayerController.asset(
        'assets/video/instruction_vid.mp4',
      );
      
      await _instructionVideoController!.initialize();
      
      _instructionChewieController = ChewieController(
        videoPlayerController: _instructionVideoController!,
        autoPlay: false, // Will start manually after intro
        looping: false,
        showControls: false,
        allowFullScreen: false,
        allowMuting: false,
        allowPlaybackSpeedChanging: false,
        showOptions: false,
      );
      
      setState(() {
        _isInstructionInitialized = true;
      });
      
      debugPrint('✅ Instruction video pre-loaded');
      debugPrint('   Duration: ${_instructionVideoController!.value.duration.inSeconds} seconds');
      
    } catch (e) {
      debugPrint('⚠️ Could not pre-load instruction video: $e');
    }
  }
  
  /// Initialize instruction video if not pre-loaded
  Future<void> _initializeInstructionVideo() async {
    if (_isInstructionInitialized) {
      _startInstructionVideo();
      return;
    }
    
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🎬 THETA INTRO SCREEN - INITIALIZING VIDEO 2 (INSTRUCTION)');
      debugPrint('═══════════════════════════════════════════════════════');
      
      _instructionVideoController = VideoPlayerController.asset(
        'assets/video/instruction_vid.mp4',
      );
      
      await _instructionVideoController!.initialize();
      
      _instructionChewieController = ChewieController(
        videoPlayerController: _instructionVideoController!,
        autoPlay: true,
        looping: false,
        showControls: false,
        allowFullScreen: false,
        allowMuting: false,
        allowPlaybackSpeedChanging: false,
        showOptions: false,
      );
      
      setState(() {
        _isInstructionInitialized = true;
        _showingIntro = false;
        _showingInstruction = true;
      });
      
      await _instructionVideoController!.play();
      
      // Listen for instruction video completion
      _instructionVideoController!.addListener(_checkInstructionProgress);
      
    } catch (e, stack) {
      debugPrint('❌ ERROR LOADING INSTRUCTION VIDEO: $e');
      debugPrint('Stack: $stack');
      // Skip to main app
      _startFadeAndNavigate();
    }
  }
  
  /// Start playing pre-loaded instruction video
  void _startInstructionVideo() {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🎬 SWITCHING TO INSTRUCTION VIDEO');
    debugPrint('═══════════════════════════════════════════════════════');
    
    // Clean up intro video
    _introVideoController?.removeListener(_checkIntroProgress);
    _introChewieController?.dispose();
    _introVideoController?.dispose();
    
    setState(() {
      _showingIntro = false;
      _showingInstruction = true;
    });
    
    // Start instruction video
    _instructionVideoController!.play();
    debugPrint('▶️ Instruction video playing...');
    
    // Listen for instruction video completion
    _instructionVideoController!.addListener(_checkInstructionProgress);
  }
  
  /// Check intro video progress
  void _checkIntroProgress() {
    if (_introVideoController == null) return;
    
    if (!_introVideoController!.value.isPlaying && 
        _introVideoController!.value.position >= _introVideoController!.value.duration &&
        _introVideoController!.value.duration.inMilliseconds > 0) {
      debugPrint('✅ INTRO VIDEO COMPLETE - switching to instruction video...');
      
      if (_isInstructionInitialized) {
        _startInstructionVideo();
      } else {
        _initializeInstructionVideo();
      }
    }
  }
  
  /// Check instruction video progress
  void _checkInstructionProgress() {
    if (_instructionVideoController == null) return;
    
    if (!_instructionVideoController!.value.isPlaying && 
        _instructionVideoController!.value.position >= _instructionVideoController!.value.duration &&
        _instructionVideoController!.value.duration.inMilliseconds > 0) {
      debugPrint('✅ INSTRUCTION VIDEO COMPLETE - starting fade transition...');
      _startFadeAndNavigate();
    }
  }
  
  /// Start fade to white and navigate to main app
  Future<void> _startFadeAndNavigate() async {
    if (_hasNavigated) return;
    _hasNavigated = true;
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🌟 STARTING FADE TRANSITION (800ms white, 4000ms navigate)');
    debugPrint('═══════════════════════════════════════════════════════');
    
    // Show fade overlay
    setState(() {
      _showFadeOverlay = true;
    });
    
    // Animate fade to white (800ms)
    for (int i = 0; i <= 16; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        setState(() {
          _fadeOverlay = i / 16.0;
        });
      }
    }
    
    debugPrint('✅ Fade to white complete');
    
    // Navigate to main app with fade transition (4000ms)
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ThetaHomePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 4000),
        ),
      );
    }
    
    debugPrint('✅ Navigation to main app initiated');
  }

  @override
  void dispose() {
    debugPrint('🗑️ Disposing intro screen resources...');
    _introVideoController?.removeListener(_checkIntroProgress);
    _instructionVideoController?.removeListener(_checkInstructionProgress);
    _introVideoController?.dispose();
    _instructionVideoController?.dispose();
    _introChewieController?.dispose();
    _instructionChewieController?.dispose();
    debugPrint('✅ Intro screen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video content
          Center(
            child: _buildVideoContent(),
          ),
          
          // Fade overlay (white)
          if (_showFadeOverlay)
            AnimatedOpacity(
              opacity: _fadeOverlay,
              duration: const Duration(milliseconds: 50),
              child: Container(
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildVideoContent() {
    // Show intro video
    if (_showingIntro && _isIntroInitialized && _introChewieController != null) {
      return AspectRatio(
        aspectRatio: _introVideoController!.value.aspectRatio,
        child: Chewie(controller: _introChewieController!),
      );
    }
    
    // Show instruction video
    if (_showingInstruction && _isInstructionInitialized && _instructionChewieController != null) {
      return AspectRatio(
        aspectRatio: _instructionVideoController!.value.aspectRatio,
        child: Chewie(controller: _instructionChewieController!),
      );
    }
    
    // Show subtle loading spinner
    return const SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
      ),
    );
  }
}
