// Theta Audio MVP - Prayer File Registry (ANDROID PRODUCTION)
//
// 150 Time-based prayers organized by time of day:
// - Morning (001-050): 5am-11am
// - Neutral (051-100): 11am-6pm
// - Evening (101-150): 6pm-5am
//
// Features:
// - Time-based selection
// - Duplicate prevention (no prayer plays twice in a row)
// - getCurrentCategoryName() for status display

import 'dart:math';

class PrayersList {
  static final Random _random = Random();
  static String? _lastPlayedPrayer;

  // Morning prayers (001-050): 5am-11am
  static const List<String> morningPrayers = [
    'audio/001_morning_gratitude.mp3',
    'audio/002_courage_prayer.mp3',
    'audio/003_strength_in_weakness.mp3',
    'audio/004_brave_heart.mp3',
    'audio/005_divine_guidance.mp3',
    'audio/006_morning_gratitude.mp3',
    'audio/007_discernment.mp3',
    'audio/008_right_path.mp3',
    'audio/009_clarity_seeking.mp3',
    'audio/010_safe_journey.mp3',
    'audio/011_new_beginnings.mp3',
    'audio/012_fresh_start.mp3',
    'audio/013_work_dedication.mp3',
    'audio/014_purpose_discovery.mp3',
    'audio/015_career_guidance.mp3',
    'audio/016_success_prayer.mp3',
    'audio/017_calling_clarification.mp3',
    'audio/018_morning_consecration.mp3',
    'audio/019_morning_awakening.mp3',
    'audio/020_dawn_dedication.mp3',
    'audio/021_morning_strength.mp3',
    'audio/022_daily_purpose.mp3',
    'audio/023_morning_clarity.mp3',
    'audio/024_new_day_blessing.mp3',
    'audio/025_morning_protection.mp3',
    'audio/026_rising_faith.mp3',
    'audio/027_morning_focus.mp3',
    'audio/028_daybreak_praise.mp3',
    'audio/029_morning_victory.mp3',
    'audio/030_dawn_renewal.mp3',
    'audio/031_morning_vision.mp3',
    'audio/032_daylight_courage.mp3',
    'audio/033_morning_assignment.mp3',
    'audio/034_sunrise_hope.mp3',
    'audio/035_morning_preparation.mp3',
    'audio/036_daily_surrender.mp3',
    'audio/037_morning_authority.mp3',
    'audio/038_dawn_decree.mp3',
    'audio/039_morning_readiness.mp3',
    'audio/040_daystart_anointing.mp3',
    'audio/041_morning_expectation.mp3',
    'audio/042_sunrise_declaration.mp3',
    'audio/043_morning_commissioning.mp3',
    'audio/044_dawn_empowerment.mp3',
    'audio/045_morning_alignment.mp3',
    'audio/046_daybreak_covering.mp3',
    'audio/047_morning_mandate.mp3',
    'audio/048_sunrise_activation.mp3',
    'audio/049_morning_overflow.mp3',
    'audio/050_dawn_commission.mp3',
  ];

  // Neutral prayers (051-100): 11am-6pm
  static const List<String> neutralPrayers = [
    'audio/051_lords_prayer.mp3',
    'audio/052_serenity_prayer.mp3',
    'audio/053_prayer_of_st_francis.mp3',
    'audio/054_divine_favor.mp3',
    'audio/055_guardian_angel_prayer.mp3',
    'audio/056_grateful_heart.mp3',
    'audio/057_thanksgiving_prayer.mp3',
    'audio/058_blessings_count.mp3',
    'audio/059_warriors_prayer.mp3',
    'audio/060_healing_light.mp3',
    'audio/061_body_restoration.mp3',
    'audio/062_spiritual_wholeness.mp3',
    'audio/063_divine_love.mp3',
    'audio/064_compassionate_heart.mp3',
    'audio/065_love_thy_neighbor.mp3',
    'audio/066_forgiveness_prayer.mp3',
    'audio/067_unconditional_love.mp3',
    'audio/068_angels_protection.mp3',
    'audio/069_shield_of_faith.mp3',
    'audio/070_protective_light.mp3',
    'audio/071_armor_of_god.mp3',
    'audio/072_faith_builder.mp3',
    'audio/073_trust_in_divine.mp3',
    'audio/074_leap_of_faith.mp3',
    'audio/075_belief_strengthening.mp3',
    'audio/076_hope_renewed.mp3',
    'audio/077_resurrection_hope.mp3',
    'audio/078_tomorrow_promise.mp3',
    'audio/079_abundance_mindset.mp3',
    'audio/080_prosperity_prayer.mp3',
    'audio/081_blessings_flow.mp3',
    'audio/082_provision_faith.mp3',
    'audio/083_grateful_abundance.mp3',
    'audio/084_family_blessing.mp3',
    'audio/085_marriage_prayer.mp3',
    'audio/086_children_protection.mp3',
    'audio/087_parents_honor.mp3',
    'audio/088_friendship_prayer.mp3',
    'audio/089_joyful_heart.mp3',
    'audio/090_celebration_thanks.mp3',
    'audio/091_happiness_prayer.mp3',
    'audio/092_laughter_gift.mp3',
    'audio/093_delight_in_life.mp3',
    'audio/094_patience_cultivation.mp3',
    'audio/095_endurance_prayer.mp3',
    'audio/096_steadfast_spirit.mp3',
    'audio/097_waiting_grace.mp3',
    'audio/098_persistence_strength.mp3',
    'audio/099_humble_heart.mp3',
    'audio/100_servant_leadership.mp3',
  ];

  // Evening prayers (101-150): 6pm-5am
  static const List<String> eveningPrayers = [
    'audio/101_evening_thankfulness.mp3',
    'audio/102_inner_peace.mp3',
    'audio/103_calm_spirit.mp3',
    'audio/104_peaceful_heart.mp3',
    'audio/105_still_waters.mp3',
    'audio/106_quiet_mind.mp3',
    'audio/107_fear_release.mp3',
    'audio/108_emotional_healing.mp3',
    'audio/109_comfort_in_pain.mp3',
    'audio/110_surrender_prayer.mp3',
    'audio/111_evening_reflection.mp3',
    'audio/112_bedtime_peace.mp3',
    'audio/113_daily_surrender_night.mp3',
    'audio/114_evening_rest.mp3',
    'audio/115_nightfall_peace.mp3',
    'audio/116_twilight_surrender.mp3',
    'audio/117_evening_review.mp3',
    'audio/118_dusk_release.mp3',
    'audio/119_nighttime_healing.mp3',
    'audio/120_evening_gratitude.mp3',
    'audio/121_bedtime_protection.mp3',
    'audio/122_sunset_reflection.mp3',
    'audio/123_night_stillness.mp3',
    'audio/124_evening_forgiveness.mp3',
    'audio/125_nightfall_trust.mp3',
    'audio/126_twilight_thanksgiving.mp3',
    'audio/127_bedtime_calm.mp3',
    'audio/128_evening_closure.mp3',
    'audio/129_night_renewal.mp3',
    'audio/130_dusk_contentment.mp3',
    'audio/131_evening_sanctuary.mp3',
    'audio/132_nighttime_serenity.mp3',
    'audio/133_sunset_blessing.mp3',
    'audio/134_evening_quieting.mp3',
    'audio/135_bedtime_letting_go.mp3',
    'audio/136_nightfall_reassurance.mp3',
    'audio/137_twilight_comfort.mp3',
    'audio/138_evening_completion.mp3',
    'audio/139_night_shelter.mp3',
    'audio/140_dusk_meditation.mp3',
    'audio/141_evening_trust.mp3',
    'audio/142_bedtime_worship.mp3',
    'audio/143_nightfall_preparation.mp3',
    'audio/144_sunset_thankfulness.mp3',
    'audio/145_evening_restoration.mp3',
    'audio/146_night_communion.mp3',
    'audio/147_twilight_release.mp3',
    'audio/148_bedtime_assurance.mp3',
    'audio/149_evening_benediction.mp3',
    'audio/150_nightfall_grace.mp3',
  ];

  // Get time-based prayer based on current hour with DUPLICATE PREVENTION
  static String getTimeBasedPrayer() {
    final hour = DateTime.now().hour;

    List<String> prayerList;
    if (hour >= 5 && hour < 11) {
      // Morning: 5am-11am
      prayerList = morningPrayers;
    } else if (hour >= 11 && hour < 18) {
      // Neutral: 11am-6pm
      prayerList = neutralPrayers;
    } else {
      // Evening: 6pm-5am
      prayerList = eveningPrayers;
    }

    // Duplicate prevention: Don't play same prayer twice in a row
    String selectedPrayer;
    int attempts = 0;
    const maxAttempts = 10;

    do {
      selectedPrayer = prayerList[_random.nextInt(prayerList.length)];
      attempts++;
    } while (selectedPrayer == _lastPlayedPrayer && attempts < maxAttempts);

    _lastPlayedPrayer = selectedPrayer;
    return selectedPrayer;
  }

  // Get random prayer (alias for getTimeBasedPrayer)
  static String getRandomPrayer() {
    return getTimeBasedPrayer();
  }

  // Get current time category name with emoji for status display
  // Returns: "🌅 Morning Prayers" or "☀️ Mid-day Prayers" or "🌙 Evening Prayers"
  static String getCurrentCategoryName() {
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

  // Get total prayer count
  static int get totalCount =>
      morningPrayers.length + neutralPrayers.length + eveningPrayers.length;

  // Reset last played (for mode switching)
  static void resetLastPlayed() {
    _lastPlayedPrayer = null;
  }
}
