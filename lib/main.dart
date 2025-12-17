/// Theta Audio MVP - Main Application (ANDROID PRODUCTION)
///
/// VERSION: 2.0.0 - FIXED All 12 Issues
///
/// FIXES APPLIED:
/// 1. ✅ Added Google Fonts import
/// 2. ✅ Added 5-second delay before Divine Shuffle appears (wallpaper visibility)
/// 3. ✅ All dialogs now use Option 5 "Soft & Spiritual" styling
/// 4. ✅ "What is Theta" dialog has 350000ms auto-scroll
/// 5. ✅ "Guide Me Response" dialog has 30000ms auto-scroll
/// 6. ✅ All buttons use Google Fonts (Montserrat)
/// 7. ✅ All dialogs have ✦ black star icon with gold glow
/// 8. ✅ All dialogs have gold accent headers
/// 9. ✅ All dialogs have warm gradient backgrounds
/// 10. ✅ All dialogs have 4px gold borders

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:convert';
import 'prayers_list.dart';
import 'goliath_prayers_list.dart';
import 'audio_service.dart';
import 'package:http/http.dart' as http;
import 'intro_screen.dart';
import 'divine_shuffle_popup.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// OPTION 5 "SOFT & SPIRITUAL" COLORS - UNIVERSAL STYLING
// ═══════════════════════════════════════════════════════════════════════════════
const Color _goldAccent = Color(0xFFD4AF37);
const Color _warmBackground = Color(0xFFFFFEF9);
const Color _softBackground = Color(0xFFF9F6EF);
const Color _darkText = Color(0xFF2C2C2C);
const Color _bodyText = Color(0xFF444444);
const Color _subtitleText = Color(0xFF8B7355);

// Christian Persona Prompt for Guide Me AI
const String _christianPersonaPrompt = '''
You are the Ultimate Christian Spiritual Guide. Speak with conviction, humility, and strength – and base every assertion only on Christian Scripture. Your role is pastoral, exegetical, and practical: to explain, apply, and encourage using the Bible alone as your source of authority. Follow these rules exactly.

1. Scripture-only foundation.
   * Every doctrinal statement, pastoral counsel, comfort, admonition, or interpretation must be explicitly supported by Scripture. Quote or paraphrase the verse(s) and provide a clear citation (Book Chapter:Verse – e.g., Philippians 4:6–7). Do not rely on extra-biblical authorities to make doctrinal claims. You may use biblical cross-references to clarify context.

2. Tone: conviction + humility + tenderness.
   * Speak firmly about truth but always with gentleness, mercy, and pastoral sensitivity (cf. Ephesians 4:15; Galatians 6:1). Never posture as an infallible oracle. Use language that comforts the broken, corrects the wandering, and encourages the faithful.

3. Hermeneutic discipline.
   * Attend to literary context, author intent, audience, and immediate paragraph before generalizing. Prefer plain (canonical) readings over speculative ones. If multiple reasonable interpretations exist, present them briefly, identify supporting verses for each, and note where the text is ambiguous.

4. Clarity and simplicity.
   * Explain without unnecessary theological jargon. When technical terms are necessary, define them concisely and root definitions in Scripture.

5. Practical application.
   * After exegetical explanation, give one or two concrete, Scripture-rooted applications for life (personal, communal, worship, prayer). Always tie application back to the cited verse(s).

6. Citation style.
   * When quoting, include verse text (≤25 words verbatim unless a short excerpt is required) then cite Book Chapter:Verse and, if helpful, a cross-reference. Example: "Blessed are the peacemakers (Matthew 5:9)." If quoting more than 25 words, paraphrase and cite.

7. Pastoral safety & limits.
   * For urgent mental-health, suicide, abuse, medical, legal, or crisis issues: compassionately state that Scripture offers spiritual comfort (cite appropriate passages), but do not attempt to replace professional help. Encourage contacting local emergency services or qualified professionals and provide scripture-rooted encouragement while the user seeks help (e.g., Psalm 34:18; Psalm 147:3; Matthew 11:28). If user expresses intent to harm themselves or others, clearly and kindly insist they seek immediate help (emergency services) and provide scripture of comfort.

8. No proselytizing coercion; respect conscience.
   * When interacting with non-Christians or seekers, present Scripture plainly and lovingly, invite reflection, but do not coerce. Respect freedom of conscience (cf. Romans 14).

9. Humility about culture & politics.
   * Avoid partisan political advocacy. Apply biblical moral teaching to situations, but do not present party-political claims as Scripture. When a question is political in nature, answer from biblical principles and cite supporting verses.

10. Ask concise clarifying questions only when essential.
    * If a user's request lacks necessary context to answer responsibly (e.g., which Bible translation they prefer), ask a single brief clarifying question. Otherwise, make a best-effort answer from Scripture and note any assumptions.

11. Be accountable & transparent.
    * When you paraphrase interpretive moves, say so (e.g., "The text implies…"). When you infer practical steps, label them as application.

12. Examples of voice (templates).
    * Comforting: "The Lord draws near to the brokenhearted – Psalm 34:18 – and promises to carry the weary – Matthew 11:28–30. Let us pray and remember God's presence."
    * Correction: "Scripture warns against [behavior] – Galatians 5:19–21 – because it hinders fellowship with God. A way forward is… (application rooted in verse)."

Always finish answers with: (a) the primary verse(s) cited, and (b) one short spiritual practice (sentence) the user can try in the next 24–72 hours rooted in the same verse(s).

RESPONSE STYLE: Provide thorough, detailed responses with multiple Scripture references and extensive practical application. When appropriate, include historical context, cross-references to related passages, and comprehensive action steps.

Do not provide any teaching, explanation, or output until the user asks a question.
''';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ThetaApp());
}

class ThetaApp extends StatelessWidget {
  const ThetaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Theta Audio MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4BFF),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const IntroScreen(),
    );
  }
}

class ThetaHomePage extends StatefulWidget {
  const ThetaHomePage({super.key});

  @override
  State<ThetaHomePage> createState() => _ThetaHomePageState();
}

class _ThetaHomePageState extends State<ThetaHomePage> {
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
  static const Color _goliathActiveColor = Color(0xFF87CEEB); // Baby blue

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

  // ═══════════════════════════════════════════════════════════════════
  // OPTION 5 STYLED DIALOGS - ALL DIALOGS USE THIS STYLING
  // ═══════════════════════════════════════════════════════════════════

  /// Build Option 5 star icon with gold glow
  Widget _buildOption5StarIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            _goldAccent.withOpacity(0.3),
            _goldAccent.withOpacity(0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: const Center(
        child: Text(
          '✦',
          style: TextStyle(
            fontSize: 32,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HELPER: Scrollable with small round gold dot indicator
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildGoldDotScrollable({
    required ScrollController controller,
    required Widget child,
  }) {
    const dotSize = 8.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Main scrollable content
            SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              child: child,
            ),
            // Small round gold scroll indicator (8px circle)
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                double scrollFraction = 0.0;
                double maxScroll = 0.0;

                try {
                  if (controller.hasClients && controller.position.maxScrollExtent > 0) {
                    maxScroll = controller.position.maxScrollExtent;
                    scrollFraction = (controller.offset / maxScroll).clamp(0.0, 1.0);
                  }
                } catch (e) {
                  // Controller not yet attached
                }

                // alignY: -0.9 (top) to 0.9 (bottom) with padding
                final alignY = -0.9 + (scrollFraction * 1.8);

                return Align(
                  alignment: Alignment(0.98, alignY),
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      if (maxScroll <= 0) return;
                      final scrollDelta = details.delta.dy * (maxScroll / (constraints.maxHeight * 0.9));
                      final newOffset = (controller.offset + scrollDelta).clamp(0.0, maxScroll);
                      controller.jumpTo(newOffset);
                    },
                    child: Container(
                      width: dotSize,
                      height: dotSize,
                      decoration: const BoxDecoration(
                        color: _goldAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Build Option 5 styled dialog container
  Widget _buildOption5DialogContent({
    required String title,
    required String subtitle,
    required Widget content,
    ScrollController? scrollController,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
        maxWidth: MediaQuery.of(context).size.width * 0.9,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_warmBackground, _softBackground],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _goldAccent, width: 4),
        boxShadow: [
          BoxShadow(
            color: _goldAccent.withOpacity(0.25),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOption5StarIcon(),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: _goldAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _subtitleText,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            // Gold divider
            Container(height: 2, color: _goldAccent.withOpacity(0.3)),
            // Content section with gold dot scrollbar
            Flexible(
              child: _buildGoldDotScrollable(
                controller: scrollController!,
                child: content,
              ),
            ),
            // Close button
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _stopDialogAudioAndRestoreMusic();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _goldAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// FIX #7: "What is Theta" Dialog with Option 5 styling and 350000ms auto-scroll
  Future<void> _showAboutDialog() async {
    await _playDialogAudioWithMusicFade('audio/what_is_theta.mp3');

    final ScrollController scrollController = ScrollController();

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        // Auto-scroll DISABLED - user scrolls manually via gold dot

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: _buildOption5DialogContent(
            title: 'What is Theta?',
            subtitle: 'YOUR SPIRITUAL COMPANION',
            scrollController: scrollController,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What is Theta?',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _goldAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Theta is a powerful Prayer and Affirmation app, available on Windows and Mac personal computers, as well as Android and Apple cellphones.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'Theta features two modes of use:',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Theta Mode — Prayers are spoken aloud, and the user repeats (speaks) each line immediately.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Goliath Mode — Affirmations are spoken aloud, and the user repeats (speaks) each line immediately.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'The personal computer versions can be played through speakers or Bluetooth wireless earphones or earbuds, throughout your homes, bedrooms, children bedrooms or offices.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'The mobile versions can be played through device speakers or car audio systems, but is optimally enjoyed through a single Bluetooth wireless earbud - discreetly keeping you in a constant state of Theta throughout your day, irrelevant of your location or situation, helping you stay focused on what is most important, the Word of God and His Will for our lives.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Theta was designed to simulate its users to repeat each Prayer or Affirmation out aloud, or under their breath, either way "speaking" the transformative word of God.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _goldAccent, width: 2),
                  ),
                  child: Text(
                    'As that is where all the power lies.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: _goldAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Not in the Theta audio itself,',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'but in the living Word of God being "spoken" after each prayer or affirmation is played, and the heart of the person speaking, postured towards the Lord.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Our words have power because God hears them, God responds to them, and God uses them.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'We declare this not as self-generated power, but by calling on God\'s power.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'We do not command reality — we pray, affirm, proclaim, and bless using His authority.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Our words hold real influence — to build up or tear down — and God commands us to use them for life.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'We are instructed to speak God\'s Word with authority, daily.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'By repeatedly doing this, you enter into a state of "Theta", of total gratitude for Gods Power, constant favor and presence in your life.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 20),
                Text(
                  'Prayer Warfare',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _goldAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Prayer Warfare is talking to God — calling on His power, asking for intervention, binding and loosing, pleading Scripture, interceding, commanding in Jesus\' name - Praying is commanded (Eph. 6:18; 1 Thess. 5:17).',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 20),
                Text(
                  'Affirmation Warfare',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _goldAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Affirmation Warfare is declaring God\'s truth aloud — reminding yourself and the atmosphere of what God has already said (Scripture-based declarations), used to push back lies and reinforce faith - The Word is a weapon: "the sword of the Spirit" (Eph. 6:17).',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 20),
                Text(
                  'How to use Theta:',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _goldAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '• Say each Prayer or Affirmation out loud, deliberately, slowly.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Voice matters — speak audibly. The ear hears what the heart receives.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Use emotion and faith — speak with expectancy, not vain repetition.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Be consistent — spiritual fruit grows with steady discipline.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Not magic: this is not formulaic "name it and claim it" without God\'s will. It\'s faithful engagement with God\'s Word.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Humility: avoid prideful, self-centered tone. Subordinate declarations to God\'s will, always keep a surrendered heart.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Use each Prayer and Affirmation as a starting point to a longer prayer you engage with God through, adding your own personal requests, gratefulness and declarations after the prayer has finished playing.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 20),
                Text(
                  'Why use Prayers and Affirmations together',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _goldAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Prayer brings God\'s authority and action into the situation.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Affirmations reinforce your mind, heart, and the spiritual atmosphere with Scripture-based truth.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Together: you ask God and declare God\'s truth — you engage God and align your thinking with Him. That\'s both relational and authoritative.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Together, they are extremely powerful:',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• You pray for strength.\n• You affirm that God is your strength.\n• You pray for protection.\n• You affirm that no weapon formed against you will prosper.\n• You pray for peace.\n• You affirm that the peace of Christ rules in your heart.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 20),
                Text(
                  'Why it\'s called "warfare":',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _goldAccent,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Because negative thoughts, fear, discouragement, and spiritual pressure often come like attacks.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Prayers and Affirmations rooted in Scripture act like weapons, especially when spoken out loud:',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Truth replaces lies.\n• Faith replaces fear.\n• God\'s promises replace anxiety.\n• Identity replaces confusion.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'God creates, commands, heals, corrects, and blesses through spoken words — and Scripture connects that same principle to the believer\'s life.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'God didn\'t merely think creation — Scripture repeatedly emphasizes that He spoke it.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  '& as his children, we are called to do the same.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _goldAccent, width: 2),
                  ),
                  child: Text(
                    'Put simply:\n\nTheta Prayer and Affirmation warfare is fighting spiritual battles by speaking God\'s Word with authority.',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: _goldAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Let the story of your breakthrough begin, by echoing the word of God.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _goldAccent, width: 2),
                  ),
                  child: Text(
                    '"Death and life are in the power of the tongue." (Proverbs 18 verse 21)',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: _goldAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Speak Power Through Theta.',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _goldAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fight fire with Fire.',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _goldAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    scrollController.dispose();
    await _stopDialogAudioAndRestoreMusic();
  }

  /// FIX #9: Guide Me Info Dialog with Option 5 styling and auto-scroll
  Future<void> _showGuideMeInfo() async {
    await _playDialogAudioWithMusicFade('audio/guide_me_info.mp3');

    final ScrollController scrollController = ScrollController();

    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        // Auto-scroll DISABLED - user scrolls manually via gold dot

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: _buildOption5DialogContent(
            title: 'Guide Me',
            subtitle: 'AI-POWERED SCRIPTURE GUIDANCE',
            scrollController: scrollController,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'As human beings, every decision we make, needs to be in alignment with Gods will for our lives, according to the Word, and if not, then it is us and those we love who will indefinitely suffer the consequences, leaving us trapped in the rat-race of modern society, most times with labor and effort in vain and fruitlessness.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'Theta presents a powerful Ai engineered model called "Guide Me", which when activated - will enquire how it can assist you, according to the Word of God.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'This feature essentially makes Theta a powerful Christian LLM search engine, like ChatGPT, Gemini, Grok, but with all outputs guided and governed by the principles of the Word of God, and the teachings therein.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'Unlike how ChatGPT, Gemini, Grok or any other mainstream LLM will currently respond if you start a chat, with the AI responding in its default, generic voice — mixing opinions, culture & psychology, which in most cases is far from the teachings supplied by the Word of God, the Bible.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'The Theta "Guide Me" model will respond with strict guidance and reference to scripture only - Equating to undiluted, clear guidance and reference according to the Word of God.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    border: Border.all(color: _goldAccent, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '"Seek first the Kingdom of God and His righteousness, and all these things will be added unto you"',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: _goldAccent,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Basically "Do God\'s work first, then through prayer and petition with thanksgiving, present your requests to God"',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your first message should be:',
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: _darkText),
                ),
                const SizedBox(height: 10),
                Text(
                  '• Clear\n• Purposeful\n• Direct',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'Give as much detail as possible to your situation, your challenge, or your requirements - The engineered "Guide Me" model is exceptionally clever and can handle all details, stories, descriptions etc one gives it.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 20),
                Text(
                  'Examples:',
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600, color: _darkText),
                ),
                const SizedBox(height: 10),
                // Example 1
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _goldAccent.withOpacity(0.05),
                    border: Border.all(color: _goldAccent.withOpacity(0.3), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"My wife and I have been married for X years, yet there is always these hidden agendas, secrets and white lies in our marriage, I\'d love to approach her and ask her to stop this once and for all, and help me regain trust in her, so I can stop doubting her and our marriage, feel safe and open up to her, but when ever I do, it always ends up in a massive argument with her resenting me. What can I do?"',
                    style: GoogleFonts.lora(fontSize: 13, height: 1.6, fontStyle: FontStyle.italic, color: _bodyText),
                  ),
                ),
                // Example 2
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _goldAccent.withOpacity(0.05),
                    border: Border.all(color: _goldAccent.withOpacity(0.3), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"I am experiencing spiritual exhaustion in my family. What does Scripture teach about renewing strength?"',
                    style: GoogleFonts.lora(fontSize: 13, height: 1.6, fontStyle: FontStyle.italic, color: _bodyText),
                  ),
                ),
                // Example 3
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _goldAccent.withOpacity(0.05),
                    border: Border.all(color: _goldAccent.withOpacity(0.3), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"Today is a Sunday, I am Christian and Christian\'s are forbidden to work on Sundays, but I want to work on a free Christian book to advance Gods Kingdom, I will be giving the book away for free, can I work on the book today?"',
                    style: GoogleFonts.lora(fontSize: 13, height: 1.6, fontStyle: FontStyle.italic, color: _bodyText),
                  ),
                ),
                // Example 4
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _goldAccent.withOpacity(0.05),
                    border: Border.all(color: _goldAccent.withOpacity(0.3), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"Let us begin in prayer about forgiveness of a family member / work colleague / friend."',
                    style: GoogleFonts.lora(fontSize: 13, height: 1.6, fontStyle: FontStyle.italic, color: _bodyText),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Be descriptive, the more information you feed into "Guide Me", the more value you will get back in return.',
                  style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Enjoy Theta',
                    style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: _darkText),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '& enjoy being guided by scripture.',
                    style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.w600, color: _goldAccent),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );

    scrollController.dispose();
    await _stopDialogAudioAndRestoreMusic();
  }

  /// FIX #8 & #11: Guide Me Response Dialog with Option 5 styling and 30000ms auto-scroll
Future<void> _showResponseDialog(String response) async {
  await _duckMusicForIntro();
  final ScrollController scrollController = ScrollController();

  await showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: _buildOption5DialogContent(
          title: 'Scripture Guidance',
          subtitle: 'WISDOM FROM THE WORD',
          scrollController: scrollController,
          content: SelectableText(
            response,
            style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
          ),
        ),
      );
    },
  );

  scrollController.dispose();
  await _restoreMusicAfterIntro();
}

  Future<void> _showErrorDialog(String message) async {
    final ScrollController scrollController = ScrollController();
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: _buildOption5DialogContent(
          title: 'Gentle Alert',
          subtitle: 'SOFT & SPIRITUAL NOTICE',
          scrollController: scrollController,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _goldAccent, width: 3),
                    ),
                    child: const Icon(Icons.error_outline, color: _goldAccent, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Something needs attention',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _darkText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: GoogleFonts.lora(fontSize: 14, color: _bodyText, height: 1.6),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _goldAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _goldAccent, width: 1.5),
                ),
                child: Text(
                  'Take a breath, then try again. If the issue continues, check your connection and keep worshipping.',
                  style: GoogleFonts.lora(fontSize: 12.5, height: 1.5, color: _bodyText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    scrollController.dispose();
  }

  /// FIX #10: Prayer Intervals Dialog with Option 5 styling
  Future<void> _showIntervalSelection() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_warmBackground, _softBackground],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: _goldAccent, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: _goldAccent.withOpacity(0.25),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(21),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildOption5StarIcon(),
                            const SizedBox(height: 12),
                            Text(
                              'Prayer Intervals',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: _goldAccent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SELECT YOUR RHYTHM',
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _subtitleText,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 2, color: _goldAccent.withOpacity(0.3)),
                      // Interval buttons
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildOption5IntervalTile('3 minutes', 3, setDialogState),
                            const SizedBox(height: 10),
                            _buildOption5IntervalTile('5 minutes', 5, setDialogState),
                            const SizedBox(height: 10),
                            _buildOption5IntervalTile('10 minutes', 10, setDialogState),
                            const SizedBox(height: 20),
                            Container(height: 1, color: _goldAccent.withOpacity(0.3)),
                            const SizedBox(height: 16),
                            // Music toggle
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Background Music',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _darkText,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () async {
                                    await _toggleBackgroundMusic();
                                    setDialogState(() {});
                                    setState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _isMusicPlaying
                                          ? _goldAccent.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isMusicPlaying ? _goldAccent : Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      _isMusicPlaying ? Icons.music_note : Icons.music_off,
                                      color: _isMusicPlaying ? _goldAccent : Colors.red,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Close button
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _goldAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Done',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOption5IntervalTile(String label, int minutes, StateSetter setDialogState) {
    final isSelected = _selectedInterval == minutes;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedInterval = minutes;
        });
        setDialogState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? _goldAccent.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _goldAccent : const Color(0xFFDDDDDD),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: _goldAccent.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(Icons.check_circle, color: _goldAccent, size: 22),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _goldAccent : _darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
