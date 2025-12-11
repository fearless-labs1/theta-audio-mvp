import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';
import 'intro_screen.dart';
import 'prayers_list.dart';
import 'package:flutter_tts/flutter_tts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // TEMPORARILY DISABLED TO PREVENT CRASH
  // await AudioService.init(
  //     builder: () => ThetaAudioHandler(),
  // );
  
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
        fontFamily: 'SF Pro Display',
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts flutterTts = FlutterTts();
  bool _isActive = false;
  String _selectedInterval = '10 minutes';
  Timer? _prayerTimer;
  Timer? _stopwatchTimer;
  int _elapsedSeconds = 0;
  String? _lastPlayedPrayer;
  String? _currentPrayer;
  int _activeTab = 0; // 0 = What is Theta, 1 = Prayer Intervals

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setVolume(1.0);
  }

  @override
  void dispose() {
    _prayerTimer?.cancel();
    _stopwatchTimer?.cancel();
    _audioPlayer.dispose();
    flutterTts.stop();
    super.dispose();
  }

  String _formatStopwatch(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  void _startStopwatch() {
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  void _stopStopwatch() {
    _stopwatchTimer?.cancel();
    setState(() {
      _elapsedSeconds = 0;
    });
  }

  Duration _getIntervalDuration() {
    switch (_selectedInterval) {
      case '3 minutes':
        return const Duration(minutes: 3);
      case '5 minutes':
        return const Duration(minutes: 5);
      case '10 minutes':
      default:
        return const Duration(minutes: 10);
    }
  }

  Future<void> _playPrayer() async {
    String prayer;
    int attempts = 0;
    
    do {
      prayer = PrayersList.getTimeBasedPrayer();
      attempts++;
    } while (prayer == _lastPlayedPrayer && attempts < 10);
    
    _lastPlayedPrayer = prayer;
    _currentPrayer = prayer;
    
    try {
      await _audioPlayer.play(AssetSource('audio/soft-chime.mp3'));
      await Future.delayed(const Duration(seconds: 2));
      await _audioPlayer.play(AssetSource(prayer));
    } catch (e) {
      print('Error playing prayer: $e');
    }
  }

  void _startTheta() {
    setState(() {
      _isActive = true;
    });
    
    _startStopwatch();
    _playPrayer();
    
    _prayerTimer = Timer.periodic(_getIntervalDuration(), (timer) {
      _playPrayer();
    });
  }

  void _stopTheta() {
    setState(() {
      _isActive = false;
    });
    
    _stopStopwatch();
    _prayerTimer?.cancel();
    _audioPlayer.stop();
  }

  void _repeatPrayer() {
    if (_currentPrayer != null && _isActive) {
      _audioPlayer.stop();
      _playPrayer();
    }
  }

  Future<void> _playGuideExplanation() async {
    await flutterTts.speak(
      "Guide Me is your AI spiritual companion. Ask any question about faith, prayer, or life challenges, and receive thoughtful guidance rooted in Christian wisdom. Simply type your question and press enter."
    );
  }

  void _showIntervalSelection() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Prayer Interval'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('3 minutes'),
                leading: Radio<String>(
                  value: '3 minutes',
                  groupValue: _selectedInterval,
                  onChanged: (value) {
                    setState(() {
                      _selectedInterval = value!;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
              ListTile(
                title: const Text('5 minutes'),
                leading: Radio<String>(
                  value: '5 minutes',
                  groupValue: _selectedInterval,
                  onChanged: (value) {
                    setState(() {
                      _selectedInterval = value!;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
              ListTile(
                title: const Text('10 minutes'),
                leading: Radio<String>(
                  value: '10 minutes',
                  groupValue: _selectedInterval,
                  onChanged: (value) {
                    setState(() {
                      _selectedInterval = value!;
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Theta iOS Wallpaper Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/Theta_iOS_Wallpaper.png',
              fit: BoxFit.cover,
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                // TOP BUTTONS - DARK BLUE (Windows MVP Style)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      // What is Theta Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _activeTab = 0;
                            });
                            // Play What is Theta narration
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A5F), // Dark blue
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 3,
                          ),
                          child: const Text(
                            'What is Theta',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Prayer Intervals Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _activeTab = 1;
                            });
                            _showIntervalSelection();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A5F), // Dark blue
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 3,
                          ),
                          child: const Text(
                            'Prayer Intervals',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main Content Area
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // NO THETA TEXT HERE - REMOVED!
                      // Just show stopwatch when active
                      
                      // Add spacing to lower the stopwatch by 4cm
                      const SizedBox(height: 150),  // Lowers stopwatch position
                      
                      // Stopwatch display - BIGGER & LOWER NOW
                      if (_isActive) 
                        AnimatedOpacity(
                          opacity: _isActive ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            _formatStopwatch(_elapsedSeconds),
                            style: const TextStyle(
                              fontSize: 48,  // MUCH BIGGER
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 2),
                                  blurRadius: 6,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      // FIXED SPACING - Same whether active or not (no movement)
                      const SizedBox(height: 320),  // FIXED spacing - Guide Me won't move
                      
                      // GUIDE ME SEARCH BAR - LOWERED POSITION
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 30),
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
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
                            // Guide Me Button (30% of bar)
                            Expanded(
                              flex: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A7BA7),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(25),
                                    bottomLeft: Radius.circular(25),
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(25),
                                      bottomLeft: Radius.circular(25),
                                    ),
                                    onTap: _playGuideExplanation,
                                    child: const Center(
                                      child: Text(
                                        'Guide Me',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Search area (70% of bar)
                            Expanded(
                              flex: 7,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 15),
                                child: const TextField(
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Ask a question...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Magnifying glass icon
                            const Padding(
                              padding: EdgeInsets.only(right: 15),
                              child: Icon(
                                Icons.search,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Bottom Action Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // START / REPEAT Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isActive ? _repeatPrayer : _startTheta,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _isActive ? 'REPEAT' : 'START / REPEAT',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // STOP THETA Button  
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isActive ? _stopTheta : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            disabledBackgroundColor: Colors.red.withOpacity(0.3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'STOP THETA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}