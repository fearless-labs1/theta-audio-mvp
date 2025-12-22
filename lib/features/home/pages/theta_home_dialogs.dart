part of 'theta_home_page.dart';

mixin _DialogBuilders on State<ThetaHomePage> {
  // Members provided by _ThetaHomePageState
  Future<void> _stopDialogAudioAndRestoreMusic();
  Future<void> _playDialogAudioWithMusicFade(String assetPath);
  Future<void> _duckMusicForIntro();
  Future<void> _restoreMusicAfterIntro();
  Future<void> _toggleBackgroundMusic();
  bool get _isMusicPlaying;
  int get _selectedInterval;
  set _selectedInterval(int minutes);
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
            _goldAccent.withValues(alpha: 0.3),
            _goldAccent.withValues(alpha: 0.1),
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
                  if (controller.hasClients &&
                      controller.position.maxScrollExtent > 0) {
                    maxScroll = controller.position.maxScrollExtent;
                    scrollFraction =
                        (controller.offset / maxScroll).clamp(0.0, 1.0);
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
                      final scrollDelta = details.delta.dy *
                          (maxScroll / (constraints.maxHeight * 0.9));
                      final newOffset = (controller.offset + scrollDelta)
                          .clamp(0.0, maxScroll);
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
            color: _goldAccent.withValues(alpha: 0.25),
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
            Container(height: 2, color: _goldAccent.withValues(alpha: 0.3)),
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
  // ignore: unused_element
  Future<void> _showAboutDialog() async {
    await _playDialogAudioWithMusicFade('audio/what_is_theta.mp3');

    if (!mounted) return;

    final ScrollController scrollController = ScrollController();

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
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
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'Theta features two modes of use:',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Theta Mode — Prayers are spoken aloud, and the user repeats (speaks) each line immediately.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Goliath Mode — Affirmations are spoken aloud, and the user repeats (speaks) each line immediately.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'The personal computer versions can be played through speakers or Bluetooth wireless earphones or earbuds, throughout your homes, bedrooms, children bedrooms or offices.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'The mobile versions can be played through device speakers or car audio systems, but is optimally enjoyed through a single Bluetooth wireless earbud - discreetly keeping you in a constant state of Theta throughout your day, irrelevant of your location or situation, helping you stay focused on what is most important, the Word of God and His Will for our lives.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Theta was designed to simulate its users to repeat each Prayer or Affirmation out aloud, or under their breath, either way "speaking" the transformative word of God.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
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
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'but in the living Word of God being "spoken" after each prayer or affirmation is played, and the heart of the person speaking, postured towards the Lord.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Our words have power because God hears them, God responds to them, and God uses them.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'We declare this not as self-generated power, but by calling on God\'s power.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'We do not command reality — we pray, affirm, proclaim, and bless using His authority.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Our words hold real influence — to build up or tear down — and God commands us to use them for life.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'We are instructed to speak God\'s Word with authority, daily.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'By repeatedly doing this, you enter into a state of "Theta", of total gratitude for Gods Power, constant favor and presence in your life.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
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
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
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
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
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
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Voice matters — speak audibly. The ear hears what the heart receives.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Use emotion and faith — speak with expectancy, not vain repetition.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Be consistent — spiritual fruit grows with steady discipline.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Not magic: this is not formulaic "name it and claim it" without God\'s will. It\'s faithful engagement with God\'s Word.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Humility: avoid prideful, self-centered tone. Subordinate declarations to God\'s will, always keep a surrendered heart.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Use each Prayer and Affirmation as a starting point to a longer prayer you engage with God through, adding your own personal requests, gratefulness and declarations after the prayer has finished playing.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
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
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Affirmations reinforce your mind, heart, and the spiritual atmosphere with Scripture-based truth.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Together: you ask God and declare God\'s truth — you engage God and align your thinking with Him. That\'s both relational and authoritative.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Together, they are extremely powerful:',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• You pray for strength.\n• You affirm that God is your strength.\n• You pray for protection.\n• You affirm that no weapon formed against you will prosper.\n• You pray for peace.\n• You affirm that the peace of Christ rules in your heart.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
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
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'Prayers and Affirmations rooted in Scripture act like weapons, especially when spoken out loud:',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Truth replaces lies.\n• Faith replaces fear.\n• God\'s promises replace anxiety.\n• Identity replaces confusion.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'God creates, commands, heals, corrects, and blesses through spoken words — and Scripture connects that same principle to the believer\'s life.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  'God didn\'t merely think creation — Scripture repeatedly emphasizes that He spoke it.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 12),
                Text(
                  '& as his children, we are called to do the same.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
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
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
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
  // ignore: unused_element
  Future<void> _showGuideMeInfo() async {
    await _playDialogAudioWithMusicFade('audio/guide_me_info.mp3');

    if (!mounted) return;

    final ScrollController scrollController = ScrollController();

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
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
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'Theta presents a powerful Ai engineered model called "Guide Me", which when activated - will enquire how it can assist you, according to the Word of God.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'This feature essentially makes Theta a powerful Christian LLM search engine, like ChatGPT, Gemini, Grok, but with all outputs guided and governed by the principles of the Word of God, and the teachings therein.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'Unlike how ChatGPT, Gemini, Grok or any other mainstream LLM will currently respond if you start a chat, with the AI responding in its default, generic voice — mixing opinions, culture & psychology, which in most cases is far from the teachings supplied by the Word of God, the Bible.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'The Theta "Guide Me" model will respond with strict guidance and reference to scripture only - Equating to undiluted, clear guidance and reference according to the Word of God.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 20),
                Text(
                  'Your first message should be:',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _darkText),
                ),
                const SizedBox(height: 10),
                Text(
                  '• Clear\n• Purposeful\n• Direct',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 16),
                Text(
                  'Give as much detail as possible to your situation, your challenge, or your requirements - The engineered "Guide Me" model is exceptionally clever and can handle all details, stories, descriptions etc one gives it.',
                  style: GoogleFonts.lora(
                      fontSize: 14, height: 1.7, color: _bodyText),
                ),
                const SizedBox(height: 20),
                Text(
                  'Examples:',
                  style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _darkText),
                ),
                const SizedBox(height: 10),
                // Example 1
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _goldAccent.withValues(alpha: 0.05),
                    border: Border.all(
                        color: _goldAccent.withValues(alpha: 0.3), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"My wife and I have been married for X years, yet there is always these hidden agendas, secrets and white lies in our marriage, I\'d love to approach her and ask her to stop this once and for all, and help me regain trust in her, so I can stop doubting her and our marriage, feel safe and open up to her, but when ever I do, it always ends up in a massive argument with her resenting me. What can I do?"',
                    style: GoogleFonts.lora(
                        fontSize: 13,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        color: _bodyText),
                  ),
                ),
                // Example 2
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _goldAccent.withValues(alpha: 0.05),
                    border: Border.all(
                        color: _goldAccent.withValues(alpha: 0.3), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"I am experiencing spiritual exhaustion in my family. What does Scripture teach about renewing strength?"',
                    style: GoogleFonts.lora(
                        fontSize: 13,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        color: _bodyText),
                  ),
                ),
                // Example 3
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _goldAccent.withValues(alpha: 0.05),
                    border: Border.all(
                        color: _goldAccent.withValues(alpha: 0.3), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"Today is a Sunday, I am Christian and Christian\'s are forbidden to work on Sundays, but I want to work on a free Christian book to advance Gods Kingdom, I will be giving the book away for free, can I work on the book today?"',
                    style: GoogleFonts.lora(
                        fontSize: 13,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        color: _bodyText),
                  ),
                ),
                // Example 4
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _goldAccent.withValues(alpha: 0.05),
                    border: Border.all(
                        color: _goldAccent.withValues(alpha: 0.3), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '"Let us begin in prayer about forgiveness of a family member / work colleague / friend."',
                    style: GoogleFonts.lora(
                        fontSize: 13,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        color: _bodyText),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Be descriptive, the more information you feed into "Guide Me", the more value you will get back in return.',
                  style: GoogleFonts.lora(
                      fontSize: 14,
                      height: 1.7,
                      color: _bodyText,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Enjoy Theta',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _darkText),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '& enjoy being guided by scripture.',
                    style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _goldAccent),
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

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
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
              style:
                  GoogleFonts.lora(fontSize: 14, height: 1.7, color: _bodyText),
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
      barrierColor: Colors.black.withValues(alpha: 0.7),
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
                    child: const Icon(Icons.error_outline,
                        color: _goldAccent, size: 26),
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
                style: GoogleFonts.lora(
                    fontSize: 14, color: _bodyText, height: 1.6),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _goldAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _goldAccent, width: 1.5),
                ),
                child: Text(
                  'Take a breath, then try again. If the issue continues, check your connection and keep worshipping.',
                  style: GoogleFonts.lora(
                      fontSize: 12.5, height: 1.5, color: _bodyText),
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
  // ignore: unused_element
  Future<void> _showIntervalSelection() async {
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
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
                      color: _goldAccent.withValues(alpha: 0.25),
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
                      Container(
                          height: 2, color: _goldAccent.withValues(alpha: 0.3)),
                      // Interval buttons
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            _buildOption5IntervalTile(
                                '3 minutes', 3, setDialogState),
                            const SizedBox(height: 10),
                            _buildOption5IntervalTile(
                                '5 minutes', 5, setDialogState),
                            const SizedBox(height: 10),
                            _buildOption5IntervalTile(
                                '10 minutes', 10, setDialogState),
                            const SizedBox(height: 20),
                            Container(
                                height: 1,
                                color: _goldAccent.withValues(alpha: 0.3)),
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
                                          ? _goldAccent.withValues(alpha: 0.2)
                                          : Colors.red.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _isMusicPlaying
                                            ? _goldAccent
                                            : Colors.red,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      _isMusicPlaying
                                          ? Icons.music_note
                                          : Icons.music_off,
                                      color: _isMusicPlaying
                                          ? _goldAccent
                                          : Colors.red,
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

  Widget _buildOption5IntervalTile(
      String label, int minutes, StateSetter setDialogState) {
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
          color:
              isSelected ? _goldAccent.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _goldAccent : const Color(0xFFDDDDDD),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _goldAccent.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ]
              : null,
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
}
