// ignore_for_file: unused_field
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
  VideoPlayerController? _intro;
  VideoPlayerController? _instruction;

  bool _showingIntro = true;
  bool _showingInstruction = false;

  bool _introInitialized = false;
  bool _instructionInitialized = false;

  bool _introCompleted = false;
  bool _instructionCompleted = false;
  bool _hasNavigated = false;

  bool _introPlaybackStarted = false;
  bool _instructionPlaybackStarted = false;

  Timer? _introTimeout;
  Timer? _instructionTimeout;
  Timer? _monitorTimer;

  Duration _lastPos = Duration.zero;
  int _stuckCount = 0;
  int _playRetryCount = 0;
  VideoPlayerController? _lastMonitoredController;

  // Fade + splash
  bool _showFade = false;
  double _fadeOpacity = 0.0;

  bool _showLatestPc = false;
  double _latestPcOpacity = 0.0;

  // Desktop “if nothing starts, don't hang forever”
  Timer? _windowsStartGuard;
  Timer? _firstFrameGuard;

  static const bool _disableIntroVideo =
      bool.fromEnvironment('THETA_DISABLE_INTRO_VIDEO', defaultValue: false);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Pre-cache splash image
      precacheImage(const AssetImage('assets/images/latest_pc.png'), context);

      if (_shouldSkipIntroVideo) {
        debugPrint('INTRO_VIDEO: fallback-reason=${_fallbackReasonForDisabledVideo()}');
        unawaited(_startFadeAndNavigate());
        return;
      }

      // Guard: if desktop video playback never starts, force continue.
      if (Platform.isWindows || Platform.isLinux) {
        _windowsStartGuard = Timer(const Duration(seconds: 15), () {
          if (!mounted || _hasNavigated) return;
          if (!_introCompleted && !_instructionCompleted) {
            debugPrint('INTRO_VIDEO: fallback-reason=start-guard-timeout');
            _startFadeAndNavigate();
          }
        });
      }

      runZonedGuarded(() async {
        debugPrint('INTRO_VIDEO: using-video');
        await _initAndPlayIntro();
        _startFirstFrameGuard();
      }, (error, stackTrace) {
        debugPrint('INTRO_VIDEO: fallback-reason=zone-error error=$error');
        if (!mounted || _hasNavigated) return;
        unawaited(_startFadeAndNavigate());
      });
    });

  }

  String _fallbackReasonForDisabledVideo() {
    if (_disableIntroVideo) return 'video-disabled-flag';
    return 'video-disabled';
  }

  bool get _shouldSkipIntroVideo {
    if (_disableIntroVideo) return true;
    return false;
  }

  void _startFirstFrameGuard() {
    _firstFrameGuard?.cancel();
    _firstFrameGuard = Timer(const Duration(seconds: 5), () {
      if (!mounted || _hasNavigated) return;
      final active = _showingIntro ? _intro : _instruction;
      final position = active?.value.position ?? Duration.zero;
      if (position == Duration.zero) {
        debugPrint('INTRO_VIDEO: fallback-reason=no-first-frame-timeout');
        _startFadeAndNavigate();
      }
    });
  }

  Future<void> _initAndPlayIntro() async {
    try {
      debugPrint('🎬 INIT INTRO: assets/video/intro_video.mp4');

      await _disposeIntro();

      _intro = VideoPlayerController.asset('assets/video/intro_video.mp4');

      // IMPORTANT: initialize first, THEN set volume/looping, THEN play.
      await _intro!.initialize();
      await _intro!.setVolume(1.0);
      await _intro!.setLooping(false);

      if (!mounted) return;
      setState(() => _introInitialized = true);

      _intro!.addListener(_onIntroProgress);

      // Preload instruction while intro starts
      unawaited(_preloadInstruction());

      await _intro!.play();
      _introPlaybackStarted = true;
      _windowsStartGuard?.cancel();
      debugPrint('▶️ INTRO play() called');

      _startIntroTimeout();
      _startPlaybackMonitor();
    } catch (e, st) {
      debugPrint('INTRO_VIDEO: fallback-reason=intro-init-failed error=$e');
      debugPrint('$st');
      _switchToInstruction();
    }
  }

  Future<void> _preloadInstruction() async {
    if (_instructionInitialized) return;

    try {
      debugPrint('📦 PRELOAD INSTRUCTION: assets/video/instruction_vid.mp4');

      await _disposeInstruction();

      _instruction =
          VideoPlayerController.asset('assets/video/instruction_vid.mp4');

      await _instruction!.initialize();
      await _instruction!.setVolume(1.0);
      await _instruction!.setLooping(false);

      if (!mounted) return;
      setState(() => _instructionInitialized = true);

      debugPrint('✅ INSTRUCTION preloaded');
    } catch (e, st) {
      debugPrint('INTRO_VIDEO: fallback-reason=instruction-preload-failed error=$e');
      debugPrint('$st');
      // We can still navigate later even if instruction fails.
    }
  }

  Future<void> _initAndPlayInstruction() async {
    try {
      debugPrint('🎬 INIT+PLAY INSTRUCTION');

      // If it was preloaded, just play it.
      if (!_instructionInitialized || _instruction == null) {
        await _preloadInstruction();
      }

      if (_instruction == null || !_instructionInitialized) {
        debugPrint('INTRO_VIDEO: fallback-reason=instruction-not-available');
        _startFadeAndNavigate();
        return;
      }

      _instruction!.removeListener(_onInstructionProgress);
      _instruction!.addListener(_onInstructionProgress);

      await _instruction!.seekTo(Duration.zero);
      await _instruction!.play();
      _instructionPlaybackStarted = true;
      _windowsStartGuard?.cancel();
      debugPrint('▶️ INSTRUCTION play() called');

      _startInstructionTimeout();
    } catch (e, st) {
      debugPrint('INTRO_VIDEO: fallback-reason=instruction-init-failed error=$e');
      debugPrint('$st');
      _startFadeAndNavigate();
    }
  }

  void _onIntroProgress() {
    if (_intro == null || _introCompleted) return;
    final v = _intro!.value;
    if (!v.isInitialized) return;

    final pos = v.position;
    final dur = v.duration;

    if (!_introPlaybackStarted && v.isPlaying && pos > Duration.zero) {
      _introPlaybackStarted = true;
      _firstFrameGuard?.cancel();
    }

    // Treat “near end” as complete
    if (dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 120) {
      debugPrint('✅ INTRO COMPLETE');
      _switchToInstruction();
    }
  }

  void _onInstructionProgress() {
    if (_instruction == null || _instructionCompleted) return;
    final v = _instruction!.value;
    if (!v.isInitialized) return;

    final pos = v.position;
    final dur = v.duration;

    if (!_instructionPlaybackStarted && v.isPlaying && pos > Duration.zero) {
      _instructionPlaybackStarted = true;
      _firstFrameGuard?.cancel();
    }

    if (dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 120) {
      debugPrint('✅ INSTRUCTION COMPLETE');
      _instructionCompleted = true;
      _startFadeAndNavigate();
    }
  }

  void _switchToInstruction() {
    if (_introCompleted) return;
    _introCompleted = true;

    _introTimeout?.cancel();
    _introPlaybackStarted = false;

    _intro?.removeListener(_onIntroProgress);
    _intro?.pause();

    _stuckCount = 0;
    _lastPos = Duration.zero;

    if (!mounted) return;
    setState(() {
      _showingIntro = false;
      _showingInstruction = true;
    });

    unawaited(_initAndPlayInstruction());
  }

  void _startIntroTimeout() {
    final dur = _intro?.value.duration ?? const Duration(seconds: 10);
    final timeout = dur + const Duration(seconds: 4);

    _introTimeout?.cancel();
    _introTimeout = Timer(timeout, () {
      if (!mounted || _hasNavigated) return;
      if (!_introCompleted) {
        debugPrint('⏱️ INTRO TIMEOUT — forcing switch');
        _switchToInstruction();
      }
    });
  }

  void _startInstructionTimeout() {
    final dur = _instruction?.value.duration ?? const Duration(seconds: 10);
    final timeout = dur + const Duration(seconds: 4);

    _instructionTimeout?.cancel();
    _instructionTimeout = Timer(timeout, () {
      if (!mounted || _hasNavigated) return;
      if (!_instructionCompleted) {
        debugPrint('⏱️ INSTRUCTION TIMEOUT — navigating');
        _startFadeAndNavigate();
      }
    });
  }

  void _startPlaybackMonitor() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted || _hasNavigated) return;

      // Monitor only whichever is showing
      final controller =
          _showingIntro ? _intro : (_showingInstruction ? _instruction : null);

      if (controller == null || !controller.value.isInitialized) return;

      if (!identical(controller, _lastMonitoredController)) {
        _lastMonitoredController = controller;
        _playRetryCount = 0;
      }

      final v = controller.value;
      final pos = v.position;

      if (!v.isPlaying && pos == Duration.zero && _playRetryCount < 4) {
        _playRetryCount++;
        unawaited(controller.play());
      }

      // If it reports playing but position never advances, assume stuck.
      if (v.isPlaying && pos == _lastPos && pos.inMilliseconds > 0) {
        _stuckCount++;
        if (_stuckCount >= 6) {
          debugPrint('🔄 Video stuck ~3s — forcing continue');
          if (_showingIntro && !_introCompleted) {
            _switchToInstruction();
          } else {
            _startFadeAndNavigate();
          }
        }
      } else {
        _stuckCount = 0;
      }

      _lastPos = pos;
    });
  }

  Future<void> _startFadeAndNavigate() async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    debugPrint('🌟 FADE + NAVIGATE');

    _windowsStartGuard?.cancel();
    _firstFrameGuard?.cancel();
    _introTimeout?.cancel();
    _instructionTimeout?.cancel();
    _monitorTimer?.cancel();

    _intro?.pause();
    _instruction?.pause();

    _introPlaybackStarted = false;
    _instructionPlaybackStarted = false;
    _playRetryCount = 0;
    _lastMonitoredController = null;

    if (!mounted) return;
    setState(() {
      _showFade = true;
      _fadeOpacity = 0.0;
    });

    // Fade to white
    for (int i = 0; i <= 16; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() => _fadeOpacity = i / 16.0);
    }

    if (!mounted) return;
    setState(() {
      _showLatestPc = true;
      _latestPcOpacity = 0.0;
    });

    // Fade in splash image
    for (int i = 0; i <= 16; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      setState(() => _latestPcOpacity = i / 16.0);
    }

    await Future.delayed(const Duration(milliseconds: 800));

    if (!mounted) return;
    Navigator.pushReplacement(context, AppRouter.fadeToHomeReplacement());
  }

  Future<void> _disposeIntro() async {
    try {
      _intro?.removeListener(_onIntroProgress);
      await _intro?.dispose();
    } catch (_) {}
    if (identical(_lastMonitoredController, _intro)) {
      _lastMonitoredController = null;
    }
    _intro = null;
    _introInitialized = false;
    _introPlaybackStarted = false;
    _playRetryCount = 0;
  }

  Future<void> _disposeInstruction() async {
    try {
      _instruction?.removeListener(_onInstructionProgress);
      await _instruction?.dispose();
    } catch (_) {}
    if (identical(_lastMonitoredController, _instruction)) {
      _lastMonitoredController = null;
    }
    _instruction = null;
    _instructionInitialized = false;
    _instructionPlaybackStarted = false;
    _playRetryCount = 0;
  }

  @override
  void dispose() {
    _windowsStartGuard?.cancel();
    _firstFrameGuard?.cancel();
    _introTimeout?.cancel();
    _instructionTimeout?.cancel();
    _monitorTimer?.cancel();

    _intro?.removeListener(_onIntroProgress);
    _instruction?.removeListener(_onInstructionProgress);

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
          Positioned.fill(child: _buildVideoLayer()),

          if (_showFade)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _fadeOpacity,
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
                        fit: BoxFit.cover, // <- FULL SCREEN, not tiny
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Loader while intro is preparing
          if (!_introInitialized && !_hasNavigated && !_showLatestPc)
            const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white24),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoLayer() {
    if (_showingIntro && _introInitialized && _intro != null) {
      return _videoFitted(_intro!);
    }
    if (_showingInstruction && _instructionInitialized && _instruction != null) {
      return _videoFitted(_instruction!);
    }
    return const SizedBox.expand();
  }

  Widget _videoFitted(VideoPlayerController c) {
    final size = c.value.size;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(c),
          ),
        ),
      ),
    );
  }
}
