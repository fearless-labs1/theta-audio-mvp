// Theta Audio MVP - Intro Screen (ANDROID PRODUCTION - FIXED)
//
// VIDEO SEQUENCE:
// 1. Play intro_video.mp4 (full duration)
// 2. Play instruction_vid.mp4 (full duration)
// 3. Fade to white overlay (800ms)
// 4. Navigate to main app with fade transition (4000ms)
//
// FIXES APPLIED:
// - Removed Chewie layer (simpler, more reliable playback)
// - Added surface-ready detection (waits for first frame to render)
// - Added 5-second timeout fallback if video fails to start
// - Fixed completion detection for frozen video edge case
// - Added isPlaying check with position monitoring
// - Better error recovery and fallback logic
//
// FEATURES:
// - No skip functionality (users must watch entire videos)
// - Subtle spinner only during load
// - Black background to prevent white flash
// - Smooth fade transitions

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:theta_audio_mvp/app/router.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  // Video 1: Intro video
  VideoPlayerController? _introVideoController;

  // Video 2: Instruction video
  VideoPlayerController? _instructionVideoController;

  // State tracking
  bool _isIntroInitialized = false;
  bool _isInstructionInitialized = false;
  bool _showingIntro = true;
  bool _showingInstruction = false;
  bool _hasNavigated = false;
  bool _introCompleted = false;
  bool _instructionCompleted = false;

  // Timeout timers
  Timer? _introTimeoutTimer;
  Timer? _instructionTimeoutTimer;
  Timer? _playbackMonitorTimer;

  // Track last position for stuck detection
  Duration _lastIntroPosition = Duration.zero;
  Duration _lastInstructionPosition = Duration.zero;
  int _stuckFrameCount = 0;

  // Fade animation
  double _fadeOverlay = 0.0;
  bool _showFadeOverlay = false;

  @override
  void initState() {
    super.initState();
    _initializeIntroVideo();
  }

  // Initialize intro video (Video 1) with surface-ready detection
  Future<void> _initializeIntroVideo() async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🎬 THETA INTRO SCREEN - INITIALIZING VIDEO 1 (INTRO)');
      debugPrint('═══════════════════════════════════════════════════════');

      // Try MP4 first (recommended), fall back to MOV
      String videoPath = 'assets/video/intro_video.mp4';

      _introVideoController = VideoPlayerController.asset(videoPath);

      debugPrint('📹 Loading $videoPath from assets...');

      await _introVideoController!.initialize();

      debugPrint('✅ Intro video initialized');
      debugPrint(
          '   Duration: ${_introVideoController!.value.duration.inSeconds} seconds');
      debugPrint('   Size: ${_introVideoController!.value.size}');

      // Set volume
      await _introVideoController!.setVolume(1.0);

      setState(() {
        _isIntroInitialized = true;
      });

      // Add completion listener BEFORE playing
      _introVideoController!.addListener(_checkIntroProgress);

      // Start playback
      await _introVideoController!.play();
      debugPrint('▶️ Intro video play() called...');

      // Wait for first frame to actually render (surface-ready detection)
      await _waitForFirstFrame(_introVideoController!, 'intro');

      // Start timeout timer (fallback if video hangs)
      _startIntroTimeout();

      // Start playback monitor to detect stuck video
      _startPlaybackMonitor();

      // Pre-load instruction video while intro plays
      _preloadInstructionVideo();
    } catch (e, stack) {
      debugPrint('❌ ERROR LOADING INTRO VIDEO: $e');
      debugPrint('Stack: $stack');
      // Try MOV format as fallback
      _tryFallbackIntroFormat();
    }
  }

  // Try loading MOV format if MP4 fails
  Future<void> _tryFallbackIntroFormat() async {
    try {
      debugPrint('🔄 Trying fallback format: intro_video.mov');

      _introVideoController?.dispose();
      _introVideoController =
          VideoPlayerController.asset('assets/video/intro_video.mov');

      await _introVideoController!.initialize();
      await _introVideoController!.setVolume(1.0);

      setState(() {
        _isIntroInitialized = true;
      });

      _introVideoController!.addListener(_checkIntroProgress);
      await _introVideoController!.play();

      await _waitForFirstFrame(_introVideoController!, 'intro');
      _startIntroTimeout();
      _startPlaybackMonitor();
      _preloadInstructionVideo();
    } catch (e) {
      debugPrint('❌ Fallback also failed: $e');
      // Skip to instruction video
      _switchToInstructionVideo();
    }
  }

  // Wait for first frame to render (surface-ready detection)
  Future<void> _waitForFirstFrame(
      VideoPlayerController controller, String videoName) async {
    debugPrint('⏳ Waiting for first frame to render ($videoName)...');

    int attempts = 0;
    const maxAttempts = 50; // 5 seconds max wait

    while (attempts < maxAttempts) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;

      // Check if video is actually playing (position advancing)
      final position = controller.value.position;
      final isPlaying = controller.value.isPlaying;

      if (isPlaying && position.inMilliseconds > 0) {
        debugPrint(
            '✅ First frame rendered ($videoName) - position: ${position.inMilliseconds}ms');
        return;
      }

      // Also check if video has frames ready
      if (controller.value.isInitialized &&
          controller.value.size.width > 0 &&
          controller.value.size.height > 0 &&
          isPlaying) {
        debugPrint('✅ Video surface ready ($videoName)');
        return;
      }

      if (attempts % 10 == 0) {
        debugPrint(
            '   Still waiting... attempt $attempts, isPlaying: $isPlaying, position: ${position.inMilliseconds}ms');
      }
    }

    debugPrint('⚠️ First frame wait timeout ($videoName) - proceeding anyway');
  }

  // Start timeout timer for intro video
  void _startIntroTimeout() {
    final duration =
        _introVideoController?.value.duration ?? const Duration(seconds: 30);
    final timeoutDuration = duration + const Duration(seconds: 5);

    debugPrint('⏱️ Intro timeout set for ${timeoutDuration.inSeconds} seconds');

    _introTimeoutTimer?.cancel();
    _introTimeoutTimer = Timer(timeoutDuration, () {
      if (!_introCompleted && mounted) {
        debugPrint('⚠️ INTRO VIDEO TIMEOUT - forcing switch to instruction');
        _switchToInstructionVideo();
      }
    });
  }

  // Start playback monitor to detect stuck video
  void _startPlaybackMonitor() {
    _playbackMonitorTimer?.cancel();
    _playbackMonitorTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_showingIntro && _introVideoController != null && !_introCompleted) {
        final currentPos = _introVideoController!.value.position;
        final isPlaying = _introVideoController!.value.isPlaying;

        // Check if position is stuck while supposedly playing
        if (isPlaying &&
            currentPos == _lastIntroPosition &&
            currentPos.inMilliseconds > 0) {
          _stuckFrameCount++;
          debugPrint(
              '⚠️ Intro video may be stuck - count: $_stuckFrameCount, pos: ${currentPos.inMilliseconds}ms');

          if (_stuckFrameCount >= 6) {
            // 3 seconds of no progress
            debugPrint('🔄 Video stuck for 3 seconds - forcing skip');
            _switchToInstructionVideo();
          }
        } else {
          _stuckFrameCount = 0;
        }
        _lastIntroPosition = currentPos;
      }

      if (_showingInstruction &&
          _instructionVideoController != null &&
          !_instructionCompleted) {
        final currentPos = _instructionVideoController!.value.position;
        final isPlaying = _instructionVideoController!.value.isPlaying;

        if (isPlaying &&
            currentPos == _lastInstructionPosition &&
            currentPos.inMilliseconds > 0) {
          _stuckFrameCount++;
          debugPrint(
              '⚠️ Instruction video may be stuck - count: $_stuckFrameCount');

          if (_stuckFrameCount >= 6) {
            debugPrint('🔄 Video stuck for 3 seconds - forcing navigation');
            _startFadeAndNavigate();
          }
        } else {
          _stuckFrameCount = 0;
        }
        _lastInstructionPosition = currentPos;
      }
    });
  }

  // Pre-load instruction video while intro plays
  Future<void> _preloadInstructionVideo() async {
    try {
      debugPrint('📹 Pre-loading instruction_vid.mp4...');

      _instructionVideoController = VideoPlayerController.asset(
        'assets/video/instruction_vid.mp4',
      );

      await _instructionVideoController!.initialize();
      await _instructionVideoController!.setVolume(1.0);

      setState(() {
        _isInstructionInitialized = true;
      });

      debugPrint('✅ Instruction video pre-loaded');
      debugPrint(
          '   Duration: ${_instructionVideoController!.value.duration.inSeconds} seconds');
    } catch (e) {
      debugPrint('⚠️ Could not pre-load instruction video: $e');
    }
  }

  // Check intro video progress
  void _checkIntroProgress() {
    if (_introVideoController == null || _introCompleted) return;

    final value = _introVideoController!.value;
    final position = value.position;
    final duration = value.duration;

    // Check for completion: position at or past duration
    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 100) {
      // 100ms tolerance
      debugPrint(
          '✅ INTRO VIDEO COMPLETE (position: ${position.inMilliseconds}ms, duration: ${duration.inMilliseconds}ms)');
      _switchToInstructionVideo();
      return;
    }

    // Also check if video stopped playing near the end
    if (!value.isPlaying &&
        duration.inMilliseconds > 0 &&
        position.inMilliseconds > duration.inMilliseconds - 500) {
      debugPrint('✅ INTRO VIDEO STOPPED NEAR END - treating as complete');
      _switchToInstructionVideo();
    }
  }

  // Switch from intro to instruction video
  void _switchToInstructionVideo() {
    if (_introCompleted) return;
    _introCompleted = true;

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🎬 SWITCHING TO INSTRUCTION VIDEO');
    debugPrint('═══════════════════════════════════════════════════════');

    // Cancel intro timeout
    _introTimeoutTimer?.cancel();

    // Clean up intro video
    _introVideoController?.removeListener(_checkIntroProgress);
    _introVideoController?.pause();

    // Reset stuck counter
    _stuckFrameCount = 0;

    setState(() {
      _showingIntro = false;
      _showingInstruction = true;
    });

    // Start instruction video
    if (_isInstructionInitialized && _instructionVideoController != null) {
      _startInstructionVideo();
    } else {
      _initializeInstructionVideo();
    }
  }

  // Initialize instruction video if not pre-loaded
  Future<void> _initializeInstructionVideo() async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🎬 INITIALIZING VIDEO 2 (INSTRUCTION)');
      debugPrint('═══════════════════════════════════════════════════════');

      _instructionVideoController = VideoPlayerController.asset(
        'assets/video/instruction_vid.mp4',
      );

      await _instructionVideoController!.initialize();
      await _instructionVideoController!.setVolume(1.0);

      setState(() {
        _isInstructionInitialized = true;
      });

      _startInstructionVideo();
    } catch (e, stack) {
      debugPrint('❌ ERROR LOADING INSTRUCTION VIDEO: $e');
      debugPrint('Stack: $stack');
      // Skip to main app
      _startFadeAndNavigate();
    }
  }

  // Start playing instruction video
  Future<void> _startInstructionVideo() async {
    if (_instructionVideoController == null) {
      _startFadeAndNavigate();
      return;
    }

    // Add listener before playing
    _instructionVideoController!.addListener(_checkInstructionProgress);

    await _instructionVideoController!.play();
    debugPrint('▶️ Instruction video playing...');

    // Wait for first frame
    await _waitForFirstFrame(_instructionVideoController!, 'instruction');

    // Start timeout timer
    _startInstructionTimeout();
  }

  // Start timeout timer for instruction video
  void _startInstructionTimeout() {
    final duration = _instructionVideoController?.value.duration ??
        const Duration(seconds: 30);
    final timeoutDuration = duration + const Duration(seconds: 5);

    debugPrint(
        '⏱️ Instruction timeout set for ${timeoutDuration.inSeconds} seconds');

    _instructionTimeoutTimer?.cancel();
    _instructionTimeoutTimer = Timer(timeoutDuration, () {
      if (!_instructionCompleted && mounted) {
        debugPrint('⚠️ INSTRUCTION VIDEO TIMEOUT - forcing navigation');
        _startFadeAndNavigate();
      }
    });
  }

  // Check instruction video progress
  void _checkInstructionProgress() {
    if (_instructionVideoController == null || _instructionCompleted) return;

    final value = _instructionVideoController!.value;
    final position = value.position;
    final duration = value.duration;

    // Check for completion
    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 100) {
      debugPrint('✅ INSTRUCTION VIDEO COMPLETE');
      _startFadeAndNavigate();
      return;
    }

    // Check if stopped near end
    if (!value.isPlaying &&
        duration.inMilliseconds > 0 &&
        position.inMilliseconds > duration.inMilliseconds - 500) {
      debugPrint('✅ INSTRUCTION VIDEO STOPPED NEAR END - treating as complete');
      _startFadeAndNavigate();
    }
  }

  // Start fade to white and navigate to main app
  Future<void> _startFadeAndNavigate() async {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _instructionCompleted = true;

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🌟 STARTING FADE TRANSITION (800ms white, 4000ms navigate)');
    debugPrint('═══════════════════════════════════════════════════════');

    // Cancel all timers
    _introTimeoutTimer?.cancel();
    _instructionTimeoutTimer?.cancel();
    _playbackMonitorTimer?.cancel();

    // Stop any playing video
    _introVideoController?.pause();
    _instructionVideoController?.pause();

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
      Navigator.pushReplacement(context, AppRouter.fadeToHomeReplacement());
    }

    debugPrint('✅ Navigation to main app initiated');
  }

  @override
  void dispose() {
    debugPrint('🗑️ Disposing intro screen resources...');

    // Cancel all timers
    _introTimeoutTimer?.cancel();
    _instructionTimeoutTimer?.cancel();
    _playbackMonitorTimer?.cancel();

    // Remove listeners
    _introVideoController?.removeListener(_checkIntroProgress);
    _instructionVideoController?.removeListener(_checkInstructionProgress);

    // Dispose controllers
    _introVideoController?.dispose();
    _instructionVideoController?.dispose();

    debugPrint('✅ Intro screen disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video content (full screen)
          Positioned.fill(
            child: _buildVideoContent(),
          ),

          // Fade overlay (white)
          if (_showFadeOverlay)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _fadeOverlay,
                duration: const Duration(milliseconds: 50),
                child: Container(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    // Show intro video
    if (_showingIntro && _isIntroInitialized && _introVideoController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _introVideoController!.value.aspectRatio > 0
              ? _introVideoController!.value.aspectRatio
              : 16 / 9,
          child: VideoPlayer(_introVideoController!),
        ),
      );
    }

    // Show instruction video
    if (_showingInstruction &&
        _isInstructionInitialized &&
        _instructionVideoController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: _instructionVideoController!.value.aspectRatio > 0
              ? _instructionVideoController!.value.aspectRatio
              : 16 / 9,
          child: VideoPlayer(_instructionVideoController!),
        ),
      );
    }

    // Show subtle loading spinner
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
        ),
      ),
    );
  }
}
