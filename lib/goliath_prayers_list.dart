// Theta Audio MVP - Goliath Mode Prayer Registry
//
// 50 Powerful Spiritual Warfare Prayers
// NOT time-based - can play at any time
// Duplicate prevention (no prayer plays twice in a row)
//
// Voice: shimmer @ 0.70 speed (humble, meek)

import 'dart:math';

class GoliathPrayersList {
  static final _random = Random();

  // Track last played prayer to prevent duplicates
  static String? _lastPlayedPrayer;

  /// All 50 Spiritual Warfare Prayers
  static const List<String> prayers = [
    // Breaking Chains & Bondage (G001-G010)
    'audio/goliath/G001_break_every_chain.mp3',
    'audio/goliath/G002_destroy_strongholds.mp3',
    'audio/goliath/G003_release_from_bondage.mp3',
    'audio/goliath/G004_sever_ungodly_ties.mp3',
    'audio/goliath/G005_cancel_assignments.mp3',
    'audio/goliath/G006_demolish_barriers.mp3',
    'audio/goliath/G007_shatter_limitations.mp3',
    'audio/goliath/G008_break_generational_curses.mp3',
    'audio/goliath/G009_loose_heavens_power.mp3',
    'audio/goliath/G010_bind_the_enemy.mp3',

    // Authority & Dominion (G011-G020)
    'audio/goliath/G011_declare_authority.mp3',
    'audio/goliath/G012_exercise_dominion.mp3',
    'audio/goliath/G013_command_the_enemy.mp3',
    'audio/goliath/G014_take_back_ground.mp3',
    'audio/goliath/G015_stand_unmovable.mp3',
    'audio/goliath/G016_resist_the_devil.mp3',
    'audio/goliath/G017_enforce_victory.mp3',
    'audio/goliath/G018_declare_triumph.mp3',
    'audio/goliath/G019_claim_inheritance.mp3',
    'audio/goliath/G020_walk_in_power.mp3',

    // Protection & Defense (G021-G030)
    'audio/goliath/G021_blood_covering.mp3',
    'audio/goliath/G022_angelic_protection.mp3',
    'audio/goliath/G023_shield_of_faith.mp3',
    'audio/goliath/G024_armor_activated.mp3',
    'audio/goliath/G025_fortress_of_god.mp3',
    'audio/goliath/G026_hedge_of_protection.mp3',
    'audio/goliath/G027_fire_wall.mp3',
    'audio/goliath/G028_divine_concealment.mp3',
    'audio/goliath/G029_guard_my_gates.mp3',
    'audio/goliath/G030_secure_my_house.mp3',

    // Offensive Warfare (G031-G040)
    'audio/goliath/G031_weapons_of_war.mp3',
    'audio/goliath/G032_sword_of_spirit.mp3',
    'audio/goliath/G033_fire_from_heaven.mp3',
    'audio/goliath/G034_thunder_against_enemies.mp3',
    'audio/goliath/G035_pursue_and_overtake.mp3',
    'audio/goliath/G036_trample_the_serpent.mp3',
    'audio/goliath/G037_dismantle_darkness.mp3',
    'audio/goliath/G038_scatter_the_enemy.mp3',
    'audio/goliath/G039_send_confusion.mp3',
    'audio/goliath/G040_release_judgment.mp3',

    // Victory Declarations (G041-G050)
    'audio/goliath/G041_already_won.mp3',
    'audio/goliath/G042_no_defeat.mp3',
    'audio/goliath/G043_champion_rising.mp3',
    'audio/goliath/G044_giant_slayer.mp3',
    'audio/goliath/G045_overcomer_anointing.mp3',
    'audio/goliath/G046_unstoppable_force.mp3',
    'audio/goliath/G047_fearless_warrior.mp3',
    'audio/goliath/G048_complete_victory.mp3',
    'audio/goliath/G049_enemy_under_feet.mp3',
    'audio/goliath/G050_battle_cry.mp3',
  ];

  /// Get total number of prayers
  static int get count => prayers.length;

  /// Get random prayer with DUPLICATE PREVENTION
  /// Never plays the same prayer twice in a row
  static String getRandomPrayer() {
    String selectedPrayer;
    int attempts = 0;
    const maxAttempts = 10;

    do {
      selectedPrayer = prayers[_random.nextInt(prayers.length)];
      attempts++;
    } while (selectedPrayer == _lastPlayedPrayer && attempts < maxAttempts);

    // Store for next comparison
    _lastPlayedPrayer = selectedPrayer;

    return selectedPrayer;
  }

  /// Reset last played prayer (called on mode switch)
  static void resetLastPlayed() {
    _lastPlayedPrayer = null;
  }

  /// Validate prayer count
  static bool validatePrayers() {
    return count == 50;
  }
}
