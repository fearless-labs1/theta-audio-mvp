// Theta Audio MVP - Intro Screen (ANDROID PRODUCTION - FIXED)
//
// VIDEO SEQUENCE:
// 1. Play intro_video.mp4 (full duration)
// 2. Play instruction_vid.mp4 (full duration)
// 3. Fade to white overlay (800ms)
// 4. Fade in LATEST PC image on white overlay
// 5. Navigate to main app with fade transition (4000ms)
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
import 'dart:io';
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
  Timer? _windowsFallbackTimer;

  // Track last position for stuck detection
  Duration _lastIntroPosition = Duration.zero;
  Duration _lastInstructionPosition = Duration.zero;
  int _stuckFrameCount = 0;

  // Fade animation
  double _fadeOverlay = 0.0;
  bool _showFadeOverlay = false;
  bool _showLatestPc = false;
  double _latestPcOpacity = 0.0;
  final bool _allowPlaybackFallbacks = true;
  bool _introPlaybackStarted = false;
  bool _instructionPlaybackStarted = false;
  int _introInitRetryCount = 0;
  int _instructionInitRetryCount = 0;
  static const int _maxInitRetries = 2;
  bool _isIntroInitializing = false;
  bool _isInstructionInitializing = false;
  static const Duration _videoInitTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        precacheImage(
          const AssetImage('assets/images/latest_pc.png'),
          context,
        );
        _initializeIntroVideo();
        if (Platform.isWindows) {
          _startWindowsFallbackTimer();
        }
      }
    });
  }

  void _startWindowsFallbackTimer() {
    _windowsFallbackTimer?.cancel();
    _windowsFallbackTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _hasNavigated) return;
      if (!_introPlaybackStarted && !_instructionPlaybackStarted) {
        debugPrint(
            '⚠️ WINDOWS FALLBACK - videos did not start, navigating to home');
        _startFadeAndNavigate();
      }
    });
  }

  // Initialize intro video (Video 1) with surface-ready detection
  Future<void> _initializeIntroVideo() async {
    if (_isIntroInitializing) return;
    _isIntroInitializing = true;
    try {
      _introVideoController?.removeListener(_checkIntroProgress);
      _introVideoController?.dispose();
      _introPlaybackStarted = false;
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🎬 THETA INTRO SCREEN - INITIALIZING VIDEO 1 (INTRO)');
      debugPrint('═══════════════════════════════════════════════════════');

      // Try MP4 first (recommended), fall back to MOV
      String videoPath = 'assets/video/intro_video.mp4';

      _introVideoController = VideoPlayerController.asset(videoPath);

      debugPrint('📹 Loading $videoPath from assets...');

      await _initializeController(_introVideoController!, 'intro');

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
      _introPlaybackStarted = true;
      _windowsFallbackTimer?.cancel();
      debugPrint('▶️ Intro video play() called...');

      await _ensurePlaybackStarted(_introVideoController!, 'intro');

      // Wait for first frame to actually render (surface-ready detection)
      await _waitForFirstFrame(_introVideoController!, 'intro');

      if (_allowPlaybackFallbacks) {
        // Start timeout timer (fallback if video hangs)
        _startIntroTimeout();

        // Start playback monitor to detect stuck video
        _startPlaybackMonitor();
      }

      // Pre-load instruction video while intro plays
      _preloadInstructionVideo();
    } catch (e, stack) {
      debugPrint('❌ ERROR LOADING INTRO VIDEO: $e');
      debugPrint('Stack: $stack');
      // Try MOV format as fallback
      _tryFallbackIntroFormat();
    } finally {
      _isIntroInitializing = false;
    }
  }

  // Try loading MOV format if MP4 fails
  Future<void> _tryFallbackIntroFormat() async {
    try {
      debugPrint('🔄 Trying fallback format: intro_video.mov');

      _introVideoController?.dispose();
      _introPlaybackStarted = false;
      _introVideoController =
          VideoPlayerController.asset('assets/video/intro_video.mov');

      await _initializeController(_introVideoController!, 'intro fallback');
      await _introVideoController!.setVolume(1.0);

      setState(() {
        _isIntroInitialized = true;
      });

      _introVideoController!.addListener(_checkIntroProgress);
      await _introVideoController!.play();
      _introPlaybackStarted = true;

      await _ensurePlaybackStarted(_introVideoController!, 'intro');

      await _waitForFirstFrame(_introVideoController!, 'intro');
      if (_allowPlaybackFallbacks) {
        _startIntroTimeout();
        _startPlaybackMonitor();
      }
      _preloadInstructionVideo();
    } catch (e) {
      debugPrint('❌ Fallback also failed: $e');
      _retryIntroInitialization();
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

      if (controller.value.hasError) {
        debugPrint(
            '❌ Video error while waiting for first frame ($videoName): ${controller.value.errorDescription}');
        return;
      }

      if (isPlaying && position.inMilliseconds > 0) {
        debugPrint(
            '✅ First frame rendered ($videoName) - position: ${position.inMilliseconds}ms');
        return;
      }

      // Also check if video has frames ready (buffering indicator)
      if (controller.value.isBuffering) {
        debugPrint('⏳ Video buffering ($videoName)...');
      }
    }

    debugPrint(
        '⚠️ Timeout waiting for first frame ($videoName) after 5 seconds');
  }

  Future<void> _ensurePlaybackStarted(
      VideoPlayerController controller, String videoName) async {
    for (int attempt = 1; attempt <= 5; attempt++) {
      await Future.delayed(const Duration(milliseconds: 250));
      final value = controller.value;
      if (value.isPlaying ||
          value.position.inMilliseconds > 0 ||
          value.isBuffering) {
        return;
      }

      debugPrint(
          '↻ $videoName playback not started (attempt $attempt) - retrying');
      await controller.seekTo(Duration.zero);
      await controller.play();
    }
  }

  // Start timeout timer for intro video
  void _startIntroTimeout() {
    final duration =
        _introVideoController?.value.duration ?? const Duration(seconds: 30);
    final timeoutDuration = duration + const Duration(seconds: 5);

    debugPrint('⏱️ Intro timeout set for ${timeoutDuration.inSeconds} seconds');

    _introTimeoutTimer?.cancel();
    _introTimeoutTimer = Timer(timeoutDuration, () {
      if (!_introCompleted && mounted && _introPlaybackStarted) {
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
            if (_instructionPlaybackStarted) {
              _markInstructionComplete('INSTRUCTION VIDEO STUCK');
            }
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

      await _initializeController(
        _instructionVideoController!,
        'instruction preload',
      );
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
    if (_isInstructionInitializing) return;
    _isInstructionInitializing = true;
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🎬 INITIALIZING VIDEO 2 (INSTRUCTION)');
      debugPrint('═══════════════════════════════════════════════════════');

      _instructionVideoController?.removeListener(_checkInstructionProgress);
      _instructionVideoController?.dispose();
      _instructionPlaybackStarted = false;
      _instructionVideoController = VideoPlayerController.asset(
        'assets/video/instruction_vid.mp4',
      );

      await _initializeController(_instructionVideoController!, 'instruction');
      await _instructionVideoController!.setVolume(1.0);

      setState(() {
        _isInstructionInitialized = true;
      });

      _startInstructionVideo();
    } catch (e, stack) {
      debugPrint('❌ ERROR LOADING INSTRUCTION VIDEO: $e');
      debugPrint('Stack: $stack');
      await _retryInstructionInitialization();
    } finally {
      _isInstructionInitializing = false;
    }
  }

  // Start playing instruction video
  Future<void> _startInstructionVideo() async {
    if (_instructionVideoController == null) {
      await _retryInstructionInitialization();
      return;
    }

    // Add listener before playing
    _instructionVideoController!.addListener(_checkInstructionProgress);

    await _instructionVideoController!.play();
    _instructionPlaybackStarted = true;
    _windowsFallbackTimer?.cancel();
    debugPrint('▶️ Instruction video playing...');

    await _ensurePlaybackStarted(_instructionVideoController!, 'instruction');

    // Wait for first frame
    await _waitForFirstFrame(_instructionVideoController!, 'instruction');

    // Start timeout timer
    if (_allowPlaybackFallbacks) {
      _startInstructionTimeout();
    }
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
      if (!_instructionCompleted && mounted && _instructionPlaybackStarted) {
        debugPrint('⚠️ INSTRUCTION VIDEO TIMEOUT - forcing navigation');
        _markInstructionComplete('INSTRUCTION VIDEO TIMEOUT');
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
      _markInstructionComplete('INSTRUCTION VIDEO COMPLETE');
      return;
    }

    // Check if stopped near end
    if (!value.isPlaying &&
        duration.inMilliseconds > 0 &&
        position.inMilliseconds > duration.inMilliseconds - 500) {
      _markInstructionComplete('INSTRUCTION VIDEO STOPPED NEAR END');
    }
  }

  void _markInstructionComplete(String reason) {
    if (_instructionCompleted) return;
    debugPrint('✅ $reason');
    _instructionCompleted = true;
    _startFadeAndNavigate();
  }

  Future<void> _initializeController(
      VideoPlayerController controller, String label) async {
    try {
      await controller.initialize().timeout(_videoInitTimeout);
    } on TimeoutException {
      throw TimeoutException('Video init timed out: $label');
    }
  }

  Future<void> _retryIntroInitialization() async {
    if (!mounted) {
      return;
    }

    if (_introInitRetryCount >= _maxInitRetries) {
      debugPrint(
          '⚠️ Intro video failed after retries - continuing to retry...');
      _introInitRetryCount = 0;
    } else {
      _introInitRetryCount++;
    }

    final delay =
        Duration(milliseconds: 750 + (_introInitRetryCount * 250));
    debugPrint('↻ Retrying intro initialization ($_introInitRetryCount)');
    await Future.delayed(delay);
    if (!mounted) return;
    await _initializeIntroVideo();
  }

  Future<void> _retryInstructionInitialization() async {
    if (!mounted) {
      return;
    }

    if (_instructionInitRetryCount >= _maxInitRetries) {
      debugPrint(
          '⚠️ Instruction video failed after retries - continuing to retry...');
      _instructionInitRetryCount = 0;
    } else {
      _instructionInitRetryCount++;
    }

    final delay =
        Duration(milliseconds: 750 + (_instructionInitRetryCount * 250));
    debugPrint(
        '↻ Retrying instruction initialization ($_instructionInitRetryCount)');
    await Future.delayed(delay);
    if (!mounted) return;
    await _initializeInstructionVideo();
  }

  // Start fade to white and navigate to main app
  Future<void> _startFadeAndNavigate() async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🌟 STARTING FADE TRANSITION (800ms white, 4000ms navigate)');
    debugPrint('═══════════════════════════════════════════════════════');

    // Cancel all timers
    _introTimeoutTimer?.cancel();
    _instructionTimeoutTimer?.cancel();
    _playbackMonitorTimer?.cancel();
    _windowsFallbackTimer?.cancel();

    // Stop any playing video
    _introVideoController?.pause();
    _instructionVideoController?.pause();

    // Show white overlay and LATEST PC splash immediately
    if (mounted) {
      setState(() {
        _showFadeOverlay = true;
        _fadeOverlay = 1.0;
        _showLatestPc = true;
        _latestPcOpacity = 1.0;
      });

      // Briefly hold the splash before navigating
      await Future.delayed(const Duration(milliseconds: 1200));
    }

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
    _windowsFallbackTimer?.cancel();

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

          // LATEST PC splash on white background
          if (_showLatestPc)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _latestPcOpacity,
                duration: const Duration(milliseconds: 50),
                child: Container(
                  color: Colors.white,
                  child: Center(
                    child: SizedBox.expand(
                      child: Image.asset(
                        'assets/images/latest_pc.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (!_isIntroInitialized && !_hasNavigated) _buildLoadingIndicator(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
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

  Widget _buildVideoContent() {
    // Show intro video
    if (_showingIntro && _isIntroInitialized && _introVideoController != null) {
      return _buildVideoPlayer(_introVideoController!);
    }

    // Show instruction video
    if (_showingInstruction &&
        _isInstructionInitialized &&
        _instructionVideoController != null) {
      return _buildVideoPlayer(_instructionVideoController!);
    }

    return const SizedBox.expand();
  }

  Widget _buildVideoPlayer(VideoPlayerController controller) {
    final aspectRatio = controller.value.aspectRatio;
    final safeAspectRatio = aspectRatio > 0 ? aspectRatio : 16 / 9;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: safeAspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }

}
