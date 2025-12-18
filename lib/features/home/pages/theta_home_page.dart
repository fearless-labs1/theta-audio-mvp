import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:theta_audio_mvp/audio_service.dart';
import 'package:theta_audio_mvp/core/constants/app_colors.dart';
import 'package:theta_audio_mvp/core/constants/prompts.dart';
import 'package:theta_audio_mvp/divine_shuffle_popup.dart';
import 'package:theta_audio_mvp/prayer_texts.dart';
part 'theta_home_dialogs.dart';

const Color _goldAccent = AppColors.goldAccent;
const Color _warmBackground = AppColors.warmBackground;
const Color _softBackground = AppColors.softBackground;
const Color _darkText = AppColors.darkText;
const Color _bodyText = AppColors.bodyText;
const Color _subtitleText = AppColors.subtitleText;
const Color _goliathActiveColor = AppColors.goliathActiveColor;
const String _christianPersonaPrompt = Prompts.christianPersona;

class ThetaHomePage extends StatefulWidget {
  const ThetaHomePage({super.key});

  @override
  State<ThetaHomePage> createState() => _ThetaHomePageState();
}

class _ThetaHomePageState extends State<ThetaHomePage> with _DialogBuilders {
  // Audio service instance
  final ThetaAudioService _audioService = ThetaAudioService();

  // SEPARATE audio player for dialog TTS (What is Theta, Guide Me info)
  final AudioPlayer _dialogAudioPlayer = AudioPlayer();
  StreamSubscription<void>? _dialogCompleteSubscription;
  StreamSubscription<String>? _dialogErrorSubscription;

  // Background music player (Yeshua / David songs)
  AudioPlayer? _musicPlayer;

  // Background music state
  bool _isMusicPlaying = true;
  bool _musicInitialized = false;

  // PRESERVED EXACTLY: Volume settings for Android (logarithmic scale)
  static const double _yeshuaMusicVolume = 0.5;  // 50% for Yeshua (normal)
  static const double _davidMusicVolume = 0.8;   // 80% for David (louder)
  static const double _prayerMusicVolume = 0.10; // 10% during prayer (Android logarithmic)
  static const double _dialogMusicVolume = 0.05; // 5% during dialog TTS

  String _currentMusicPath = 'audio/Yeshua _ song.mp3';

  // App state
  bool _isActive = false;
  bool _isInitialized = false;
  String? _errorMessage;
  int _selectedInterval = 10;

  // Divine Shuffle state - FIX: Start as FALSE, show after 5 second delay
  bool _showDivineShuffle = false;
  bool _introComplete = false;
  String? _currentPrayerPath;
  String? _currentPrayerNumber;
  String? _currentPrayerName;
  final GlobalKey<DivineShufflePopupState> _divineShuffleKey = GlobalKey();

  // Background fade state (white → pitch black)
  double _backgroundOpacity = 0.0; // Starts at 0.0 (invisible), fades to 1.0 over 4 seconds
  bool _backgroundFadeStarted = false;

  // Status auto-refresh timer
  Timer? _statusRefreshTimer;
  Timer? _wallpaperFadeTimer;
  Timer? _backgroundFadeTimer;

  // Guide Me
  final TextEditingController _guideMeController = TextEditingController();
  bool _isLoadingGPTResponse = false;

  // Goliath Mode
  bool _isGoliathMode = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {

      // Initialize audio service
      await _audioService.initialize();

      // Set callbacks for audio service
      _audioService.onStatusChanged = (isActive) {
        if (mounted) {
          setState(() {
            _isActive = isActive;
          });
        }
      };

      // Set callbacks for music volume coordination (prayer start/end)
      _audioService.onPrayerStart = _onPrayerStart;
      _audioService.onPrayerEnd = _onPrayerEnd;

      // NEW: Set callback for Divine Shuffle sync
      _audioService.onPrayerChanged = _onPrayerChanged;

      // Initialize background music (non-critical - continue if fails)
      try {
        await _initializeBackgroundMusic();
      } catch (e) {
        debugPrint('⚠️ Background music initialization failed (non-critical): $e');
      }

      // Start status auto-refresh timer (every 1 minute)
      _statusRefreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        if (mounted && _isActive && !_isGoliathMode) {
          setState(() {}); // Triggers UI rebuild to update time status
        }
      });

      setState(() {
        _isInitialized = true;
      });

      debugPrint('✅ Theta Android Production initialized');

      // Start wallpaper fade-in over 4 seconds (opacity 0→1)
      _startWallpaperFadeIn();

      // Divine Shuffle appears at 7 seconds (3 seconds after wallpaper fade-in completes at 4s)
      Future.delayed(const Duration(seconds: 7), () {
        if (mounted) {
          debugPrint('🔀 7-second delay complete - showing Divine Shuffle');
          setState(() {
            _showDivineShuffle = true;
          });
          // Start background fade AFTER Divine Shuffle appears
          _startBackgroundFade();
        }
      });

    } catch (e) {
      // Cleanup on critical failure
      _statusRefreshTimer?.cancel();
      setState(() {
        _errorMessage = 'Failed to initialize: $e';
        _isInitialized = false;
      });
    }
  }

  /// NEW: Called when prayer changes (Divine Shuffle sync)
  void _onPrayerChanged(String prayerPath) {
    debugPrint('🔀 Prayer changed: $prayerPath');
    setState(() {
      _currentPrayerPath = prayerPath;
      _currentPrayerNumber = PrayerTexts.getPrayerNumber(prayerPath);
      _currentPrayerName = PrayerTexts.getPrayerName(prayerPath);
    });
  }

  /// Initialize background music
  Future<void> _initializeBackgroundMusic() async {
    try {
      debugPrint('🎵 Initializing background music...');

      _musicPlayer = AudioPlayer();

      // CRITICAL FIX: Set audio context to allow mixing with other audio
      await _musicPlayer!.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.duckOthers,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck,
        ),
      ));

      // Set to loop mode
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);

      // Set volume for Yeshua (50%)
      await _musicPlayer!.setVolume(_yeshuaMusicVolume);

      // Start playing Yeshua song
      await _musicPlayer!.play(AssetSource('audio/Yeshua _ song.mp3'));

      _musicInitialized = true;
      _isMusicPlaying = true;
      _currentMusicPath = 'audio/Yeshua _ song.mp3';

      debugPrint('✅ Background music started (Yeshua song at 50%)');

    } catch (e) {
      debugPrint('⚠️ Could not start background music: $e');
    }
  }

  /// Toggle background music on/off
  Future<void> _toggleBackgroundMusic() async {
    if (_musicPlayer == null) return;

    try {
      if (_isMusicPlaying) {
        await _musicPlayer!.pause();
        setState(() {
          _isMusicPlaying = false;
        });
        debugPrint('🔇 Background music paused');
      } else {
        // Restore to correct volume based on mode
        final currentVolume = _isGoliathMode ? _davidMusicVolume : _yeshuaMusicVolume;
        await _musicPlayer!.setVolume(currentVolume);
        await _musicPlayer!.resume();
        setState(() {
          _isMusicPlaying = true;
        });
        debugPrint('🎵 Background music resumed');
      }
    } catch (e) {
      debugPrint('⚠️ Error toggling music: $e');
    }
  }

  /// PRESERVED: Called when prayer starts - fade music to 10%
  void _onPrayerStart() {
    if (_isMusicPlaying && _musicPlayer != null) {
      final fromVolume = _isGoliathMode ? _davidMusicVolume : _yeshuaMusicVolume;
      _fadeVolume(fromVolume, _prayerMusicVolume, 1000);
      debugPrint('🔉 Music fading to 10% for prayer...');
    }
  }

  /// PRESERVED: Called when prayer ends - restore music volume
  void _onPrayerEnd() {
    if (_isMusicPlaying && _musicPlayer != null) {
      final toVolume = _isGoliathMode ? _davidMusicVolume : _yeshuaMusicVolume;
      _fadeVolume(_prayerMusicVolume, toVolume, 1000);
      debugPrint('🔊 Music fading back to ${_isGoliathMode ? "80%" : "50%"}...');
    }
  }

  /// Smoothly fade volume (20 steps, 1000ms duration)
  Future<void> _fadeVolume(double from, double to, int durationMs) async {
    if (_musicPlayer == null || !mounted) return;

    const int steps = 20;
    final int stepDuration = durationMs ~/ steps;
    final double volumeStep = (to - from) / steps;

    double currentVolume = from;

    for (int i = 0; i < steps; i++) {
      if (!mounted || _musicPlayer == null) return;

      currentVolume += volumeStep;
      await _musicPlayer!.setVolume(currentVolume.clamp(0.0, 1.0));
      await Future.delayed(Duration(milliseconds: stepDuration));
    }

    if (mounted && _musicPlayer != null) {
      await _musicPlayer!.setVolume(to);
    }
  }

  /// PRESERVED: Fade music for dialog audio (What is Theta, Guide Me info)
  Future<void> _playDialogAudioWithMusicFade(String assetPath) async {
    try {
      debugPrint('🎵 Playing dialog audio: $assetPath');

      // STEP 1: Fade music down to 5% FIRST
      if (_isMusicPlaying && _musicPlayer != null) {
        final fromVolume = _isGoliathMode ? _davidMusicVolume : _yeshuaMusicVolume;
        await _fadeVolume(fromVolume, _dialogMusicVolume, 500);
        debugPrint('🔉 Music faded to 5% for dialog TTS');
      }

      // STEP 2: Configure dialog player
      await _dialogAudioPlayer.setAudioContext(AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {
            AVAudioSessionOptions.mixWithOthers,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
      ));

      // STEP 3: Stop any current dialog playback
      await _dialogAudioPlayer.stop();

      // STEP 4: Set volume to MAXIMUM
      await _dialogAudioPlayer.setVolume(1.0);

      // STEP 5: Listen for completion to restore music volume
      // This must be done BEFORE playing to avoid a race condition where the
      // audio completes before the listener is attached.
      await _dialogCompleteSubscription?.cancel();
      _dialogCompleteSubscription = _dialogAudioPlayer.onPlayerComplete.listen((event) {
        debugPrint('🔔 Dialog TTS complete - restoring music volume');
        _restoreMusicVolumeAfterDialog();
      });

      await _dialogErrorSubscription?.cancel();
      _dialogErrorSubscription = _dialogAudioPlayer.onPlayerError.listen((msg) {
        debugPrint('⚠️ Dialog playback error: $msg');
        _restoreMusicVolumeAfterDialog();
      });

      // STEP 6: Play dialog audio
      await _dialogAudioPlayer.play(AssetSource(assetPath));
      debugPrint('✅ Dialog TTS playing at FULL volume');

    } catch (e) {
      debugPrint('⚠️ Could not play dialog audio: $e');
      _restoreMusicVolumeAfterDialog();
      // Also cancel the listeners we just created to avoid them lingering.
      _dialogCompleteSubscription?.cancel();
      _dialogErrorSubscription?.cancel();
    }
  }

  /// Restore music volume after dialog audio finishes
  Future<void> _restoreMusicVolumeAfterDialog() async {
    if (_isMusicPlaying && _musicPlayer != null) {
      final toVolume = _isGoliathMode ? _davidMusicVolume : _yeshuaMusicVolume;
      await _fadeVolume(_dialogMusicVolume, toVolume, 500);
      debugPrint('🔊 Music restored after dialog');
    }
  }

  /// Stop dialog audio and restore music (called when dialog closes)
  Future<void> _stopDialogAudioAndRestoreMusic() async {
    await _dialogAudioPlayer.stop();
    await _restoreMusicVolumeAfterDialog();
  }

  /// Duck music to 5% for intro TTS (Welcome to Theta, Divine Shuffle, How to Use)
  Future<void> _duckMusicForIntro() async {
    if (_isMusicPlaying && _musicPlayer != null) {
      final fromVolume = _isGoliathMode ? _davidMusicVolume : _yeshuaMusicVolume;
      await _fadeVolume(fromVolume, _dialogMusicVolume, 500);
      debugPrint('🔉 Music ducked to 5% for intro TTS');
    }
  }

  /// Restore music volume after intro TTS finishes
  Future<void> _restoreMusicAfterIntro() async {
    if (_isMusicPlaying && _musicPlayer != null) {
      final toVolume = _isGoliathMode ? _davidMusicVolume : _yeshuaMusicVolume;
      await _fadeVolume(_dialogMusicVolume, toVolume, 500);
      debugPrint('🔊 Music restored after intro TTS');
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // THETA CONTROL FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _startTheta() async {
    try {
      await _audioService.startTheta(intervalMinutes: _selectedInterval);
      setState(() {
        _isActive = true;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start: $e';
      });
    }
  }

  Future<void> _stopTheta() async {
    try {
      await _audioService.stopTheta();
      setState(() {
        _isActive = false;
        _errorMessage = null;
        _currentPrayerPath = null;
        _currentPrayerNumber = null;
        _currentPrayerName = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to stop: $e';
      });
    }
  }

  /// START / REPEAT dual function button handler
  Future<void> _startOrRepeat() async {
    if (_isActive) {
      // REPEAT current prayer
      try {
        await _audioService.repeatCurrentPrayer();
        debugPrint('🔄 Prayer repeated via dual-function button');
      } catch (e) {
        debugPrint('❌ Error repeating prayer: $e');
      }
    } else {
      // START Theta
      await _startTheta();
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // GOLIATH MODE FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _toggleGoliathMode() async {
    if (_isGoliathMode) {
      await _stopGoliathMode();
    } else {
      await _startGoliathMode();
    }
  }

  Future<void> _startGoliathMode() async {
    debugPrint('🗡️ Starting Goliath Mode...');

    // Stop Theta if running
    if (_isActive) {
      await _stopTheta();
    }

    // Fade out current music completely
    if (_isMusicPlaying && _musicPlayer != null) {
      await _fadeVolume(_yeshuaMusicVolume, 0.0, 1500);
      await _musicPlayer!.stop();
    }

    // Switch to David music
    _currentMusicPath = 'audio/David.mp3';

    if (_musicPlayer != null) {
      try {
        await _musicPlayer!.setAudioContext(AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ));

        await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
        await _musicPlayer!.setVolume(0.0);
        await _musicPlayer!.play(AssetSource('audio/David.mp3'));

        // Fade in David music to 80%
        await _fadeVolume(0.0, _davidMusicVolume, 1500);
        _isMusicPlaying = true;
        debugPrint('🎵 David music started at 80% volume');
      } catch (e) {
        debugPrint('⚠️ Error starting David music: $e');
      }
    }

    setState(() {
      _isGoliathMode = true;
    });

    // Start Goliath prayers
    await _audioService.startGoliathMode(intervalMinutes: _selectedInterval);

    setState(() {
      _isActive = true;
    });

    debugPrint('🗡️ Goliath Mode ACTIVATED');
  }

  Future<void> _stopGoliathMode() async {
    debugPrint('🗡️ Stopping Goliath Mode...');

    // Stop Goliath prayers (stopTheta works for both modes)
    await _audioService.stopTheta();

    // Fade out David music
    if (_isMusicPlaying && _musicPlayer != null) {
      await _fadeVolume(_davidMusicVolume, 0.0, 1500);
      await _musicPlayer!.stop();
    }

    // Short cooldown
    await Future.delayed(const Duration(milliseconds: 500));

    // Switch back to Yeshua music at 50%
    _currentMusicPath = 'audio/Yeshua _ song.mp3';

    if (_musicPlayer != null) {
      try {
        await _musicPlayer!.setAudioContext(AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.duckOthers,
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ));

        await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
        await _musicPlayer!.setVolume(_yeshuaMusicVolume);
        await _musicPlayer!.play(AssetSource('audio/Yeshua _ song.mp3'));
        _isMusicPlaying = true;
        debugPrint('🎵 Yeshua music resumed at 50% volume');
      } catch (e) {
        debugPrint('⚠️ Error resuming Yeshua music: $e');
      }
    }

    setState(() {
      _isGoliathMode = false;
      _isActive = false;
      _currentPrayerPath = null;
      _currentPrayerNumber = null;
      _currentPrayerName = null;
    });

    debugPrint('🗡️ Goliath Mode DEACTIVATED');
  }

  // ═══════════════════════════════════════════════════════════════════
  // STATUS TEXT FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════

  String _getFullTimeStatus() {
    final hour = DateTime.now().hour;
    final now = DateTime.now();
    final timeString = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

    if (hour >= 5 && hour < 11) {
      return '🌅 Morning Prayers ($timeString)';
    } else if (hour >= 11 && hour < 18) {
      return '☀️ Mid-day Prayers ($timeString)';
    } else {
      return '🌙 Evening Prayers ($timeString)';
    }
  }

  String _getStatusText() {
    if (_isGoliathMode) {
      return 'Goliath Mode: Spiritual Warfare';
    } else if (_isActive) {
      return _getFullTimeStatus();
    } else {
      return 'Theta Inactive';
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // DIVINE SHUFFLE PHASE 1 COMPLETE CALLBACK
  // ═══════════════════════════════════════════════════════════════════

  void _onPhase1Complete() {
    debugPrint('🔀 Divine Shuffle Phase 1 complete - buttons now enabled');
    setState(() {
      _introComplete = true;
    });
  }

  /// Check if buttons should be disabled (during intro)
  bool get _buttonsDisabled {
    if (!_showDivineShuffle) return true; // Also disabled before Divine Shuffle appears
    return !_introComplete;
  }

  Widget _buildPrayerSyncBadge() {
    if (_currentPrayerPath == null || _currentPrayerNumber == null || _currentPrayerName == null) {
      return const SizedBox.shrink();
    }

    final isGoliath = _currentPrayerNumber!.startsWith('G');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isGoliath ? _goliathActiveColor : _goldAccent, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: (isGoliath ? _goliathActiveColor : _goldAccent).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isGoliath ? _goliathActiveColor : _goldAccent).withOpacity(0.15),
              border: Border.all(color: isGoliath ? _goliathActiveColor : _goldAccent, width: 2),
            ),
            child: const Text(
              '✦',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isGoliath ? 'Spiritual Warfare' : 'Divine Shuffle Synced',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _darkText,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '#${_currentPrayerNumber!}  ·  ${_currentPrayerName!}',
                style: GoogleFonts.lora(
                  fontSize: 12,
                  height: 1.3,
                  color: _bodyText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // GUIDE ME AI FUNCTIONS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _sendQuestionToGPT(String question) async {
    final trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) {
      _showErrorDialog('Please enter a question before submitting.');
      return;
    }

    setState(() {
      _isLoadingGPTResponse = true;
    });

    try {
      const apiUrl = 'https://theta-backend.vercel.app/api/guide-me';

      debugPrint('📤 Sending Guide Me request...');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'question': trimmedQuestion,
          'systemPrompt': _christianPersonaPrompt,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final answer = data['response'] ?? data['answer'] ?? 'No response received';

        _guideMeController.clear();
        _showResponseDialog(answer);

        debugPrint('✅ Guide Me response received');
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Guide Me error: $e');
      _showErrorDialog('Unable to get guidance. Please try again.');
    } finally {
      setState(() {
        _isLoadingGPTResponse = false;
      });
    }
  }

  // Dialog helpers moved to part file
  /// Fade wallpaper into view over 4 seconds (opacity 0→1)
  void _startWallpaperFadeIn() {
    debugPrint('🌅 Starting wallpaper fade-in (4 seconds)');

    const fadeSteps = 40;
    const fadeStepMs = 100; // 4000ms / 40 steps = 100ms per step

    int step = 0;
    _wallpaperFadeTimer?.cancel();
    _wallpaperFadeTimer = Timer.periodic(const Duration(milliseconds: fadeStepMs), (timer) {
      step++;
      if (!mounted || step >= fadeSteps) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _backgroundOpacity = 1.0;
          });
        }
        debugPrint('🌅 Wallpaper fade-in complete - fully visible');
        return;
      }

      setState(() {
        _backgroundOpacity = step / fadeSteps;
      });
    });
  }

  void _startBackgroundFade() {
    if (_backgroundFadeStarted) return;
    _backgroundFadeStarted = true;

    // Cancel the wallpaper fade-in timer to prevent conflicting animations.
    _wallpaperFadeTimer?.cancel();

    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      debugPrint('🌑 Starting background fade to pitch black (4000ms)');
      const fadeSteps = 40;
      const fadeStepMs = 100;
      int step = 0;
      _backgroundFadeTimer?.cancel();
      _backgroundFadeTimer = Timer.periodic(const Duration(milliseconds: fadeStepMs), (timer) {
        step++;
        if (!mounted || step >= fadeSteps) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _backgroundOpacity = 0.0;
            });
          }
          debugPrint('🌑 Background fade complete - pitch black');
          return;
        }
        if (mounted) {
          setState(() {
            _backgroundOpacity = 1.0 - (step / fadeSteps);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _wallpaperFadeTimer?.cancel();
    _backgroundFadeTimer?.cancel();
    _statusRefreshTimer?.cancel();
    _audioService.dispose();
    _dialogCompleteSubscription?.cancel();
    _dialogErrorSubscription?.cancel();
    _dialogAudioPlayer.dispose();
    _musicPlayer?.dispose();
    _guideMeController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // UI BUILD - All buttons now use Google Fonts
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // LAYER 1: Background wallpaper with opacity fade
          Positioned.fill(
            child: Opacity(
              opacity: _backgroundOpacity,
              child: Image.asset(
                'assets/images/LATEST MOBILE.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // LAYER 2: Pitch black background (fades in as wallpaper fades out)
          Positioned.fill(
            child: Opacity(
              opacity: 1.0 - _backgroundOpacity,
              child: Container(color: Colors.black),
            ),
          ),

          // LAYER 2.5: Goliath ambience overlay
          if (_isGoliathMode)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _goliathActiveColor.withOpacity(0.28),
                      Colors.black.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
            ),

          // LAYER 3: Main UI content
          SafeArea(
            child: Column(
              children: [
                // TOP BUTTONS ROW - Light grey buttons with Google Fonts
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // What is Theta button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _buttonsDisabled ? null : _showAboutDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            disabledBackgroundColor: Colors.grey[400],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            'What is Theta',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _buttonsDisabled ? Colors.grey[600] : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Prayer Intervals button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _buttonsDisabled ? null : _showIntervalSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            disabledBackgroundColor: Colors.grey[400],
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                          ),
                          child: Text(
                            'Prayer Intervals',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _buttonsDisabled ? Colors.grey[600] : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // DIVINE SHUFFLE POPUP (positioned below top buttons, above status)
                Expanded(
                  child: Column(
                    children: [
                      // Aesthetic gap above Divine Shuffle
                      const SizedBox(height: 8),

                      // DIVINE SHUFFLE POPUP - only shows after 5 second delay
                      // When not visible, use Expanded spacer to push Status/Guide Me to bottom
                      if (_showDivineShuffle)
                        Expanded(
                          child: DivineShufflePopup(
                            key: _divineShuffleKey,
                            isVisible: _showDivineShuffle,
                            isGoliathMode: _isGoliathMode,
                            currentPrayerPath: _currentPrayerPath,
                            onPhase1Complete: _onPhase1Complete,
                            onTTSStart: _duckMusicForIntro,
                            onTTSComplete: _restoreMusicAfterIntro,
                          ),
                        )
                      else
                        const Expanded(child: SizedBox()), // Spacer keeps bottom elements in position

                      // Aesthetic gap below Divine Shuffle
                      const SizedBox(height: 8),

                      // STATUS INDICATOR - above Guide Me search bar
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isGoliathMode
                                  ? _goliathActiveColor
                                  : (_isActive ? Colors.green : Colors.red),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _isGoliathMode
                                      ? _goliathActiveColor
                                      : (_isActive ? Colors.green : Colors.red),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _getStatusText(),
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Prayer sync + context
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: _buildPrayerSyncBadge(),
                      ),

                      const SizedBox(height: 10),

                      // GUIDE ME SEARCH BAR
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey[400]!, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Guide Me button (left ~30%)
                            SizedBox(
                              width: 100,
                              child: ElevatedButton(
                                onPressed: _buttonsDisabled ? null : _showGuideMeInfo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _buttonsDisabled ? Colors.grey : Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.explore, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Guide Me',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Text input field (right ~70%)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: TextField(
                                  controller: _guideMeController,
                                  enabled: !_buttonsDisabled,
                                  decoration: InputDecoration(
                                    hintText: 'Ask your question...',
                                    hintStyle: GoogleFonts.lora(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  style: GoogleFonts.lora(fontSize: 12),
                                  onSubmitted: (value) {
                                    if (!_isLoadingGPTResponse && !_buttonsDisabled) {
                                      _sendQuestionToGPT(value);
                                    }
                                  },
                                ),
                              ),
                            ),
                            // Magnifying glass button
                            IconButton(
                              icon: const Icon(Icons.search, size: 20),
                              color: _buttonsDisabled ? Colors.grey : Colors.black,
                              onPressed: (_isLoadingGPTResponse || _buttonsDisabled)
                                  ? null
                                  : () => _sendQuestionToGPT(_guideMeController.text),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // BOTTOM BUTTONS SECTION - All with Google Fonts
                Container(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 30),
                  child: Column(
                    children: [
                      // Row 1: START/REPEAT and STOP buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // START / REPEAT button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_isGoliathMode || _buttonsDisabled) ? null : _startOrRepeat,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                disabledBackgroundColor: Colors.grey[400],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow, size: 22, color: (_isGoliathMode || _buttonsDisabled) ? Colors.grey : Colors.green),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Start / Repeat',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: (_isGoliathMode || _buttonsDisabled) ? Colors.grey : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // STOP THETA button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (!_isActive || _isGoliathMode || _buttonsDisabled) ? null : _stopTheta,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                disabledBackgroundColor: Colors.grey[400],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.stop, size: 22, color: (_isActive && !_isGoliathMode && !_buttonsDisabled) ? Colors.red : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Stop Theta',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: (_isActive && !_isGoliathMode && !_buttonsDisabled) ? Colors.black : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Row 2: GOLIATH MODE button - BRIGHT BLUE when active
                      SizedBox(
                        width: 180,
                        child: ElevatedButton(
                          onPressed: _buttonsDisabled ? null : _toggleGoliathMode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isGoliathMode ? _goliathActiveColor : Colors.grey[300],
                            disabledBackgroundColor: Colors.grey[400],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 4,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.shield,
                                size: 22,
                                color: _buttonsDisabled
                                    ? Colors.grey[600]
                                    : (_isGoliathMode ? Colors.white : Colors.black),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isGoliathMode ? 'Deactivate' : 'Goliath Mode',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _buttonsDisabled
                                      ? Colors.grey[600]
                                      : (_isGoliathMode ? Colors.white : Colors.black),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading indicator for Guide Me API calls
          if (_isLoadingGPTResponse)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_goldAccent),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Seeking guidance from Scripture...',
                      style: GoogleFonts.lora(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Error message overlay
          if (_errorMessage != null)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  _errorMessage!,
                  style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Initialization loading
          if (!_isInitialized && _errorMessage == null)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing Theta...',
                      style: GoogleFonts.lora(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
