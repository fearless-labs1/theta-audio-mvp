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
  VideoPlayerController? _introVideoController;
  VideoPlayerController? _instructionVideoController;

  bool _isIntroInitialized = false;
  bool _isInstructionInitialized = false;
  bool _showingIntro = true;
  bool _showingInstruction = false;

  bool _hasNavigated = false;
  bool _introCompleted = false;
  bool _instructionCompleted = false;

  Timer? _introTimeoutTimer;
  Timer? _instructionTimeoutTimer;
  Timer? _playbackMonitorTimer;

  Duration _lastIntroPosition = Duration.zero;
  Duration _lastInstructionPosition = Duration.zero;
  int _stuckFrameCount = 0;

  // Fade / splash
  double _fadeOverlay = 0.0;
  bool _showFadeOverlay = false;

  bool _showLatestPc = false;
  double _latestPcOpacity = 0.0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // Use the actual repo filename (from your screenshot)
      precacheImage(const AssetImage('assets/images/latest_pc.png'), context);

      await _initializeIntroVideo();
    });
  }

  Future<void> _initializeIntroVideo() async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🎬 THETA INTRO SCREEN - INIT VIDEO 1 (INTRO)');
      debugPrint('═══════════════════════════════════════════════════════');

      _introVideoController?.removeListener(_checkIntroProgress);
      await _introVideoController?.dispose();

      _introVideoController =
          VideoPlayerController.asset('assets/video/intro_video.mp4');

      await _introVideoController!.initialize();
      await _introVideoController!.setVolume(1.0);
      await _introVideoController!.setLooping(false);

      if (!mounted) return;
      setState(() => _isIntroInitialized = true);

      _introVideoController!.addListener(_checkIntroProgress);

      await _introVideoController!.play();
      debugPrint('▶️ Intro play() called');

      await _waitForFirstFrame(_introVideoController!, 'intro');

      _startIntroTimeout();
      _startPlaybackMonitor();

      // Preload instruction while intro plays (no need to await)
      unawaited(_preloadInstructionVideo());
    } catch (e, st) {
      debugPrint('❌ INTRO INIT ERROR: $e');
      debugPrint('Stack: $st');
      _switchToInstructionVideo();
    }
  }

  Future<void> _preloadInstructionVideo() async {
    try {
      debugPrint('📹 Pre-loading instruction video...');

      _instructionVideoController?.removeListener(_checkInstructionProgress);
      await _instructionVideoController?.dispose();

      _instructionVideoController =
          VideoPlayerController.asset('assets/video/instruction_vid.mp4');

      await _instructionVideoController!.initialize();
      await _instructionVideoController!.setVolume(1.0);
      await _instructionVideoController!.setLooping(false);

      if (!mounted) return;
      setState(() => _isInstructionInitialized = true);

      debugPrint('✅ Instruction video pre-loaded');
    } catch (e) {
      debugPrint('⚠️ Instruction preload failed: $e');
    }
  }

  Future<void> _initializeInstructionVideo() async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🎬 INIT VIDEO 2 (INSTRUCTION)');
      debugPrint('═══════════════════════════════════════════════════════');

      _instructionVideoController?.removeListener(_checkInstructionProgress);
      await _instructionVideoController?.dispose();

      _instructionVideoController =
          VideoPlayerController.asset('assets/video/instruction_vid.mp4');

      await _instructionVideoController!.initialize();
      await _instructionVideoController!.setVolume(1.0);
      await _instructionVideoController!.setLooping(false);

      if (!mounted) return;
      setState(() => _isInstructionInitialized = true);

      await _startInstructionVideo();
    } catch (e, st) {
      debugPrint('❌ INSTRUCTION INIT ERROR: $e');
      debugPrint('Stack: $st');
      _startFadeAndNavigate();
    }
  }

  Future<void> _startInstructionVideo() async {
    if (_instructionVideoController == null) {
      _startFadeAndNavigate();
      return;
    }

    _instructionVideoController!.addListener(_checkInstructionProgress);

    await _instructionVideoController!.play();
    debugPrint('▶️ Instruction play() called');

    await _waitForFirstFrame(_instructionVideoController!, 'instruction');

    _startInstructionTimeout();
  }

  Future<void> _waitForFirstFrame(
      VideoPlayerController controller, String name) async {
    debugPrint('⏳ Waiting for first frame ($name)...');

    const maxAttempts = 50; // 5 seconds
    for (int i = 1; i <= maxAttempts; i++) {
      await Future.delayed(const Duration(milliseconds: 100));

      if (controller.value.hasError) {
        debugPrint('❌ $name error: ${controller.value.errorDescription}');
        return;
      }

      final pos = controller.value.position;
      final isPlaying = controller.value.isPlaying;

      if (isPlaying && pos.inMilliseconds > 0) {
        debugPrint('✅ First frame ($name) @ ${pos.inMilliseconds}ms');
        return;
      }

      if (i % 10 == 0) {
        debugPrint(
            '   ...still waiting ($name) attempt $i, playing=$isPlaying, pos=${pos.inMilliseconds}ms');
      }
    }

    debugPrint('⚠️ First frame timeout ($name) — continuing anyway');
  }

  void _startIntroTimeout() {
    final duration =
        _introVideoController?.value.duration ?? const Duration(seconds: 30);
    final timeout = duration + const Duration(seconds: 5);

    _introTimeoutTimer?.cancel();
    _introTimeoutTimer = Timer(timeout, () {
      if (!_introCompleted && mounted) {
        debugPrint('⚠️ INTRO TIMEOUT — forcing switch to instruction');
        _switchToInstructionVideo();
      }
    });
  }

  void _startInstructionTimeout() {
    final duration = _instructionVideoController?.value.duration ??
        const Duration(seconds: 30);
    final timeout = duration + const Duration(seconds: 5);

    _instructionTimeoutTimer?.cancel();
    _instructionTimeoutTimer = Timer(timeout, () {
      if (!_instructionCompleted && mounted) {
        debugPrint('⚠️ INSTRUCTION TIMEOUT — forcing navigation');
        _startFadeAndNavigate();
      }
    });
  }

  void _startPlaybackMonitor() {
    _playbackMonitorTimer?.cancel();
    _playbackMonitorTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Monitor intro
      if (_showingIntro &&
          _introVideoController != null &&
          !_introCompleted &&
          _introVideoController!.value.isInitialized) {
        final currentPos = _introVideoController!.value.position;
        final isPlaying = _introVideoController!.value.isPlaying;

        if (isPlaying &&
            currentPos == _lastIntroPosition &&
            currentPos.inMilliseconds > 0) {
          _stuckFrameCount++;
          if (_stuckFrameCount >= 6) {
            debugPrint('🔄 Intro stuck for 3s — switching');
            _switchToInstructionVideo();
          }
        } else {
          _stuckFrameCount = 0;
        }

        _lastIntroPosition = currentPos;
      }

      // Monitor instruction
      if (_showingInstruction &&
          _instructionVideoController != null &&
          !_instructionCompleted &&
          _instructionVideoController!.value.isInitialized) {
        final currentPos = _instructionVideoController!.value.position;
        final isPlaying = _instructionVideoController!.value.isPlaying;

        if (isPlaying &&
            currentPos == _lastInstructionPosition &&
            currentPos.inMilliseconds > 0) {
          _stuckFrameCount++;
          if (_stuckFrameCount >= 6) {
            debugPrint('🔄 Instruction stuck for 3s — navigating');
            _startFadeAndNavigate();
          }
        } else {
          _stuckFrameCount = 0;
        }

        _lastInstructionPosition = currentPos;
      }
    });
  }

  void _checkIntroProgress() {
    if (_introVideoController == null || _introCompleted) return;

    final value = _introVideoController!.value;
    final position = value.position;
    final duration = value.duration;

    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 100) {
      debugPrint('✅ INTRO COMPLETE');
      _switchToInstructionVideo();
      return;
    }

    if (!value.isPlaying &&
        duration.inMilliseconds > 0 &&
        position.inMilliseconds > duration.inMilliseconds - 500) {
      debugPrint('✅ INTRO STOPPED NEAR END — treating as complete');
      _switchToInstructionVideo();
    }
  }

  void _switchToInstructionVideo() {
    if (_introCompleted) return;
    _introCompleted = true;

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🎬 SWITCHING TO INSTRUCTION VIDEO');
    debugPrint('═══════════════════════════════════════════════════════');

    _introTimeoutTimer?.cancel();

    _introVideoController?.removeListener(_checkIntroProgress);
    _introVideoController?.pause();

    _stuckFrameCount = 0;

    if (!mounted) return;
    setState(() {
      _showingIntro = false;
      _showingInstruction = true;
    });

    if (_isInstructionInitialized && _instructionVideoController != null) {
      unawaited(_startInstructionVideo());
    } else {
      unawaited(_initializeInstructionVideo());
    }
  }

  void _checkInstructionProgress() {
    if (_instructionVideoController == null || _instructionCompleted) return;

    final value = _instructionVideoController!.value;
    final position = value.position;
    final duration = value.duration;

    if (duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 100) {
      debugPrint('✅ INSTRUCTION COMPLETE');
      _startFadeAndNavigate();
      return;
    }

    if (!value.isPlaying &&
        duration.inMilliseconds > 0 &&
        position.inMilliseconds > duration.inMilliseconds - 500) {
      debugPrint('✅ INSTRUCTION STOPPED NEAR END — treating as complete');
      _startFadeAndNavigate();
    }
  }

  Future<void> _startFadeAndNavigate() async {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _instructionCompleted = true;

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🌟 STARTING FADE TRANSITION');
    debugPrint('═══════════════════════════════════════════════════════');

    _introTimeoutTimer?.cancel();
    _instructionTimeoutTimer?.cancel();
    _playbackMonitorTimer?.cancel();

    _introVideoController?.pause();
    _instructionVideoController?.pause();

    if (!mounted) return;
    setState(() {
      _showFadeOverlay = true;
      _fadeOverlay = 0.0;
    });

    // Fade to white (800ms)
    for (int i = 0; i <= 16; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() => _fadeOverlay = i / 16.0);
    }

    if (!mounted) return;
    setState(() {
      _showLatestPc = true;
      _latestPcOpacity = 0.0;
    });

    // Fade in splash
    for (int i = 0; i <= 16; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() => _latestPcOpacity = i / 16.0);
    }

    // Hold briefly
    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    Navigator.pushReplacement(context, AppRouter.fadeToHomeReplacement());
  }

  @override
  void dispose() {
    _introTimeoutTimer?.cancel();
    _instructionTimeoutTimer?.cancel();
    _playbackMonitorTimer?.cancel();

    _introVideoController?.removeListener(_checkIntroProgress);
    _instructionVideoController?.removeListener(_checkInstructionProgress);

    _introVideoController?.dispose();
    _instructionVideoController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildVideoContent()),

          if (_showFadeOverlay)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _fadeOverlay,
                duration: const Duration(milliseconds: 50),
                child: Container(color: Colors.white),
              ),
            ),

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

  Widget _buildVideoContent() {
    if (_showingIntro && _isIntroInitialized && _introVideoController != null) {
      final size = _introVideoController!.value.size;
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(_introVideoController!),
            ),
          ),
        ),
      );
    }

    if (_showingInstruction &&
        _isInstructionInitialized &&
        _instructionVideoController != null) {
      final size = _instructionVideoController!.value.size;
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(_instructionVideoController!),
            ),
          ),
        ),
      );
    }

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
