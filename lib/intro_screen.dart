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
  VideoPlayerController? _intro;
  VideoPlayerController? _instruction;

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

  double _fadeOverlay = 0.0;
  bool _showFadeOverlay = false;
  bool _showLatestPc = false;
  double _latestPcOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // IMPORTANT: make this match your real asset path exactly
      precacheImage(const AssetImage('assets/images/LATEST PC.png'), context);

      await _initializeIntroVideo();
    });
  }

  Future<void> _initializeIntroVideo() async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🎬 INIT VIDEO 1 (INTRO)');
      debugPrint('═══════════════════════════════════════════════════════');

      _intro?.removeListener(_checkIntroProgress);
      await _intro?.dispose();

      _intro = VideoPlayerController.asset('assets/video/intro_video.mp4');

      await _intro!.initialize();
      await _intro!.setVolume(1.0);
      await _intro!.setLooping(false);

      setState(() => _isIntroInitialized = true);

      _intro!.addListener(_checkIntroProgress);

      await _intro!.play();
      debugPrint('▶️ intro play() called');

      await _waitForFirstFrame(_intro!, 'intro');
      _startIntroTimeout();
      _startPlaybackMonitor();

      // Preload instruction while intro plays
      unawaited(_preloadInstructionVideo());
    } catch (e, st) {
      debugPrint('❌ INTRO INIT ERROR: $e');
      debugPrint('$st');
      _switchToInstructionVideo(); // fallback
    }
  }

  Future<void> _preloadInstructionVideo() async {
    try {
      debugPrint('📹 Preloading instruction...');
      _instruction?.removeListener(_checkInstructionProgress);
      await _instruction?.dispose();

      _instruction = VideoPlayerController.asset('assets/video/instruction_vid.mp4');
      await _instruction!.initialize();
      await _instruction!.setVolume(1.0);
      await _instruction!.setLooping(false);

      if (!mounted) return;
      setState(() => _isInstructionInitialized = true);

      debugPrint('✅ Instruction preloaded');
    } catch (e) {
      debugPrint('⚠️ Instruction preload failed: $e');
    }
  }

  Future<void> _initializeInstructionVideo() async {
    try {
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🎬 INIT VIDEO 2 (INSTRUCTION)');
      debugPrint('═══════════════════════════════════════════════════════');

      _instruction?.removeListener(_checkInstructionProgress);
      await _instruction?.dispose();

      _instruction = VideoPlayerController.asset('assets/video/instruction_vid.mp4');
      await _instruction!.initialize();
      await _instruction!.setVolume(1.0);
      await _instruction!.setLooping(false);

      if (!mounted) return;
      setState(() => _isInstructionInitialized = true);

      await _startInstructionVideo();
    } catch (e, st) {
      debugPrint('❌ INSTRUCTION INIT ERROR: $e');
      debugPrint('$st');
      _startFadeAndNavigate();
    }
  }

  Future<void> _startInstructionVideo() async {
    if (_instruction == null) {
      _startFadeAndNavigate();
      return;
    }

    _instruction!.addListener(_checkInstructionProgress);

    await _instruction!.play();
    debugPrint('▶️ instruction play() called');

    await _waitForFirstFrame(_instruction!, 'instruction');
    _startInstructionTimeout();
  }

  Future<void> _waitForFirstFrame(VideoPlayerController c, String name) async {
    debugPrint('⏳ Waiting for first frame ($name)...');
    const maxAttempts = 50; // 5 seconds
    for (int i = 1; i <= maxAttempts; i++) {
      await Future.delayed(const Duration(milliseconds: 100));

      if (c.value.hasError) {
        debugPrint('❌ $name error: ${c.value.errorDescription}');
        return;
      }

      final pos = c.value.position;
      final isPlaying = c.value.isPlaying;

      if (isPlaying && pos.inMilliseconds > 0) {
        debugPrint('✅ First frame ($name) @ ${pos.inMilliseconds}ms');
        return;
      }

      if (i % 10 == 0) {
        debugPrint('   ...still waiting ($name) attempt $i, playing=$isPlaying, pos=${pos.inMilliseconds}ms');
      }
    }
    debugPrint('⚠️ First frame timeout ($name) — continuing anyway');
  }

  void _startIntroTimeout() {
    final duration = _intro?.value.duration ?? const Duration(seconds: 30);
    final timeout = duration + const Duration(seconds: 5);

    _introTimeoutTimer?.cancel();
    _introTimeoutTimer = Timer(timeout, () {
      if (!_introCompleted && mounted) {
        debugPrint('⚠️ INTRO TIMEOUT — switching to instruction');
        _switchToInstructionVideo();
      }
    });
  }

  void _startInstructionTimeout() {
    final duration = _instruction?.value.duration ?? const Duration(seconds: 30);
    final timeout = duration + const Duration(seconds: 5);

    _instructionTimeoutTimer?.cancel();
    _instructionTimeoutTimer = Timer(timeout, () {
      if (!_instructionCompleted && mounted) {
        debugPrint('⚠️ INSTRUCTION TIMEOUT — navigating');
        _startFadeAndNavigate();
      }
    });
  }

  void _startPlaybackMonitor() {
    _playbackMonitorTimer?.cancel();
    _playbackMonitorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;

      if (_showingIntro && _intro != null && !_introCompleted) {
        final pos = _intro!.value.position;
        final isPlaying = _intro!.value.isPlaying;

        if (isPlaying && pos == _lastIntroPosition && pos.inMilliseconds > 0) {
          _stuckFrameCount++;
          if (_stuckFrameCount >= 6) {
            debugPrint('🔄 Intro stuck 3s — switching');
            _switchToInstructionVideo();
          }
        } else {
          _stuckFrameCount = 0;
        }
        _lastIntroPosition = pos;
      }

      if (_showingInstruction && _instruction != null && !_instructionCompleted) {
        final pos = _instruction!.value.position;
        final isPlaying = _instruction!.value.isPlaying;

        if (isPlaying && pos == _lastInstructionPosition && pos.inMilliseconds > 0) {
          _stuckFrameCount++;
          if (_stuckFrameCount >= 6) {
            debugPrint('🔄 Instruction stuck 3s — navigating');
            _startFadeAndNavigate();
          }
        } else {
          _stuckFrameCount = 0;
        }
        _lastInstructionPosition = pos;
      }
    });
  }

  void _checkIntroProgress() {
    if (_intro == null || _introCompleted) return;

    final v = _intro!.value;
    final pos = v.position;
    final dur = v.duration;

    if (dur.inMilliseconds > 0 && pos.inMilliseconds >= dur.inMilliseconds - 100) {
      debugPrint('✅ INTRO COMPLETE');
      _switchToInstructionVideo();
      return;
    }

    if (!v.isPlaying && dur.inMilliseconds > 0 && pos.inMilliseconds > dur.inMilliseconds - 500) {
      debugPrint('✅ INTRO STOPPED NEAR END — treating complete');
      _switchToInstructionVideo();
    }
  }

  void _switchToInstructionVideo() {
    if (_introCompleted) return;
    _introCompleted = true;

    _introTimeoutTimer?.cancel();
    _intro?.removeListener(_checkIntroProgress);
    _intro?.pause();

    _stuckFrameCount = 0;

    setState(() {
      _showingIntro = false;
      _showingInstruction = true;
    });

    if (_isInstructionInitialized && _instruction != null) {
      unawaited(_startInstructionVideo());
    } else {
      unawaited(_initializeInstructionVideo());
    }
  }

  void _checkInstructionProgress() {
    if (_instruction == null || _instructionCompleted) return;

    final v = _instruction!.value;
    final pos = v.position;
    final dur = v.duration;

    if (dur.inMilliseconds > 0 && pos.inMilliseconds >= dur.inMilliseconds - 100) {
      debugPrint('✅ INSTRUCTION COMPLETE');
      _startFadeAndNavigate();
      return;
    }

    if (!v.isPlaying && dur.inMilliseconds > 0 && pos.inMilliseconds > dur.inMilliseconds - 500) {
      debugPrint('✅ INSTRUCTION STOPPED NEAR END — treating complete');
      _startFadeAndNavigate();
    }
  }

  Future<void> _startFadeAndNavigate() async {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _instructionCompleted = true;

    _introTimeoutTimer?.cancel();
    _instructionTimeoutTimer?.cancel();
    _playbackMonitorTimer?.cancel();

    _intro?.pause();
    _instruction?.pause();

    setState(() => _showFadeOverlay = true);

    // Fade to white (800ms)
    for (int i = 0; i <= 16; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() => _fadeOverlay = i / 16.0);
    }

    // Show splash
    if (!mounted) return;
    setState(() => _showLatestPc = true);

    for (int i = 0; i <= 16; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() => _latestPcOpacity = i / 16.0);
    }

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    Navigator.pushReplacement(context, AppRouter.fadeToHomeReplacement());
  }

  @override
  void dispose() {
    _introTimeoutTimer?.cancel();
    _instructionTimeoutTimer?.cancel();
    _playbackMonitorTimer?.cancel();

    _intro?.removeListener(_checkIntroProgress);
    _instruction?.removeListener(_checkInstructionProgress);

    _intro?.dispose();
    _instruction?.dispose();
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
                    child: Image.asset(
                      'assets/images/LATEST PC.png',
                      width: 320,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_showingIntro && _isIntroInitialized && _intro != null) {
      final size = _intro!.value.size;
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(_intro!),
            ),
          ),
        ),
      );
    }

    if (_showingInstruction && _isInstructionInitialized && _instruction != null) {
      final size = _instruction!.value.size;
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(_instruction!),
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
