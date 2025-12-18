/// Theta Audio MVP - Audio Service (ANDROID PRODUCTION)
/// 
/// VERSION: Divine Shuffle Integration
/// 
/// FEATURES:
/// - Regular Theta Mode: 150 time-based prayers
/// - Goliath Mode: 50 spiritual warfare prayers
/// - Repeat current prayer functionality
/// - Duplicate prevention in both modes
/// - Music fade callbacks (onPrayerStart, onPrayerEnd)
/// - Divine Shuffle sync callback (onPrayerChanged)
/// 
/// Handles background audio playback with audioplayers package

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audio_service/audio_service.dart';
import 'prayers_list.dart';
import 'goliath_prayers_list.dart';

/// Audio handler for background audio service
class ThetaAudioHandler extends BaseAudioHandler {
  ThetaAudioHandler() {
    // Set initial playback state
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.play,
        MediaControl.pause,
        MediaControl.stop,
      ],
      processingState: AudioProcessingState.idle,
    ));
  }

  @override
  Future<void> play() async => playbackState.add(playbackState.value.copyWith(
    playing: true,
    processingState: AudioProcessingState.ready,
  ));

  @override
  Future<void> pause() async => playbackState.add(playbackState.value.copyWith(
    playing: false,
  ));

  @override
  Future<void> stop() async => playbackState.add(playbackState.value.copyWith(
    playing: false,
    processingState: AudioProcessingState.idle,
  ));
}

class ThetaAudioService {
  late AudioPlayer _player;
  Timer? _timer;
  bool _isActive = false;
  String? _currentPrayerPath;
  StreamSubscription<void>? _prayerCompleteSubscription;
  StreamSubscription<String>? _playerErrorSubscription;
  
  // Callbacks for UI updates
  Function(bool)? onStatusChanged;
  
  // Callbacks for music volume coordination
  VoidCallback? onPrayerStart;  // Called when prayer starts - fade music to 10%
  VoidCallback? onPrayerEnd;    // Called when prayer ends - restore music to normal
  
  // NEW: Callback for Divine Shuffle sync
  // Called with prayer path when a new prayer starts playing
  void Function(String prayerPath)? onPrayerChanged;
  
  Future<void> initialize() async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🎧 THETA ANDROID PRODUCTION - INITIALIZATION');
    debugPrint('═══════════════════════════════════════════════════════');
    
    try {
      debugPrint('Creating AudioPlayer...');
      _player = AudioPlayer();
      debugPrint('✅ AudioPlayer created');
      
      // CRITICAL FIX: Set audio context so prayer player doesn't steal focus from music
      // This allows music to continue playing (at reduced volume) while prayers play
      await _player.setAudioContext(AudioContext(
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
          audioFocus: AndroidAudioFocus.none, // DON'T steal focus from music
        ),
      ));
      debugPrint('✅ AudioContext set (no focus stealing)');
      
      debugPrint('Setting release mode...');
      await _player.setReleaseMode(ReleaseMode.stop);
      debugPrint('✅ Release mode set');
      
      // Listen for prayer completion to restore music volume
      await _prayerCompleteSubscription?.cancel();
      _prayerCompleteSubscription = _player.onPlayerComplete.listen((event) {
        debugPrint('🎵 Prayer playback complete - triggering onPrayerEnd');
        onPrayerEnd?.call();
      });

      await _playerErrorSubscription?.cancel();
      _playerErrorSubscription = _player.onPlayerError.listen((msg) {
        debugPrint('⚠️ Prayer playback error: $msg');
        onPrayerEnd?.call();
      });
      
      debugPrint('✅ Audio Service initialized successfully');
      debugPrint('═══════════════════════════════════════════════════════');
    } catch (e, stack) {
      debugPrint('❌ INITIALIZATION ERROR: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }
  
  /// Start Theta (Regular Mode - 150 time-based prayers)
  Future<void> startTheta({int intervalMinutes = 10}) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🎧 THETA ANDROID - START REGULAR MODE');
    debugPrint('═══════════════════════════════════════════════════════');
    
    if (_isActive) {
      debugPrint('⚠️ Already active');
      return;
    }
    
    _isActive = true;
    onStatusChanged?.call(true);
    
    // Reset prayer tracking for fresh session
    PrayersList.resetLastPlayed();
    
    debugPrint('Interval: $intervalMinutes minutes');
    debugPrint('Playing first prayer immediately...');
    
    await playPrayer();
    
    _timer = Timer.periodic(Duration(minutes: intervalMinutes), (timer) {
      debugPrint('⏰ Timer fired - playing next prayer');
      playPrayer();
    });
    
    debugPrint('✅ Theta started (Regular Mode)');
    debugPrint('═══════════════════════════════════════════════════════');
  }
  
  /// Start Goliath Mode (50 spiritual warfare prayers)
  Future<void> startGoliathMode({int intervalMinutes = 10}) async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('⚔️ THETA ANDROID - START GOLIATH MODE');
    debugPrint('═══════════════════════════════════════════════════════');
    
    if (_isActive) {
      debugPrint('⚠️ Already active');
      return;
    }
    
    _isActive = true;
    onStatusChanged?.call(true);
    
    // Reset Goliath prayer tracking for fresh session
    GoliathPrayersList.resetLastPlayed();
    
    debugPrint('Interval: $intervalMinutes minutes');
    debugPrint('Playing first Goliath prayer immediately...');
    
    await playGoliathPrayer();
    
    _timer = Timer.periodic(Duration(minutes: intervalMinutes), (timer) {
      debugPrint('⏰ Timer fired - playing next Goliath prayer');
      playGoliathPrayer();
    });
    
    debugPrint('✅ Goliath Mode started');
    debugPrint('═══════════════════════════════════════════════════════');
  }
  
  /// Stop Theta (works for both Regular and Goliath Mode)
  Future<void> stopTheta() async {
    debugPrint('🛑 Stopping Theta...');
    
    if (!_isActive) {
      debugPrint('⚠️ Not active');
      return;
    }
    
    _isActive = false;
    onStatusChanged?.call(false);
    
    _timer?.cancel();
    _timer = null;
    
    await _player.stop();
    
    // Clear current prayer when stopped
    _currentPrayerPath = null;
    
    // Restore music volume when stopped
    onPrayerEnd?.call();
    
    debugPrint('✅ Theta stopped');
  }
  
  /// Play a regular Theta prayer (time-based, 150 prayers)
  Future<void> playPrayer() async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🎵 PLAYING REGULAR PRAYER');
    debugPrint('═══════════════════════════════════════════════════════');
    
    try {
      // Notify that prayer is starting (fade music to 10%)
      onPrayerStart?.call();
      
      // Get time-based prayer with duplicate prevention
      final prayerPath = PrayersList.getRandomPrayer();
      final prayerName = prayerPath.split('/').last.replaceAll('.mp3', '');
      final category = PrayersList.getCurrentCategoryName();
      
      debugPrint('  Category: $category');
      debugPrint('  Selected: $prayerName');
      debugPrint('  Path: $prayerPath');
      
      // Store current prayer for repeat functionality
      _currentPrayerPath = prayerPath;
      
      // DIVINE SHUFFLE: Notify that prayer changed (triggers casino animation)
      onPrayerChanged?.call(prayerPath);
      
      // Stop any current playback
      await _player.stop();
      
      // Play prayer
      await _player.play(AssetSource(prayerPath));
      
      debugPrint('  ✅ Prayer playing');
      debugPrint('═══════════════════════════════════════════════════════');
      
    } catch (e, stack) {
      debugPrint('');
      debugPrint('❌ ERROR PLAYING PRAYER');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      debugPrint('═══════════════════════════════════════════════════════');
      
      // Restore music even on error
      onPrayerEnd?.call();
    }
  }
  
  /// Play a Goliath Mode prayer (spiritual warfare, 50 prayers)
  Future<void> playGoliathPrayer() async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('⚔️ PLAYING GOLIATH PRAYER');
    debugPrint('═══════════════════════════════════════════════════════');
    
    try {
      // Notify that prayer is starting (fade music to 10%)
      onPrayerStart?.call();
      
      // Get random Goliath prayer with duplicate prevention
      final prayerPath = GoliathPrayersList.getRandomPrayer();
      final prayerName = prayerPath.split('/').last.replaceAll('.mp3', '');
      
      debugPrint('  Selected: $prayerName');
      debugPrint('  Path: $prayerPath');
      
      // Store current prayer for repeat functionality
      _currentPrayerPath = prayerPath;
      
      // DIVINE SHUFFLE: Notify that prayer changed (triggers casino animation)
      onPrayerChanged?.call(prayerPath);
      
      // Stop any current playback
      await _player.stop();
      
      // Play prayer
      await _player.play(AssetSource(prayerPath));
      
      debugPrint('  ✅ Goliath prayer playing');
      debugPrint('═══════════════════════════════════════════════════════');
      
    } catch (e, stack) {
      debugPrint('');
      debugPrint('❌ ERROR PLAYING GOLIATH PRAYER');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      debugPrint('═══════════════════════════════════════════════════════');
      
      // Restore music even on error
      onPrayerEnd?.call();
    }
  }
  
  /// Repeat current prayer (works for both Regular and Goliath Mode)
  Future<void> repeatCurrentPrayer() async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔄 REPEAT CURRENT PRAYER');
    debugPrint('═══════════════════════════════════════════════════════');
    
    if (!_isActive) {
      debugPrint('⚠️ Theta not active - cannot repeat');
      return;
    }
    
    if (_currentPrayerPath == null) {
      debugPrint('⚠️ No prayer to repeat - playing new prayer');
      await playPrayer();
      return;
    }
    
    try {
      // Notify that prayer is starting (fade music to 10%)
      onPrayerStart?.call();
      
      final prayerName = _currentPrayerPath!.split('/').last.replaceAll('.mp3', '');
      
      debugPrint('  Repeating: $prayerName');
      debugPrint('  Path: $_currentPrayerPath');
      
      // DIVINE SHUFFLE: Notify that prayer changed (repeat same prayer)
      onPrayerChanged?.call(_currentPrayerPath!);
      
      // Stop current playback
      await _player.stop();
      
      // Replay same prayer
      await _player.play(AssetSource(_currentPrayerPath!));
      
      debugPrint('  ✅ Prayer repeating (timer continues)');
      debugPrint('═══════════════════════════════════════════════════════');
      
    } catch (e, stack) {
      debugPrint('');
      debugPrint('❌ ERROR REPEATING PRAYER');
      debugPrint('Error: $e');
      debugPrint('Stack: $stack');
      debugPrint('═══════════════════════════════════════════════════════');
      
      // Restore music even on error
      onPrayerEnd?.call();
    }
  }
  
  /// Play "What is Theta" audio explanation
  Future<void> playWhatIsTheta() async {
    try {
      debugPrint('🎵 Playing What is Theta audio...');
      await _player.stop();
      await _player.play(AssetSource('audio/what_is_theta.mp3'));
      debugPrint('✅ What is Theta playing');
    } catch (e) {
      debugPrint('❌ Error playing What is Theta: $e');
    }
  }
  
  /// Play "Guide Me Info" audio explanation
  Future<void> playGuideMeInfo() async {
    try {
      debugPrint('🎵 Playing Guide Me info audio...');
      await _player.stop();
      await _player.play(AssetSource('audio/guide_me_info.mp3'));
      debugPrint('✅ Guide Me info playing');
    } catch (e) {
      debugPrint('❌ Error playing Guide Me info: $e');
    }
  }
  
  bool get isActive => _isActive;
  
  /// Get current prayer name (for UI display)
  String? get currentPrayerName {
    if (_currentPrayerPath == null) return null;
    return _currentPrayerPath!.split('/').last.replaceAll('.mp3', '').replaceAll('_', ' ');
  }
  
  /// Get current prayer path
  String? get currentPrayerPath => _currentPrayerPath;
  
  void dispose() {
    debugPrint('🗑️ Disposing audio service...');
    _timer?.cancel();
    _prayerCompleteSubscription?.cancel();
    _playerErrorSubscription?.cancel();
    _player.dispose();
    debugPrint('✅ Disposed');
  }
}
