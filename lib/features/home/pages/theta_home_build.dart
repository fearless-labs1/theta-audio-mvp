part of 'theta_home_page.dart';

mixin _HomePageBuild on State<ThetaHomePage> {
  Widget buildHomePage(BuildContext context) {
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
                      _goliathActiveColor.withValues(alpha: 0.28),
                      Colors.black.withValues(alpha: 0.05),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              color: _buttonsDisabled
                                  ? Colors.grey[600]
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Prayer Intervals button
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              _buttonsDisabled ? null : _showIntervalSelection,
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
                              color: _buttonsDisabled
                                  ? Colors.grey[600]
                                  : Colors.black,
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
                        const Expanded(
                            child:
                                SizedBox()), // Spacer keeps bottom elements in position

                      // Aesthetic gap below Divine Shuffle
                      const SizedBox(height: 8),

                      // STATUS INDICATOR - above Guide Me search bar
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                          border:
                              Border.all(color: Colors.grey[400]!, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
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
                                onPressed:
                                    _buttonsDisabled ? null : _showGuideMeInfo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _buttonsDisabled
                                      ? Colors.grey
                                      : Colors.black,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8),
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
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                  style: GoogleFonts.lora(fontSize: 12),
                                  onSubmitted: (value) {
                                    if (!_isLoadingGPTResponse &&
                                        !_buttonsDisabled) {
                                      _sendQuestionToGPT(value);
                                    }
                                  },
                                ),
                              ),
                            ),
                            // Magnifying glass button
                            IconButton(
                              icon: const Icon(Icons.search, size: 20),
                              color:
                                  _buttonsDisabled ? Colors.grey : Colors.black,
                              onPressed:
                                  (_isLoadingGPTResponse || _buttonsDisabled)
                                      ? null
                                      : () => _sendQuestionToGPT(
                                          _guideMeController.text),
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
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 30),
                  child: Column(
                    children: [
                      // Row 1: START/REPEAT and STOP buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // START / REPEAT button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (_isGoliathMode || _buttonsDisabled)
                                  ? null
                                  : _startOrRepeat,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                disabledBackgroundColor: Colors.grey[400],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow,
                                      size: 22,
                                      color:
                                          (_isGoliathMode || _buttonsDisabled)
                                              ? Colors.grey
                                              : Colors.green),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Start / Repeat',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          (_isGoliathMode || _buttonsDisabled)
                                              ? Colors.grey
                                              : Colors.black,
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
                              onPressed: (!_isActive ||
                                      _isGoliathMode ||
                                      _buttonsDisabled)
                                  ? null
                                  : _stopTheta,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                disabledBackgroundColor: Colors.grey[400],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                elevation: 4,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.stop,
                                      size: 22,
                                      color: (_isActive &&
                                              !_isGoliathMode &&
                                              !_buttonsDisabled)
                                          ? Colors.red
                                          : Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Stop Theta',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: (_isActive &&
                                              !_isGoliathMode &&
                                              !_buttonsDisabled)
                                          ? Colors.black
                                          : Colors.grey,
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
                          onPressed:
                              _buttonsDisabled ? null : _toggleGoliathMode,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isGoliathMode
                                ? _goliathActiveColor
                                : Colors.grey[300],
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
                                    : (_isGoliathMode
                                        ? Colors.white
                                        : Colors.black),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isGoliathMode ? 'Deactivate' : 'Goliath Mode',
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _buttonsDisabled
                                      ? Colors.grey[600]
                                      : (_isGoliathMode
                                          ? Colors.white
                                          : Colors.black),
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
              color: Colors.black.withValues(alpha: 0.7),
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
                      style:
                          GoogleFonts.lora(color: Colors.white, fontSize: 16),
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
                  style: GoogleFonts.montserrat(
                      color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Initialization loading
          if (!_isInitialized && _errorMessage == null)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)),
                    const SizedBox(height: 16),
                    Text(
                      'Initializing Theta...',
                      style:
                          GoogleFonts.lora(color: Colors.white, fontSize: 16),
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
