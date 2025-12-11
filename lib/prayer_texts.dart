/// Theta Audio MVP - Prayer Texts (CORRECTED FROM MASTER)
/// 
/// Contains the full text of all 200 prayers for Divine Shuffle display.
/// Organized by session: Morning (001-050), Mid-Day (051-100), Evening (101-150), Goliath (G001-G050)
/// 
/// CORRECTED: November 30, 2025 - All texts verified against master prayer list

class PrayerTexts {
  
  /// Get prayer text by asset path
  static String? getTextByPath(String path) {
    // Extract prayer ID from path (e.g., "audio/001_morning_gratitude.mp3" -> "001")
    final filename = path.split('/').last;
    final id = filename.split('_').first.replaceAll('.mp3', '');
    return _prayerTexts[id];
  }
  
  /// Get prayer number from path (e.g., "001" or "G001")
  static String getPrayerNumber(String path) {
    final filename = path.split('/').last;
    return filename.split('_').first;
  }
  
  /// Get prayer name from path
  static String getPrayerName(String path) {
    final filename = path.split('/').last.replaceAll('.mp3', '');
    final parts = filename.split('_');
    if (parts.length > 1) {
      return parts.sublist(1).map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
    }
    return filename;
  }
  
  static const Map<String, String> _prayerTexts = {
    // ═══════════════════════════════════════════════════════════════════════
    // MORNING PRAYERS (001-050) - 5am to 11am
    // ═══════════════════════════════════════════════════════════════════════
    '001': 'Thank you, Divine Source, for this new day. I am grateful for the breath in my lungs, the beating of my heart, and the opportunity to experience life. May I walk this day with appreciation and wonder.',
    '002': 'Grant me courage to face what lies ahead. Strengthen my resolve. Fortify my spirit. I am brave. I am strong. I can overcome any challenge.',
    '003': 'When I am weak, make me strong. When I falter, lift me up. Your power flows through me. I am capable beyond my own understanding.',
    '004': 'My heart beats with courage. Fear does not control me. I step forward boldly into the unknown. I am brave. I am fearless. I am empowered.',
    '005': 'Guide me on the right path. Show me the way forward. Illuminate my steps. I trust your guidance. I follow your lead.',
    '006': 'Grant me wisdom to make right decisions. Clarity to see truth. Understanding to comprehend what matters most. I am wise.',
    '007': 'I discern truth from falsehood. Wisdom from foolishness. Good from evil. My intuition is sharp. My judgment is sound.',
    '008': 'I walk the path meant for me. I trust the journey. Every step leads me closer to my purpose. I am on the right path.',
    '009': 'I seek clarity in confusion. Light in darkness. Understanding in complexity. My mind is clear. My vision is sharp.',
    '010': 'Protect me on my journey. Keep me safe from harm. Guide my steps. Watch over me. I travel under divine protection.',
    '011': 'Every day is a new beginning. A fresh start. A clean slate. I embrace new possibilities with open arms.',
    '012': 'I start fresh. Past mistakes are behind me. The future is bright. Today I begin again with hope and enthusiasm.',
    '013': 'I dedicate my work to the highest good. May my efforts serve others. May I find meaning in my labor.',
    '014': 'Reveal my life\'s purpose to me. Show me why I am here. Help me fulfill my unique calling. I am ready to serve.',
    '015': 'Guide my career path. Open right doors. Close wrong doors. Lead me to work that fulfills and sustains me.',
    '016': 'I am successful in all I do. My efforts bear fruit. My work is recognized and valued. I achieve my goals.',
    '017': 'Clarify my calling. Help me understand my gifts. Show me how to use my talents for the greater good.',
    '018': 'I consecrate this day to the highest good. May all I do, say, and think serve love. This day is sacred.',
    '019': 'I awaken to Your presence. Fresh mercies greet this new day. My spirit rises with the sun, ready to walk in Your light.',
    '020': 'As dawn breaks, I dedicate these hours to You. Guide my steps, order my day, and let Your will be done through me.',
    '021': 'Lord, fill me with strength for today. Renew my energy, sharpen my focus, and empower me to accomplish Your purposes.',
    '022': 'Reveal my purpose for today. Show me the divine appointments You have prepared. I am ready to serve.',
    '023': 'Clear my mind as the morning mist lifts. Help me see with Your eyes and think with Your wisdom today.',
    '024': 'Bless this new day with Your favor. Open doors of opportunity and guide me through each moment with grace.',
    '025': 'Cover me with Your protection as I go forth today. Guard my steps, my words, and my heart.',
    '026': 'My faith rises with the sun. I step into this day believing in Your goodness and trusting Your plan.',
    '027': 'Help me focus on what matters most today. Remove distractions and keep my eyes fixed on You.',
    '028': 'At daybreak, I praise You. For life, for breath, for this opportunity to walk in Your light one more day.',
    '029': 'I declare victory over this day. In Your strength, I will overcome every challenge and walk in triumph.',
    '030': 'Renew me at dawn. Make me fresh, alert, and ready to embrace all You have for me today.',
    '031': 'Give me vision for today. Let me see opportunities to love, serve, and glorify You in all I do.',
    '032': 'As daylight comes, courage fills my heart. I face today boldly, knowing You walk beside me.',
    '033': 'Show me my assignment for today. I am Your willing servant, ready to fulfill Your calling.',
    '034': 'Hope rises with the sunrise. Yesterday is gone, today is fresh, tomorrow is bright in Your hands.',
    '035': 'Prepare me for today\'s journey. Equip me with wisdom, patience, and love for all I encounter.',
    '036': 'I surrender this day to Your lordship. May Your will be done in every moment and every decision.',
    '037': 'I walk in spiritual authority today. Your power flows through me to accomplish Your purposes.',
    '038': 'I decree blessings over this day. Favor, provision, protection, and divine appointments.',
    '039': 'I am ready for whatever today brings. Your grace is sufficient, Your strength is perfect.',
    '040': 'Anoint me for this day\'s work. Let Your presence be evident in all I do and say.',
    '041': 'I expect good things today. Your faithfulness never fails, Your mercies never end.',
    '042': 'I declare: Today will be fruitful, purposeful, and filled with Your presence.',
    '043': 'Commission me for today\'s tasks. I go as Your ambassador, carrying Your light.',
    '044': 'Empower me for today. Your Spirit within me is greater than any challenge I may face.',
    '045': 'Align my heart with Yours today. Let my desires match Your will, my steps follow Your path.',
    '046': 'Cover me with Your favor today. Let Your blessing rest upon all I touch and encounter.',
    '047': 'I receive Your mandate for today. Show me what to do, where to go, who to help.',
    '048': 'Activate Your gifts in me today. Let every talent and ability glorify You and serve others.',
    '049': 'Let Your goodness overflow through me today. May I be a blessing to everyone I meet.',
    '050': 'You have commissioned me for this day. I will not waste it. I will walk worthy of Your calling.',

    // ═══════════════════════════════════════════════════════════════════════
    // MID-DAY/NEUTRAL PRAYERS (051-100) - 11am to 6pm
    // ═══════════════════════════════════════════════════════════════════════
    '051': 'Our Father, who art in heaven, hallowed be thy name. Thy kingdom come, thy will be done, on earth as it is in heaven. Give us this day our daily bread, and forgive us our trespasses, as we forgive those who trespass against us. And lead us not into temptation, but deliver us from evil.',
    '052': 'God, grant me the serenity to accept the things I cannot change, courage to change the things I can, and wisdom to know the difference. Living one day at a time, enjoying one moment at a time. Accepting hardship as a pathway to peace.',
    '053': 'Lord, make me an instrument of your peace. Where there is hatred, let me sow love. Where there is injury, pardon. Where there is doubt, faith. Where there is despair, hope. Where there is darkness, light. Where there is sadness, joy.',
    '054': 'I walk in Your favor today. Your grace goes before me, preparing the way and opening doors I cannot open myself.',
    '055': 'Angel of God, my guardian dear, to whom God\'s love commits me here. Ever this day be at my side, to light and guard, to rule and guide.',
    '056': 'I cultivate a heart overflowing with gratitude. For every blessing, seen and unseen, I give thanks. May appreciation be my constant companion on this journey.',
    '057': 'For food, shelter, and love. For friends, family, and community. For health, strength, and opportunity. I give deep and sincere thanks. May I never take these gifts for granted.',
    '058': 'I count my blessings, one by one. Each person, each moment, each gift. My life is rich beyond measure. I am truly blessed. Thank you.',
    '059': 'I am a spiritual warrior. I face life\'s battles with grace and power. No obstacle can defeat me. No challenge can break me. I am victorious.',
    '060': 'Divine healing light flows through every cell of my body. I am restored. I am renewed. I am whole. Health radiates from within me.',
    '061': 'My body knows how to heal. I support its natural wisdom. Every system works in harmony. I am returning to perfect health.',
    '062': 'My spirit is being restored to wholeness. Broken pieces are coming together. I am spiritually complete. I am divinely healed.',
    '063': 'I am loved beyond measure. Divine love surrounds me, fills me, transforms me. I am worthy of love. I am made of love.',
    '064': 'May my heart overflow with compassion. For myself, for others, for all beings. I see with eyes of love. I act with kindness.',
    '065': 'I love my neighbor as myself. I extend kindness to all I meet. Every person is worthy of respect and care. Love guides my actions.',
    '066': 'I forgive those who have hurt me. I release all resentment. I free myself from the burden of anger. Forgiveness heals my soul.',
    '067': 'I love without conditions. Without expectations. Without limits. My love is pure, generous, and free. I am love.',
    '068': 'Angels surround me, protect me, guide me. I am safe in their care. No harm can come to me. I am divinely protected.',
    '069': 'My faith is my shield. My trust is my armor. Nothing can penetrate this divine protection. I am safe. I am secure.',
    '070': 'A circle of protective light surrounds me. Only good can enter. All harm is repelled. I am safe within this sacred space.',
    '071': 'I put on the full armor of God. Truth, righteousness, peace, faith, salvation, and spirit. I am fully protected.',
    '072': 'My faith grows stronger each day. I trust more deeply. I believe more fully. My faith moves mountains.',
    '073': 'I trust the divine plan. Even when I cannot see the way. Even in uncertainty. My trust is unshakeable.',
    '074': 'I take a leap of faith. I step into the unknown with confidence. I trust the universe to catch me. Faith guides my jump.',
    '075': 'I believe in miracles. I believe in divine intervention. I believe in the impossible. My belief creates reality.',
    '076': 'Hope springs eternal in my heart. No matter how dark the night, dawn always comes. My hope is renewed.',
    '077': 'Like spring after winter, I am renewed. Like dawn after night, I am refreshed. Hope resurrects within me.',
    '078': 'Tomorrow holds promise. New opportunities await. Better days are coming. I face the future with hope.',
    '079': 'I live in abundance. The universe is generous. There is more than enough for everyone. I receive prosperity with gratitude.',
    '080': 'Prosperity flows to me easily and naturally. I am a magnet for abundance. Wealth comes from expected and unexpected sources.',
    '081': 'Blessings flow to me like a river. Continuously. Abundantly. Generously. I am blessed beyond measure.',
    '082': 'I trust divine provision. My needs are always met. I have everything I require. I lack nothing.',
    '083': 'I am grateful for abundance in all forms. Material, spiritual, emotional, relational. My life overflows with blessings.',
    '084': 'Bless my family with love, health, and harmony. Keep us connected in spirit. May we support and cherish one another.',
    '085': 'Strengthen the bonds of love in my marriage. Deepen our connection. Help us grow together in understanding and compassion.',
    '086': 'Protect and guide our children. Keep them safe. Help them grow in wisdom and grace. May they fulfill their divine purpose.',
    '087': 'I honor my parents and all who came before me. I am grateful for the gift of life they gave me. May they be blessed.',
    '088': 'Bless my friendships with loyalty and joy. Help me be a good friend. Surround me with people who uplift and support me.',
    '089': 'My heart overflows with joy. I find delight in simple pleasures. Happiness is my natural state. I choose joy.',
    '090': 'I celebrate life! I give thanks for every moment of happiness. Every victory. Every blessing. Life is good!',
    '091': 'Happiness is my birthright. I claim it now. I embrace it fully. I deserve to be happy. I am happy.',
    '092': 'Laughter is medicine for my soul. I find humor in life. I don\'t take myself too seriously. Joy bubbles up from within me.',
    '093': 'I delight in being alive. Every breath is precious. Every moment is a gift. I savor life\'s sweetness.',
    '094': 'I cultivate patience. I do not rush. I trust divine timing. All things unfold in their perfect season.',
    '095': 'I endure with grace. I persist with determination. I never give up. Perseverance is my strength.',
    '096': 'My spirit is steadfast. Unchanging in the face of adversity. Constant in difficulty. I remain firm in my faith.',
    '097': 'I wait with grace. I trust the process. Good things come to those who wait. My patience will be rewarded.',
    '098': 'I persist when others quit. I continue when others stop. My persistence is my power. I keep going.',
    '099': 'Keep my heart humble. Let me not boast or compare. I serve without seeking recognition. Humility is my strength.',
    '100': 'I lead by serving. I lift others up. My authority comes from my willingness to help. I am a servant leader.',

    // ═══════════════════════════════════════════════════════════════════════
    // EVENING PRAYERS (101-150) - 6pm to 5am
    // ═══════════════════════════════════════════════════════════════════════
    '101': 'As this day comes to a close, I give thanks for all experiences, both joyful and challenging. They have shaped me and brought me wisdom. I rest in gratitude for another day of life.',
    '102': 'May peace flow through me like a gentle river. May calm settle over my mind like morning dew. I release all anxiety and embrace tranquility. Peace be with me.',
    '103': 'I breathe in peace, I breathe out tension. I breathe in calm, I breathe out worry. My spirit is still. My heart is quiet. I rest in divine peace.',
    '104': 'Let my heart be a sanctuary of peace. In the midst of life\'s storms, I find my center. I am anchored in calm. I am rooted in stillness. Peace dwells within me.',
    '105': 'Like still waters, my soul finds rest. The turbulence of the world cannot disturb my inner calm. I am at peace. I am serene. I am whole.',
    '106': 'My mind is clear. My thoughts are gentle. I release all mental chatter and embrace silence. In the quiet, I find my truth. In stillness, I find peace.',
    '107': 'I release all fear. I let go of anxiety. I surrender worry to the universe. Only courage remains. Only strength endures. I am free.',
    '108': 'My emotional wounds are healing. Past hurts are releasing. I forgive. I let go. I am emotionally whole and free.',
    '109': 'In my pain, I find comfort. In my suffering, I find meaning. This too shall pass. Healing is coming. I am supported and loved.',
    '110': 'I surrender control. I release my need to manage everything. I trust in a power greater than myself. I let go and let God.',
    '111': 'I reflect on this day with gratitude. Lessons learned. Growth experienced. Memories made. This day was a gift.',
    '112': 'As I lay down to sleep, peace surrounds me. I release the day. I rest in divine care. I sleep in perfect peace.',
    '113': 'I surrender this day to you. My plans. My worries. My desires. Not my will but yours be done.',
    '114': 'As evening comes, I enter Your rest. The day\'s work is done, and I release it all into Your hands.',
    '115': 'Nightfall brings peace. My mind quiets, my body relaxes, and my spirit finds refuge in You.',
    '116': 'In the twilight hour, I surrender all worries. Tomorrow\'s concerns can wait. Tonight, I rest.',
    '117': 'I review this day with gratitude. For victories and lessons, for joys and growth, I give thanks.',
    '118': 'At dusk, I release the day\'s burdens. I forgive myself for shortcomings and celebrate all progress made.',
    '119': 'Heal me as I sleep tonight. Restore my body, refresh my mind, renew my spirit for tomorrow.',
    '120': 'Evening gratitude fills my heart. For this day completed, for rest earned, for tomorrow\'s promise.',
    '121': 'Protect me through the night. Guard my sleep, shield my dreams, and keep me in Your care.',
    '122': 'As the sun sets, I reflect on Your faithfulness. You walked with me all day long. Thank You.',
    '123': 'In night\'s stillness, I find You. The noise fades, and Your gentle voice speaks peace to my soul.',
    '124': 'I forgive all who hurt me today. I release resentment and choose peace before I sleep.',
    '125': 'As night falls, I trust You. You watch over me while I rest. I am safe in Your hands.',
    '126': 'Twilight brings thanksgiving. I count today\'s blessings and rest content in Your provision.',
    '127': 'Calm washes over me at bedtime. Anxiety departs, peace arrives, and rest awaits.',
    '128': 'I close this day with joy. What was good, I celebrate. What was hard, I release. Tomorrow is new.',
    '129': 'Renew me through the night. As my body rests, let my spirit be strengthened and restored.',
    '130': 'Contentment settles at dusk. I have enough, I am enough, and You are more than enough.',
    '131': 'This evening, I enter Your sanctuary. My home becomes holy ground where I rest in Your presence.',
    '132': 'Serenity fills the night. All is calm, all is well, and I drift into peaceful sleep.',
    '133': 'Bless my night as the sun sets. May dreams be sweet, sleep be deep, and morning bring renewal.',
    '134': 'My soul quiets this evening. The day\'s noise fades away, and gentle silence surrounds me.',
    '135': 'I let go of today. Regrets, worries, frustrations—all released. Peace is my evening companion.',
    '136': 'Your reassurance comes with nightfall. You are with me even in darkness. I will not fear.',
    '137': 'Comfort envelops me at twilight. Your love surrounds me like a blanket. I rest secure.',
    '138': 'This day is complete. I did what I could, You did what I couldn\'t. It is finished. I rest.',
    '139': 'You are my shelter through the night. Under Your wings, I find refuge and sweet, peaceful sleep.',
    '140': 'At dusk, I meditate on Your goodness. My final thoughts before sleep are of Your faithfulness.',
    '141': 'I trust You with my sleep tonight. You neither slumber nor sleep. I can rest because You watch.',
    '142': 'My bedtime worship rises to You. For this day lived, for this rest earned, I honor You.',
    '143': 'I prepare for restful sleep. My body relaxes, my mind releases, my spirit rests in You.',
    '144': 'Thankfulness floods my heart at sunset. Another day of life, another night of rest. I am blessed.',
    '145': 'Restore me through this evening. Let sleep bring healing, dreams bring hope, morning bring joy.',
    '146': 'In night\'s communion with You, I find perfect peace. We talk, I listen, and my soul is satisfied.',
    '147': 'I release today\'s tension at twilight. Tomorrow will have grace of its own. Tonight, I simply rest.',
    '148': 'Your assurance comforts me at bedtime. I am loved, I am safe, I am Yours. I sleep in peace.',
    '149': 'Speak Your benediction over my night. Bless my rest, guard my sleep, and wake me refreshed.',
    '150': 'Grace covers my night. For mistakes made, grace forgives. For tomorrow\'s needs, grace will provide. I rest in grace.',

    // ═══════════════════════════════════════════════════════════════════════
    // GOLIATH PRAYERS (G001-G050) - Spiritual Warfare - Any Time
    // ═══════════════════════════════════════════════════════════════════════
    'G001': 'I break every chain that binds me. Every stronghold is demolished. Every yoke is destroyed. By the power of Christ, I am free. No weapon formed against me shall prosper. I walk in total freedom.',
    'G002': 'I pull down every stronghold of the enemy. Every fortress of darkness crumbles before me. The walls of oppression fall. I take authority over every demonic structure. They are destroyed by the blood of Jesus.',
    'G003': 'I release myself from every bondage. Every shackle falls off. Every prison door opens. I step out of captivity into glorious freedom. The Son has set me free, and I am free indeed.',
    'G004': 'I sever every ungodly soul tie. Every unholy connection is cut. Every demonic attachment is broken. I am loosed from the grip of the enemy. My soul is free and belongs to Christ alone.',
    'G005': 'I cancel every assignment of the enemy against my life. Every plot is exposed. Every scheme is destroyed. Every plan of darkness fails. The enemy\'s strategies are nullified by the blood of Jesus.',
    'G006': 'I demolish every barrier the enemy has erected. Every obstacle is removed. Every blockage is cleared. The path before me opens wide. Nothing stops my advancement in Christ.',
    'G007': 'I shatter every limitation placed upon my life. Every ceiling breaks. Every boundary expands. I am not confined by the enemy\'s restrictions. I move in the unlimited power of God.',
    'G008': 'I break every generational curse over my bloodline. The sins of my fathers do not define me. Every inherited bondage ends now. My family line is redeemed. We are blessed and not cursed.',
    'G009': 'I loose the power of heaven into my situation. Angels are dispatched on my behalf. Divine intervention manifests now. The hosts of heaven fight for me. Victory is mine.',
    'G010': 'I bind every demonic spirit operating against me. You are bound in the name of Jesus. You cannot operate. You cannot function. You are rendered powerless. Be gone from my presence.',
    'G011': 'I declare my authority in Christ Jesus. I am seated in heavenly places. I am above and not beneath. I am the head and not the tail. Demons tremble at the name I carry.',
    'G012': 'I exercise dominion over every work of darkness. I have been given authority to tread on serpents and scorpions. Nothing shall by any means hurt me. I walk in divine power.',
    'G013': 'I command every enemy spirit to flee. You must obey the name of Jesus. You have no authority over me. You have no power against me. Leave now and never return.',
    'G014': 'I take back every ground the enemy has stolen. Every territory is reclaimed. Every possession is restored. What was taken is returned sevenfold. I recover all.',
    'G015': 'I stand unmovable against every attack. I am rooted and grounded in Christ. No storm shakes me. No assault moves me. I am steadfast, immovable, always abounding.',
    'G016': 'I resist the devil and he flees from me. I give no place to the enemy. Every foothold is removed. Every entrance is sealed. Satan has nothing in me.',
    'G017': 'I enforce the victory of Calvary. Jesus already won the battle. The enemy is already defeated. I stand on finished work. I enforce what Christ accomplished.',
    'G018': 'I declare triumph over every adversary. I am more than a conqueror. I do not merely survive, I overwhelmingly triumph. Victory is my portion. Success is my inheritance.',
    'G019': 'I claim my full inheritance in Christ. Every promise is mine. Every blessing belongs to me. I receive all that the Father has prepared. Nothing is withheld from me.',
    'G020': 'I walk in resurrection power. The same Spirit that raised Christ from the dead lives in me. Death has no hold. The grave has no victory. I live in supernatural power.',
    'G021': 'I plead the blood of Jesus over my life. Every door is marked. Every entrance is sealed. Death passes over me. Destruction cannot touch me. I am covered by precious blood.',
    'G022': 'I activate angelic protection around me. Angels encamp around those who fear the Lord. They bear me up. They guard my way. They fight my battles. I am divinely protected.',
    'G023': 'I raise my shield of faith. Every fiery dart is quenched. Every attack is deflected. Every assault is blocked. My faith is an impenetrable barrier. Nothing gets through.',
    'G024': 'I put on the full armor of God. My loins are girded with truth. My chest is covered with righteousness. My feet are shod with the gospel. I am fully armed and battle ready.',
    'G025': 'The Lord is my fortress. I run into His name and I am safe. No enemy can breach these walls. No attack can penetrate this stronghold. I dwell in divine safety.',
    'G026': 'A hedge of protection surrounds me. The enemy cannot penetrate. Every curse bounces back. Every attack returns to sender. I am untouchable within God\'s hedge.',
    'G027': 'A wall of fire surrounds me. Anyone who touches me touches the apple of God\'s eye. The fire of God consumes every threat. I am protected by holy flames.',
    'G028': 'I am hidden in Christ. The enemy cannot find me. I am concealed in the secret place. Darkness cannot locate me. I am invisible to demonic radar.',
    'G029': 'I guard every gate of my life. My eyes, my ears, my mouth, my heart. Nothing unclean enters. Nothing defiled passes through. Every entrance is sanctified.',
    'G030': 'I secure my household against every attack. My home is dedicated to God. No evil dwells here. No darkness operates here. This is holy ground.',
    'G031': 'The weapons of my warfare are mighty through God. I pull down strongholds. I cast down arguments. I bring every thought captive. I wage war and I win.',
    'G032': 'I wield the sword of the Spirit. The Word of God is sharp and powerful. It divides and penetrates. It exposes and destroys. I strike the enemy with scripture.',
    'G033': 'I call down fire from heaven. Let the fire of God fall. Let it consume every offering of the enemy. Let it burn up every work of darkness. Holy fire, fall now.',
    'G034': 'The Lord thunders against my enemies. His voice breaks the cedars. His power scatters the adversaries. Heaven itself fights on my behalf. The battle is the Lord\'s.',
    'G035': 'I pursue my enemies and overtake them. I do not retreat. I do not surrender. I press forward until they are consumed. I recover everything stolen from me.',
    'G036': 'I trample serpents and scorpions underfoot. Every venomous attack is crushed. Every deadly scheme is stomped out. I walk over the enemy in triumph.',
    'G037': 'I dismantle every operation of darkness. Every network is exposed. Every conspiracy is uncovered. Every hidden work is brought to light. Darkness cannot hide from me.',
    'G038': 'Let God arise and His enemies be scattered. Those who hate Him flee before Him. As smoke is driven away, so are they driven. The wicked perish before God\'s presence.',
    'G039': 'I send confusion into the enemy\'s camp. Let them turn against each other. Let their plans backfire. Let their strategies fail. Every scheme collapses in chaos.',
    'G040': 'I release divine judgment against every persistent enemy. Every unrepentant adversary faces justice. The hand of God moves against those who oppose His children.',
    'G041': 'The battle is already won. Jesus conquered at the cross. I fight from victory, not for victory. The outcome is certain. My triumph is guaranteed.',
    'G042': 'Defeat is not my portion. I do not know failure. I am not acquainted with loss. Everything I touch prospers. Every battle I fight, I win.',
    'G043': 'I rise as a champion of God. Fear has no place in me. Doubt cannot survive in me. I am bold as a lion. I advance without hesitation.',
    'G044': 'I am a giant slayer. No Goliath intimidates me. No obstacle is too big. No enemy is too strong. I bring down giants with the power of God.',
    'G045': 'The overcomer\'s anointing is upon me. I overcome by the blood of the Lamb. I overcome by the word of my testimony. I do not love my life unto death.',
    'G046': 'I am an unstoppable force for God\'s kingdom. Nothing halts my progress. No barrier blocks my path. I move forward relentlessly. I am unstoppable.',
    'G047': 'I am a fearless warrior in God\'s army. I do not cower. I do not retreat. I face every enemy head-on. Fear is beneath me. Courage defines me.',
    'G048': 'I declare complete victory over every battle. Total triumph in every area. Absolute conquest in every situation. Nothing is left undefeated. Victory is total.',
    'G049': 'Every enemy is under my feet. They are my footstool. They serve my advancement. What was meant to destroy me now promotes me. I stand on conquered foes.',
    'G050': 'This is my battle cry: Greater is He that is in me than he that is in the world. I am victorious. I am triumphant. I am more than a conqueror through Christ who strengthens me.',
  };
}
