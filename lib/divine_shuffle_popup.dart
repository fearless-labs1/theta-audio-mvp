/// Theta Audio MVP - Divine Shuffle™ Popup Widget (ANDROID MOBILE)
/// 
/// VERSION: 6.3.0 - FIXED Auto-Scroll Speeds Per Screen
/// 
/// FIXES APPLIED:
/// 1. ✅ Prayer text now uses FULL OPACITY (was 80% - too faint)
/// 2. ✅ Prayer text is now SCROLLABLE (was truncated to 2 lines)
/// 3. ✅ Increased font size from 11 to 12 for better readability
/// 4. ✅ Added fontWeight: FontWeight.w500 for bolder text
/// 5. ✅ Prayer card height increased to accommodate scrolling
/// 
/// VERSION 6.3.0 FIXES (Auto-Scroll Speed Issues):
/// 6. ✅ Part 1 "Welcome to Theta": FASTER scroll (25 sec, was 45 sec - TOO SLOW)
/// 7. ✅ Part 2 "Divine Shuffle": Now starts at TOP (was starting midway)
/// 8. ✅ Part 2 "Divine Shuffle": SLOWER scroll (90 sec, was 45 sec - TOO FAST)
/// 9. ✅ Part 3 "How to Theta": SLOWER scroll (100 sec, was 45 sec - TOO FAST)
/// 10. ✅ All scroll controllers now properly reset to TOP before each screen

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'prayers_list.dart';
import 'goliath_prayers_list.dart';
import 'prayer_texts.dart';

class DivineShufflePopup extends StatefulWidget {
  final bool isVisible;
  final bool isGoliathMode;
  final String? currentPrayerPath;
  final VoidCallback? onPhase1Complete;
  final VoidCallback? onTTSStart;      // Duck music when TTS starts
  final VoidCallback? onTTSComplete;   // Restore music when TTS ends
  
  const DivineShufflePopup({
    super.key,
    required this.isVisible,
    required this.isGoliathMode,
    this.currentPrayerPath,
    this.onPhase1Complete,
    this.onTTSStart,
    this.onTTSComplete,
  });

  @override
  State<DivineShufflePopup> createState() => DivineShufflePopupState();
}

class DivineShufflePopupState extends State<DivineShufflePopup> with TickerProviderStateMixin {
  
  // ═══════════════════════════════════════════════════════════════════════════
  // STATE MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Current intro part: 1, 2, 3 = intro parts, 0 = Phase 2 (prayers)
  int _currentIntroPart = 1;
  
  // Opacity states
  double _popupOpacity = 0.0;
  double _contentOpacity = 1.0;
  double _topPanelOpacity = 1.0;
  double _bottomPanelOpacity = 1.0;
  
  // TTS audio player
  AudioPlayer? _ttsPlayer;
  StreamSubscription? _ttsCompletionSubscription;
  bool _isTTSPlaying = false;
  
  // Scroll controllers for Intro Parts 2 and 3
  // Scroll controllers for Intro Parts 1, 2 and 3
  final ScrollController _part1ScrollController = ScrollController();
  final ScrollController _part2ScrollController = ScrollController();
  final ScrollController _part3ScrollController = ScrollController();
  Timer? _introScrollTimer;
  
  // Prayer list for Phase 2
  List<String> _currentPrayerList = [];
  int _currentPrayerIndex = 0; // The ACTUAL prayer being played
  int _displayedPrayerIndex = 0; // The prayer shown in center during shuffle
  
  // Shuffle animation state
  bool _isShuffling = false;
  Timer? _shuffleTimer;
  
  // Track last played prayer for Divine Shuffle (no repeats)
  String? _lastPlayedPrayer;
  
  // Track previous session for time-based changes
  String _currentSessionType = '';
  Timer? _sessionCheckTimer;
  
  // Auto-scroll for highlighted prayer card (green/blue box)
  final ScrollController _prayerCardScrollController = ScrollController();
  Timer? _prayerCardAutoScrollTimer;
  
  // ═══════════════════════════════════════════════════════════════════════════
  // COLORS - Option 5 "Soft & Spiritual" Theme (EXACT MATCH)
  // ═══════════════════════════════════════════════════════════════════════════
  
  static const Color _goldAccent = Color(0xFFD4AF37);
  static const Color _warmBackground = Color(0xFFFFFEF9);
  static const Color _softBackground = Color(0xFFF9F6EF);
  static const Color _darkText = Color(0xFF2C2C2C);
  static const Color _bodyText = Color(0xFF444444);
  static const Color _subtitleText = Color(0xFF999999);
  static const Color _greenHighlight = Color(0xFF22C55E);
  static const Color _goliathBlue = Color(0xFF87CEEB); // Electric blue for Goliath

  // ═══════════════════════════════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _initializePrayerList();
    _currentSessionType = _getSessionType();
    
    if (widget.isVisible) {
      _startIntroSequence();
    }
  }

  @override
  void didUpdateWidget(DivineShufflePopup oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isVisible && !oldWidget.isVisible) {
      _startIntroSequence();
    }
    
    if (widget.isGoliathMode != oldWidget.isGoliathMode && _currentIntroPart == 0) {
      _handleGoliathModeChange();
    }
    
    // When a NEW prayer starts playing, trigger the shuffle animation
    if (widget.currentPrayerPath != null && 
        widget.currentPrayerPath != oldWidget.currentPrayerPath &&
        _currentIntroPart == 0) {
      _onNewPrayerPlaying(widget.currentPrayerPath!);
    }
  }

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    _sessionCheckTimer?.cancel();
    _introScrollTimer?.cancel();
    _prayerCardAutoScrollTimer?.cancel();
    _ttsCompletionSubscription?.cancel();
    _part1ScrollController.dispose();
    _part2ScrollController.dispose();
    _part3ScrollController.dispose();
    _prayerCardScrollController.dispose();
    _ttsPlayer?.dispose();
    super.dispose();
  }

  void _initializePrayerList() {
    if (widget.isGoliathMode) {
      _currentPrayerList = GoliathPrayersList.prayers;
    } else {
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 11) {
        _currentPrayerList = PrayersList.morningPrayers;
      } else if (hour >= 11 && hour < 18) {
        _currentPrayerList = PrayersList.neutralPrayers;
      } else {
        _currentPrayerList = PrayersList.eveningPrayers;
      }
    }
    
    if (_currentPrayerList.isNotEmpty) {
      _currentPrayerIndex = Random().nextInt(_currentPrayerList.length);
      _displayedPrayerIndex = _currentPrayerIndex;
    }
  }
  
  String _getSessionType() {
    if (widget.isGoliathMode) return 'goliath';
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return 'morning';
    if (hour >= 11 && hour < 18) return 'midday';
    return 'evening';
  }

  Color get _highlightColor => widget.isGoliathMode ? _goliathBlue : _greenHighlight;
  
  /// Check if intro is still active (buttons should be disabled)
  bool get isIntroActive => _currentIntroPart > 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // 3-PART INTRO SEQUENCE
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _startIntroSequence() async {
    debugPrint('🔀 Divine Shuffle - Starting Part 1: Welcome to Theta');
    
    setState(() {
      _currentIntroPart = 1;
      _popupOpacity = 0.0;
      _contentOpacity = 1.0;
    });
    
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => _popupOpacity = 1.0);
    await Future.delayed(const Duration(milliseconds: 800));
    
    _playPartAudio(1);
  }
  
  Future<void> _playPartAudio(int part) async {
    String audioFile;
    switch (part) {
      case 1:
        audioFile = 'audio/theta_intro_part1_welcome.mp3';
        break;
      case 2:
        audioFile = 'audio/theta_intro_part2_shuffle.mp3';
        break;
      case 3:
        audioFile = 'audio/theta_intro_part3_howto.mp3';
        break;
      default:
        return;
    }
    
    try {
      _ttsPlayer?.dispose();
      _ttsPlayer = AudioPlayer();
      
      // CRITICAL FIX: Set AudioContext to NOT steal focus from music
      // This makes music DUCK (lower volume) instead of CUT OFF
      await _ttsPlayer!.setAudioContext(AudioContext(
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
          contentType: AndroidContentType.speech,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gainTransientMayDuck, // DUCK music, don't pause it
        ),
      ));
      
      _ttsCompletionSubscription?.cancel();
      _ttsCompletionSubscription = _ttsPlayer!.onPlayerComplete.listen((_) {
        debugPrint('🔊 Part $part TTS complete');
        widget.onTTSComplete?.call();  // Restore music volume
        setState(() => _isTTSPlaying = false);
        _introScrollTimer?.cancel();
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _currentIntroPart == part) {
            _advanceToNextPart();
          }
        });
      });
      
      setState(() => _isTTSPlaying = true);
      await _ttsPlayer!.play(AssetSource(audioFile));
      widget.onTTSStart?.call();  // Duck music volume
      debugPrint('▶️ Playing Part $part TTS');
      
      // Auto-scroll DISABLED - user scrolls manually via gold dot
      // _startIntroAutoScroll(part);
      
    } catch (e) {
      debugPrint('⚠️ Error playing Part $part audio: $e');
      setState(() => _isTTSPlaying = false);
      
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && _currentIntroPart == part) {
          _advanceToNextPart();
        }
      });
    }
  }
  
  Future<void> _skipCurrentPart() async {
    debugPrint('⏭️ Skipping Part $_currentIntroPart');
    
    await _ttsPlayer?.stop();
    setState(() => _isTTSPlaying = false);
    _introScrollTimer?.cancel();
    
    _advanceToNextPart();
  }
  
  /// Auto-scroll for ALL Intro Parts - FIXED with part-specific speeds
  /// Part 1 (Welcome): FASTER scroll (shorter content)
  /// Part 2 (Divine Shuffle): SLOWER scroll (more content) + starts at TOP
  /// Part 3 (How to Theta): SLOWER scroll (most content)
  void _startIntroAutoScroll(int part) {
    _introScrollTimer?.cancel();
    
    final ScrollController controller;
    int scrollDuration;
    int delaySeconds;
    
    switch (part) {
      case 1:
        controller = _part1ScrollController;
        scrollDuration = 25000;  // FIX: 25 seconds (was 45 - TOO SLOW)
        delaySeconds = 2;        // Shorter delay for Part 1
        break;
      case 2:
        controller = _part2ScrollController;
        scrollDuration = 90000;  // FIX: 90 seconds (was 45 - TOO FAST)
        delaySeconds = 3;        // Standard delay
        break;
      case 3:
        controller = _part3ScrollController;
        scrollDuration = 100000; // FIX: 100 seconds (was 45 - TOO FAST for longest content)
        delaySeconds = 3;        // Standard delay
        break;
      default:
        return;
    }
    
    // FIX: ALWAYS reset scroll position to TOP FIRST before any scrolling
    // This fixes the issue where Part 2 starts midway through text
    if (controller.hasClients) {
      controller.jumpTo(0);
      debugPrint('📜 Reset Part $part scroll position to TOP');
    }
    
    // Delay before scrolling starts (let user read title)
    Future.delayed(Duration(seconds: delaySeconds), () {
      if (!mounted || !controller.hasClients) return;
      
      // Double-check we're at the top before starting scroll
      if (controller.position.pixels != 0) {
        controller.jumpTo(0);
      }
      
      final maxScroll = controller.position.maxScrollExtent;
      if (maxScroll <= 0) return;
      
      debugPrint('📜 Starting auto-scroll for Part $part (duration: ${scrollDuration}ms, max: $maxScroll)');
      
      controller.animateTo(
        maxScroll,
        duration: Duration(milliseconds: scrollDuration),
        curve: Curves.easeInOut,
      );
    });
  }
  
  Future<void> _advanceToNextPart() async {
    setState(() => _contentOpacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 400));
    
    // FIX: Reset ALL scroll controllers to top before showing next part
    // This ensures each part starts from the very beginning
    if (_part1ScrollController.hasClients) {
      _part1ScrollController.jumpTo(0);
    }
    if (_part2ScrollController.hasClients) {
      _part2ScrollController.jumpTo(0);
    }
    if (_part3ScrollController.hasClients) {
      _part3ScrollController.jumpTo(0);
    }
    
    if (_currentIntroPart < 3) {
      setState(() {
        _currentIntroPart++;
        _contentOpacity = 1.0;
      });
      debugPrint('🔀 Advancing to Part $_currentIntroPart');
      
      _playPartAudio(_currentIntroPart);
    } else {
      _transitionToPhase2();
    }
  }
  
  Future<void> _transitionToPhase2() async {
    debugPrint('🔀 Transitioning to Phase 2 (Prayers)');
    
    setState(() {
      _currentIntroPart = 0;
      _contentOpacity = 1.0;
    });
    
    widget.onPhase1Complete?.call();
    
    // Start session check timer (check every 60 seconds for time-based changes)
    _sessionCheckTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkSessionChange();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SESSION CHANGE DETECTION (Time-based transitions)
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _checkSessionChange() {
    if (widget.isGoliathMode) return; // Don't check time when in Goliath mode
    
    final newSessionType = _getSessionType();
    if (newSessionType != _currentSessionType) {
      debugPrint('🔀 Session changed from $_currentSessionType to $newSessionType');
      _handleSessionChange(newSessionType);
    }
  }
  
  Future<void> _handleSessionChange(String newSession) async {
    // Fade out top panel
    setState(() => _topPanelOpacity = 0.0);
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Update prayer list and session
    _currentSessionType = newSession;
    _initializePrayerList();
    
    // Fade in top panel
    setState(() => _topPanelOpacity = 1.0);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GOLIATH MODE TRANSITION
  // ═══════════════════════════════════════════════════════════════════════════
  
  Future<void> _handleGoliathModeChange() async {
    debugPrint('🔀 Goliath mode changed: ${widget.isGoliathMode}');
    
    // CRITICAL: Update prayer list IMMEDIATELY before any delay
    _currentSessionType = _getSessionType();
    _initializePrayerList();
    _lastPlayedPrayer = null; // Reset for new mode
    
    // Fade out both panels
    setState(() {
      _topPanelOpacity = 0.0;
      _bottomPanelOpacity = 0.0;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Fade in both panels
    setState(() {
      _topPanelOpacity = 1.0;
      _bottomPanelOpacity = 1.0;
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CASINO-STYLE SHUFFLE ANIMATION
  // Prayer list scrolls behind FIXED center highlight
  // ═══════════════════════════════════════════════════════════════════════════
  
  void _onNewPrayerPlaying(String newPrayerPath) {
    // Detect if this is a Goliath prayer by path
    final isGoliathPrayer = newPrayerPath.contains('/goliath/') || newPrayerPath.contains('G0');
    
    // If prayer type doesn't match current list, update the list first
    if (isGoliathPrayer && _currentPrayerList != GoliathPrayersList.prayers) {
      debugPrint('🔀 Goliath prayer detected - updating list');
      _currentPrayerList = GoliathPrayersList.prayers;
    } else if (!isGoliathPrayer && _currentPrayerList == GoliathPrayersList.prayers) {
      debugPrint('🔀 Regular prayer detected - updating list');
      _initializePrayerList();
    }
    
    // Find the index of the new prayer
    final newIndex = _currentPrayerList.indexOf(newPrayerPath);
    if (newIndex == -1) {
      debugPrint('⚠️ Prayer not found in list: $newPrayerPath');
      return;
    }
    
    // Check for Divine Shuffle - ensure no repeat
    if (newPrayerPath == _lastPlayedPrayer) {
      debugPrint('⚠️ DIVINE SHUFFLE: Same prayer detected! This should not happen.');
    }
    
    _lastPlayedPrayer = newPrayerPath;
    
    debugPrint('🔀 New prayer playing: index $newIndex - ${PrayerTexts.getPrayerName(newPrayerPath)}');
    
    // Start casino-style shuffle animation
    _startCasinoShuffle(newIndex);
  }
  
  void _startCasinoShuffle(int targetIndex) {
    if (_isShuffling) {
      _shuffleTimer?.cancel();
    }
    
    setState(() {
      _isShuffling = true;
    });
    
    final random = Random();
    int shuffleCount = 0;
    const totalShuffles = 12; // Number of random positions before landing
    
    // Speed starts fast, slows down towards the end (casino effect)
    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      shuffleCount++;
      
      if (shuffleCount >= totalShuffles) {
        // Final position - land on target
        timer.cancel();
        setState(() {
          _displayedPrayerIndex = targetIndex;
          _currentPrayerIndex = targetIndex;
          _isShuffling = false;
        });
        debugPrint('🎰 Shuffle complete - landed on prayer $targetIndex');
        // Start auto-scroll on highlighted prayer card after 2-second delay
        _startPrayerCardAutoScroll();
      } else {
        // Random shuffle - prayers "spin" behind the fixed highlight
        setState(() {
          _displayedPrayerIndex = random.nextInt(_currentPrayerList.length);
        });
      }
    });
  }
  
  /// Start auto-scroll on highlighted prayer card with 2-second delay
  void _startPrayerCardAutoScroll() {
    // Cancel any existing timer
    _prayerCardAutoScrollTimer?.cancel();
    
    // Reset scroll position to top
    if (_prayerCardScrollController.hasClients) {
      _prayerCardScrollController.jumpTo(0);
    }
    
    // Wait 2 seconds before starting auto-scroll (gives user time to read first line)
    _prayerCardAutoScrollTimer = Timer(const Duration(seconds: 12), () {
      if (!mounted) return;
      if (!_prayerCardScrollController.hasClients) return;
      
      final maxScroll = _prayerCardScrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return; // No need to scroll if content fits
      
      // Calculate duration based on content length (smooth reading pace)
      final scrollDuration = Duration(milliseconds: (maxScroll * 50).toInt().clamp(3000, 15000));
      
      _prayerCardScrollController.animateTo(
        maxScroll,
        duration: scrollDuration,
        curve: Curves.linear,
      );
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  
  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();
    
    return AnimatedOpacity(
      opacity: _popupOpacity,
      duration: const Duration(milliseconds: 800),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          child: _currentIntroPart > 0 ? _buildIntroContent() : _buildPhase2Content(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTRO CONTENT (Parts 1, 2, 3) - Option 5 "Soft & Spiritual" Style
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildIntroContent() {
    return AnimatedOpacity(
      opacity: _contentOpacity,
      duration: const Duration(milliseconds: 400),
      child: Stack(
        children: [
          // Main content - reduced padding for mobile
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
            child: _buildPartContent(),
          ),
          
          // Part indicator (bottom left)
          Positioned(
            bottom: 12,
            left: 16,
            child: _buildPartIndicator(),
          ),
          
          // Skip button (bottom right)
          Positioned(
            bottom: 12,
            right: 16,
            child: _buildSkipButton(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPartContent() {
    switch (_currentIntroPart) {
      case 1:
        return _buildPart1Welcome();
      case 2:
        return _buildPart2DivineShuffle();
      case 3:
        return _buildPart3HowTo();
      default:
        return const SizedBox.shrink();
    }
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

  // ─────────────────────────────────────────────────────────────────────────
  // PART 1: Welcome to Theta - EXACT FROM WINDOWS
  // ─────────────────────────────────────────────────────────────────────────
  
  Widget _buildPart1Welcome() {
    return _buildGoldDotScrollable(
      controller: _part1ScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ✦ Glow Icon (black, size 32)
          Container(
            width: 40,
            height: 40,
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
          ),
          const SizedBox(height: 12),
          
          // "Welcome to Theta" - Theta in gold
          RichText(
            text: TextSpan(
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: _darkText,
              ),
              children: [
                const TextSpan(text: 'Welcome to '),
                TextSpan(
                  text: 'Theta',
                  style: GoogleFonts.playfairDisplay(color: _goldAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          
          // Subtitle
          Text(
            'YOUR SPIRITUAL COMPANION',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: _subtitleText,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 18),
          
          // EXACT Windows Blueprint text - First paragraph
          Text(
            'Theta was designed to inspire users to vocalize each prayer or affirmation—either aloud or under their breath—thus actively speaking the transformative word of God.',
            style: GoogleFonts.lora(
              fontSize: 14,
              height: 1.7,
              color: _bodyText,
            ),
          ),
          const SizedBox(height: 18),
          
          // Highlight box with gold border - EXACT Windows quote
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _goldAccent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _goldAccent.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              '"As that is where all the power lies."',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: _goldAccent,
              ),
            ),
          ),
          const SizedBox(height: 18),
          
          // EXACT Windows Blueprint text - Second paragraph
          Text(
            'Not in the Theta audio itself, but in the living Word of God being "spoken" after each prayer or affirmation is played, and the heart of the person speaking, postured towards the Lord.',
            style: GoogleFonts.lora(
              fontSize: 14,
              height: 1.7,
              color: _bodyText,
            ),
          ),
        ],
      ),
    );
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // PART 2: Divine Shuffle™ - EXACT FROM WINDOWS
  // ─────────────────────────────────────────────────────────────────────────
  
  Widget _buildPart2DivineShuffle() {
    return _buildGoldDotScrollable(
      controller: _part2ScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🔀 Icon
          Container(
            width: 40,
            height: 40,
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
                '🔀',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Title - EXACT Windows: "Divine Shuffle" not "Divine Shuffle™"
          RichText(
            text: TextSpan(
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: _darkText,
              ),
              children: [
                const TextSpan(text: 'Divine '),
                TextSpan(
                  text: 'Shuffle',
                  style: GoogleFonts.playfairDisplay(color: _goldAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          
          // Subtitle - EXACT Windows
          Text(
            'INTELLIGENT PRAYER ROTATION',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: _subtitleText,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 18),
          
          // EXACT Windows Blueprint paragraphs
          Text(
            'Theta features Divine Shuffle — an intelligent prayer rotation system engineered to deliver a fresh spiritual experience with every prayer.',
            style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
          ),
          const SizedBox(height: 14),
          
          Text(
            'This smart algorithm tracks your last played prayer within each time-based pool (Morning, Mid-Day, Evening, or Goliath) and automatically re-selects if a duplicate is detected, attempting up to 10 fresh selections to guarantee variety.',
            style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
          ),
          const SizedBox(height: 14),
          
          Text(
            'With 50 prayers per session, hearing the same prayer back-to-back would feel repetitive and break your spiritual flow. Divine Shuffle eliminates this entirely — ensuring that each prayer feels intentional, timely, and divinely appointed for that exact moment.',
            style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
          ),
          const SizedBox(height: 14),
          
          // Highlight box - EXACT Windows quote
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _goldAccent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _goldAccent.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              '"No repeats. No redundancy. Just fresh, flowing prayer."',
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: _goldAccent,
              ),
            ),
          ),
          const SizedBox(height: 14),
          
          // Final paragraph - EXACT Windows
          Text(
            'Theta delivers time-based spiritual nourishment through carefully curated prayer sessions. Each session is designed to align with the natural rhythm of your day, providing relevant prayers that speak to your current moment. Additionally, Goliath Mode offers powerful spiritual warfare prayers for breakthrough moments.',
            style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
          ),
        ],
      ),
    );
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // PART 3: How to Use Theta - EXACT FROM WINDOWS
  // ─────────────────────────────────────────────────────────────────────────
  
  Widget _buildPart3HowTo() {
    return _buildGoldDotScrollable(
      controller: _part3ScrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 📖 Icon
          Container(
            width: 40,
            height: 40,
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
                '📖',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Title
          RichText(
            text: TextSpan(
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: _darkText,
              ),
              children: [
                const TextSpan(text: 'How to use '),
                TextSpan(
                  text: 'Theta',
                  style: GoogleFonts.playfairDisplay(color: _goldAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          
          // Subtitle
          Text(
            'MAXIMIZE YOUR SPIRITUAL JOURNEY',
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: _subtitleText,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 18),
          
          // Instructions
          Text(
            'Say each Prayer or Affirmation out loud, deliberately, slowly.',
            style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
          ),
          const SizedBox(height: 12),
          
          Text(
            'Voice matters — speak audibly. The ear hears what the heart receives.',
            style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
          ),
          const SizedBox(height: 12),
          
          Text(
            'Use emotion and faith — speak with expectancy, not vain repetition.',
            style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
          ),
          const SizedBox(height: 12),
          
          Text(
            'Be consistent — spiritual fruit grows with steady discipline.',
            style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
          ),
          const SizedBox(height: 12),
          
          Text(
            'Theta is not magic, not formulaic "name it and claim it" without God\'s will. It\'s faithful engagement with God\'s Word.',
            style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
          ),
          const SizedBox(height: 12),
          
          Text(
            'Maintain humility. Avoid prideful, self-centered tones. Subordinate declarations to God\'s will, always keep a surrendered heart.',
            style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
          ),
          const SizedBox(height: 12),
          
          Text(
            'Use each Prayer and Affirmation as a starting point for a longer prayer through which you engage with God, adding your own personal requests, expressions of gratitude, and declarations after the prayer has finished playing.',
            style: GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
          ),
          const SizedBox(height: 14),
          
          // Highlight box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _goldAccent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _goldAccent.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              '"Fight fire with Fire. Enjoy the empowerment of Theta."',
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: _goldAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // PART INDICATOR
  // ─────────────────────────────────────────────────────────────────────────
  
  Widget _buildPartIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIndicatorDot(1),
          const SizedBox(width: 6),
          _buildIndicatorDot(2),
          const SizedBox(width: 6),
          _buildIndicatorDot(3),
          const SizedBox(width: 10),
          Text(
            'Part $_currentIntroPart of 3',
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _subtitleText,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIndicatorDot(int part) {
    final bool isActive = part == _currentIntroPart;
    final bool isComplete = part < _currentIntroPart;
    
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? _goldAccent
            : isComplete
                ? _greenHighlight
                : const Color(0xFFDDDDDD),
        boxShadow: isActive ? [
          BoxShadow(
            color: _goldAccent.withOpacity(0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ] : null,
      ),
    );
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // SKIP BUTTON
  // ─────────────────────────────────────────────────────────────────────────
  
  Widget _buildSkipButton() {
    String buttonText;
    switch (_currentIntroPart) {
      case 1:
        buttonText = 'Skip to Part 2';
        break;
      case 2:
        buttonText = 'Skip to Part 3';
        break;
      case 3:
        buttonText = 'Skip to Prayers';
        break;
      default:
        buttonText = 'Skip';
    }
    
    return TextButton(
      onPressed: _skipCurrentPart,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            buttonText,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _subtitleText,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: _subtitleText,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHASE 2: MOBILE VERTICAL LAYOUT - Top (Session Info) + Bottom (Prayer List)
  // Adapted from Windows dual-panel horizontal layout
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildPhase2Content() {
    return AnimatedOpacity(
      opacity: _contentOpacity,
      duration: const Duration(milliseconds: 800),
      child: Column(
        children: [
          // Top Section - Session Header (compact)
          AnimatedOpacity(
            opacity: _topPanelOpacity,
            duration: const Duration(milliseconds: 500),
            child: _buildSessionHeader(),
          ),
          
          // Gold divider line
          Container(height: 2, color: _goldAccent.withOpacity(0.5)),
          
          // Bottom Section - Prayer List with FIXED center highlight
          Expanded(
            child: AnimatedOpacity(
              opacity: _bottomPanelOpacity,
              duration: const Duration(milliseconds: 500),
              child: _buildPrayerListSection(),
            ),
          ),
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // TOP SECTION - COMPACT SESSION HEADER (Mobile)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildSessionHeader() {
    final hour = DateTime.now().hour;
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    String sessionTitle;
    String sessionRange;
    String sessionEmoji;
    String sessionTime;
    String sessionDescription;
    
    if (widget.isGoliathMode) {
      sessionTitle = 'Goliath Mode';
      sessionRange = 'G001-G050';
      sessionEmoji = '🗡️';
      sessionTime = 'Spiritual Warfare';
      sessionDescription = '50 powerful declarations against spiritual opposition';
    } else if (hour >= 5 && hour < 11) {
      sessionTitle = 'Morning Prayers';
      sessionRange = '001-050';
      sessionEmoji = '🌅';
      sessionTime = '5:00 AM – 11:00 AM';
      sessionDescription = 'Start your day anchored in faith and gratitude';
    } else if (hour >= 11 && hour < 18) {
      sessionTitle = 'Mid-Day Prayers';
      sessionRange = '051-100';
      sessionEmoji = '☀️';
      sessionTime = '11:00 AM – 6:00 PM';
      sessionDescription = 'Sustaining strength and focus through your day';
    } else {
      sessionTitle = 'Evening Prayers';
      sessionRange = '101-150';
      sessionEmoji = '🌙';
      sessionTime = '6:00 PM – 5:00 AM';
      sessionDescription = 'Rest and reflection as day turns to night';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_warmBackground, _softBackground],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Star, Title, Prayer count
          Row(
            children: [
              // ✦ Star with glow
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      (widget.isGoliathMode ? _goliathBlue : _goldAccent).withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Center(
                  child: Text(
                    '✦',
                    style: TextStyle(
                      fontSize: 28,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              
              // Title and time range
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(sessionEmoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          sessionTitle,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _darkText,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '$sessionRange  •  $sessionTime',
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        color: widget.isGoliathMode ? _goliathBlue : _subtitleText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Prayer count badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.isGoliathMode ? _goliathBlue.withOpacity(0.15) : _goldAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isGoliathMode ? _goliathBlue.withOpacity(0.3) : _goldAccent.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  '${_currentPrayerList.length}',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.isGoliathMode ? _goliathBlue : _goldAccent,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Session description
          Text(
            sessionDescription,
            style: GoogleFonts.lora(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: _bodyText.withOpacity(0.8),
            ),
          ),
          
          // Current time indicator (non-Goliath only)
          if (!widget.isGoliathMode) ...[
            const SizedBox(height: 4),
            Text(
              'Current time: $currentTime',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: _subtitleText,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // BOTTOM SECTION - PRAYER LIST with FIXED CENTER HIGHLIGHT (Casino Style)
  // ═══════════════════════════════════════════════════════════════════════════
  
  Widget _buildPrayerListSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isGoliathMode ? _goliathBlue.withOpacity(0.08) : _goldAccent.withOpacity(0.08),
              border: Border(bottom: BorderSide(color: widget.isGoliathMode ? _goliathBlue.withOpacity(0.2) : _goldAccent.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(colors: [(widget.isGoliathMode ? _goliathBlue : _goldAccent).withOpacity(0.3), Colors.transparent]),
                  ),
                  child: const Center(child: Text('🔀', style: TextStyle(fontSize: 14))),
                ),
                const SizedBox(width: 8),
                Text(
                  'Divine Shuffle™',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.isGoliathMode ? _goliathBlue : _goldAccent,
                  ),
                ),
              ],
            ),
          ),
          
          // Prayer display area with FIXED center highlight
          Expanded(
            child: Stack(
              children: [
                // Background prayers (faded, above and below)
                _buildPrayerStack(),
                
                // Fixed center highlight frame overlay (border only, no fill)
                Center(
                  child: Container(
                    height: 110, // REDUCED: Match prayer card height
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _highlightColor, width: 3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPrayerStack() {
    if (_currentPrayerList.isEmpty) return const SizedBox.shrink();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        const itemHeight = 110.0; // REDUCED: Tighter prayer cards
        const gap = 4.0; // REDUCED: Minimal gap between prayers
        final centerY = (constraints.maxHeight - itemHeight) / 2;
        
        // Show 3 prayers: 1 above, 1 center (highlighted), 1 below
        // Equal spacing above and below center prayer
        return Stack(
          children: [
            // Prayer -1 (above center) - equal gap from center
            Positioned(
              top: centerY - itemHeight - gap,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.7,
                child: _buildPrayerCard(_getRelativePrayerIndex(-1), isHighlighted: false),
              ),
            ),
            // Prayer 0 (CENTER - HIGHLIGHTED - matches TTS)
            Positioned(
              top: centerY,
              left: 0,
              right: 0,
              child: _buildPrayerCard(_displayedPrayerIndex, isHighlighted: true),
            ),
            // Prayer +1 (below center) - equal gap from center
            Positioned(
              top: centerY + itemHeight + gap,
              left: 0,
              right: 0,
              child: Opacity(
                opacity: 0.7,
                child: _buildPrayerCard(_getRelativePrayerIndex(1), isHighlighted: false),
              ),
            ),
          ],
        );
      },
    );
  }
  
  int _getRelativePrayerIndex(int offset) {
    if (_currentPrayerList.isEmpty) return 0;
    int index = _displayedPrayerIndex + offset;
    // Wrap around
    while (index < 0) index += _currentPrayerList.length;
    return index % _currentPrayerList.length;
  }
  
  /// FIX #3 & #4: Prayer card with FULL OPACITY text and SCROLLABLE content
  Widget _buildPrayerCard(int index, {required bool isHighlighted}) {
    if (index < 0 || index >= _currentPrayerList.length) {
      return const SizedBox(height: 110);
    }
    
    final prayerPath = _currentPrayerList[index];
    final prayerNumber = PrayerTexts.getPrayerNumber(prayerPath);
    final prayerName = PrayerTexts.getPrayerName(prayerPath);
    final prayerText = PrayerTexts.getTextByPath(prayerPath) ?? 'Prayer text not available';
    final highlightColor = _highlightColor;
    
    return Container(
      height: 110, // REDUCED: Tighter cards for closer spacing
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? Colors.transparent : const Color(0xFFEEEEEE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with prayer number and name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isHighlighted ? highlightColor : _goldAccent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  prayerNumber,
                  style: GoogleFonts.montserrat(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  prayerName,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? highlightColor : _darkText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isHighlighted)
                Icon(Icons.play_circle_filled, color: highlightColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          
          // FIX #4: SCROLLABLE prayer text (not truncated)
          // AUTO-SCROLL: Controller added for highlighted cards (green/blue box)
          Expanded(
            child: SingleChildScrollView(
              controller: isHighlighted ? _prayerCardScrollController : null,
              child: Text(
                prayerText,
                style: GoogleFonts.lora(
                  fontSize: 12,               // FIX: Increased from 11
                  fontWeight: FontWeight.w500, // FIX: Added for bolder text
                  height: 1.5,
                  color: _darkText,           // FIX: Full opacity (was _bodyText.withOpacity(0.8))
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
