// Static defs for Bindora engagement (achievements, titles, NPCs, goals).

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final String icon; // Material icon name key
}

const achievementDefs = <AchievementDef>[
  AchievementDef(
    id: 'ripper_10',
    title: 'Warm Hands',
    description: 'Open 10 packs.',
    icon: 'inventory_2',
  ),
  AchievementDef(
    id: 'ripper_50',
    title: 'Pack Addict',
    description: 'Open 50 packs.',
    icon: 'local_fire_department',
  ),
  AchievementDef(
    id: 'first_gem',
    title: 'First Gem',
    description: 'Pull your first chase-tier card.',
    icon: 'diamond',
  ),
  AchievementDef(
    id: 'seller_5',
    title: 'First Flips',
    description: 'Sell 5 cards.',
    icon: 'sell',
  ),
  AchievementDef(
    id: 'seller_25',
    title: 'Market Regular',
    description: 'Sell 25 cards.',
    icon: 'storefront',
  ),
  AchievementDef(
    id: 'binder_50',
    title: 'Growing Binder',
    description: 'Own 50 cards in your collection.',
    icon: 'collections_bookmark',
  ),
  AchievementDef(
    id: 'binder_150',
    title: 'Vault Starter',
    description: 'Own 150 cards in your collection.',
    icon: 'warehouse',
  ),
  AchievementDef(
    id: 'grader_1',
    title: 'Slab Curious',
    description: 'Reveal your first graded card.',
    icon: 'verified',
  ),
  AchievementDef(
    id: 'streak_3',
    title: 'Three-Day Habit',
    description: 'Claim daily candy 3 days in a row.',
    icon: 'calendar_month',
  ),
  AchievementDef(
    id: 'set_complete',
    title: 'Set Closer',
    description: 'Complete any set 100%.',
    icon: 'emoji_events',
  ),
];

AchievementDef? achievementById(String id) {
  for (final a in achievementDefs) {
    if (a.id == id) return a;
  }
  return null;
}

class BusinessTitle {
  const BusinessTitle({
    required this.minLevel,
    required this.title,
    required this.blurb,
  });

  final int minLevel;
  final String title;
  final String blurb;
}

const businessTitles = <BusinessTitle>[
  BusinessTitle(minLevel: 1, title: 'Kitchen Table', blurb: 'Start small.'),
  BusinessTitle(minLevel: 3, title: 'Local Dealer', blurb: '+1 binder page.'),
  BusinessTitle(minLevel: 5, title: 'Weekend Vendor', blurb: 'Cheaper listing fees.'),
  BusinessTitle(minLevel: 8, title: 'Regional Buyer', blurb: '+1 auction slot.'),
  BusinessTitle(minLevel: 12, title: 'Shop Owner', blurb: 'Extra grading queue.'),
  BusinessTitle(minLevel: 18, title: 'Grail Hunter', blurb: 'Featured pack perk.'),
  BusinessTitle(minLevel: 25, title: 'Vault Magnate', blurb: 'Max prestige.'),
];

String businessTitleForLevel(int level) {
  var t = businessTitles.first.title;
  for (final b in businessTitles) {
    if (level >= b.minLevel) t = b.title;
  }
  return t;
}

/// XP → business level. Soft curve; caps at 30.
int businessLevelFromXp(int xp) {
  var level = 1;
  var need = 40;
  var rem = xp;
  while (rem >= need && level < 30) {
    rem -= need;
    level++;
    need = 40 + level * 8;
  }
  return level;
}

/// Binder pages unlocked from business level (base 2).
int binderPagesForLevel(int level) => 2 + (level ~/ 3).clamp(0, 10);

class DailyGoalDef {
  const DailyGoalDef({
    required this.id,
    required this.title,
    required this.target,
    required this.candyReward,
    required this.xpReward,
  });

  final String id;
  final String title;
  final int target;
  final int candyReward;
  final int xpReward;
}

const dailyGoalDefs = <DailyGoalDef>[
  DailyGoalDef(
    id: 'rip_2',
    title: 'Rip 2 packs',
    target: 2,
    candyReward: 400,
    xpReward: 8,
  ),
  DailyGoalDef(
    id: 'list_1',
    title: 'List 1 card online',
    target: 1,
    candyReward: 250,
    xpReward: 5,
  ),
  DailyGoalDef(
    id: 'grade_1',
    title: 'Send 1 card to grading',
    target: 1,
    candyReward: 300,
    xpReward: 6,
  ),
];

class NpcBuyer {
  const NpcBuyer({
    required this.id,
    required this.name,
    required this.quirk,
    required this.fairBias,
  });

  final String id;
  final String name;
  final String quirk;
  /// Multiplier on offers they make toward you (buy) or counters (<1 = cheapskate).
  final double fairBias;
}

const npcBuyers = <NpcBuyer>[
  NpcBuyer(
    id: 'marcus',
    name: 'Marcus',
    quirk: 'Always lowballs chase cards.',
    fairBias: 0.85,
  ),
  NpcBuyer(
    id: 'lena',
    name: 'Lena',
    quirk: 'Pays fair for foils she loves.',
    fairBias: 1.05,
  ),
  NpcBuyer(
    id: 'otto',
    name: 'Otto',
    quirk: 'Bulk specialist — hates slabs.',
    fairBias: 0.92,
  ),
  NpcBuyer(
    id: 'priya',
    name: 'Priya',
    quirk: 'Set completer. Overpays when 1-away.',
    fairBias: 1.12,
  ),
  NpcBuyer(
    id: 'jax',
    name: 'Jax',
    quirk: 'Auction sniper energy.',
    fairBias: 0.97,
  ),
];

NpcBuyer npcById(String id) {
  for (final n in npcBuyers) {
    if (n.id == id) return n;
  }
  return npcBuyers.first;
}

NpcBuyer npcForIndex(int i) => npcBuyers[i.abs() % npcBuyers.length];

const rivalBidderNames = [
  'SleeveSniper',
  'HoloHarbor',
  'MintCornerCo',
  'ChaseCatcher',
  'AltArtAnnie',
  'VaultFlipVince',
  'GradedGrailGuy',
];

/// Ghost leaderboard personas (clearly flavor).
const ghostCollectorNames = [
  'BinderBunny',
  'FoilFoxCards',
  'SlabStacker',
  'PullRatePete',
  'CaseCrackChris',
  'NMOnlyNick',
  'BudgetBinder',
  'RuneRunnerCards',
  'SealedVault',
  'MythicMintMike',
];
