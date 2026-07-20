// Offline rival personas for Discover leaderboard / Auction Pit / profiles.
// Portraits are original parody anime collectors — not trademarked IP.

enum RivalStatus {
  idle,
  listing,
  highBid,
  sweating,
  tappedOut,
}

extension RivalStatusX on RivalStatus {
  String get label => switch (this) {
        RivalStatus.idle => 'browsing',
        RivalStatus.listing => 'listing',
        RivalStatus.highBid => 'high bid',
        RivalStatus.sweating => 'sweating',
        RivalStatus.tappedOut => 'tapped-out',
      };
}

class RivalPersona {
  const RivalPersona({
    required this.id,
    required this.handle,
    required this.title,
    required this.personality,
    required this.quirk,
    required this.fairBias,
    required this.seed,
    required this.avatarAsset,
  });

  final String id;
  final String handle;
  final String title;
  final List<String> personality;
  final String quirk;
  /// Offer bias: <1 cheapskate, >1 generous.
  final double fairBias;
  final int seed;
  final String avatarAsset;
}

/// Full roster (16). Board size unlocks with businessLevel.
const rivalPersonas = <RivalPersona>[
  RivalPersona(
    id: 'ember',
    handle: 'EmberEyes',
    title: 'Pit Regular',
    personality: ['aggressive', 'foil-hunter'],
    quirk: 'Never lets a chase go quiet.',
    fairBias: 1.08,
    seed: 1101,
    avatarAsset: 'assets/avatars/ember.png',
  ),
  RivalPersona(
    id: 'norbert',
    handle: 'NoLowballsNorbert',
    title: 'Stubborn Dealer',
    personality: ['stubborn', 'comps-obsessed'],
    quirk: 'Walks if you nick him under fair.',
    fairBias: 0.82,
    seed: 1102,
    avatarAsset: 'assets/avatars/norbert.png',
  ),
  RivalPersona(
    id: 'cackle',
    handle: 'CackleCorp',
    title: 'Bulk Baron',
    personality: ['bulk', 'volume'],
    quirk: 'Buys commons by the binder page.',
    fairBias: 0.90,
    seed: 1103,
    avatarAsset: 'assets/avatars/cackle.png',
  ),
  RivalPersona(
    id: 'lena',
    handle: 'LenaHolo',
    title: 'Foil Romantic',
    personality: ['generous', 'foil'],
    quirk: 'Pays up for foils she loves.',
    fairBias: 1.12,
    seed: 1104,
    avatarAsset: 'assets/avatars/lena.png',
  ),
  RivalPersona(
    id: 'marcus',
    handle: 'MarcusMint',
    title: 'Lowball King',
    personality: ['cheap', 'patient'],
    quirk: 'Always opens 15% under fair.',
    fairBias: 0.85,
    seed: 1105,
    avatarAsset: 'assets/avatars/marcus.png',
  ),
  RivalPersona(
    id: 'priya',
    handle: 'PriyaSets',
    title: 'Set Closer',
    personality: ['completer', 'focused'],
    quirk: 'Overpays when she is 1-away.',
    fairBias: 1.15,
    seed: 1106,
    avatarAsset: 'assets/avatars/priya.png',
  ),
  RivalPersona(
    id: 'jax',
    handle: 'JaxSnipes',
    title: 'Auction Sniper',
    personality: ['sniper', 'quiet'],
    quirk: 'Bids in the last seconds.',
    fairBias: 0.97,
    seed: 1107,
    avatarAsset: 'assets/avatars/jax.png',
  ),
  RivalPersona(
    id: 'otto',
    handle: 'OttoBulk',
    title: 'Raw Specialist',
    personality: ['raw-only', 'practical'],
    quirk: 'Hates slabs. Loves NM raw.',
    fairBias: 0.92,
    seed: 1108,
    avatarAsset: 'assets/avatars/otto.png',
  ),
  RivalPersona(
    id: 'mira',
    handle: 'MiraVault',
    title: 'Grail Curator',
    personality: ['collector', 'patient'],
    quirk: 'Only moves on true grails.',
    fairBias: 1.05,
    seed: 1109,
    avatarAsset: 'assets/avatars/mira.png',
  ),
  RivalPersona(
    id: 'dex',
    handle: 'DexDrift',
    title: 'Flip Artist',
    personality: ['flipper', 'fast'],
    quirk: 'In and out before the hype cools.',
    fairBias: 0.94,
    seed: 1110,
    avatarAsset: 'assets/avatars/dex.png',
  ),
  RivalPersona(
    id: 'sora',
    handle: 'SoraSleeve',
    title: 'Condition Hawk',
    personality: ['condition', 'strict'],
    quirk: 'Whitening kills the deal.',
    fairBias: 0.88,
    seed: 1111,
    avatarAsset: 'assets/avatars/sora.png',
  ),
  RivalPersona(
    id: 'kai',
    handle: 'KaiCaseCrack',
    title: 'Sealed Whale',
    personality: ['sealed', 'whale'],
    quirk: 'Pays for boxes, skips singles.',
    fairBias: 1.02,
    seed: 1112,
    avatarAsset: 'assets/avatars/kai.png',
  ),
  RivalPersona(
    id: 'nova',
    handle: 'NovaNeon',
    title: 'Hype Chaser',
    personality: ['hype', 'impulsive'],
    quirk: 'Buys whatever just spiked.',
    fairBias: 1.10,
    seed: 1113,
    avatarAsset: 'assets/avatars/nova.png',
  ),
  RivalPersona(
    id: 'reed',
    handle: 'ReedReserved',
    title: 'Quiet Whale',
    personality: ['quiet', 'deep-pockets'],
    quirk: 'Silent until the number hurts.',
    fairBias: 1.00,
    seed: 1114,
    avatarAsset: 'assets/avatars/reed.png',
  ),
  RivalPersona(
    id: 'yuki',
    handle: 'YukiBinder',
    title: 'Page Filler',
    personality: ['binder', 'friendly'],
    quirk: 'Trades fillers for progress.',
    fairBias: 1.06,
    seed: 1115,
    avatarAsset: 'assets/avatars/yuki.png',
  ),
  RivalPersona(
    id: 'vox',
    handle: 'VoxVaultFlip',
    title: 'Regional Buyer',
    personality: ['dealer', 'networked'],
    quirk: 'Always knows a buyer upstairs.',
    fairBias: 0.96,
    seed: 1116,
    avatarAsset: 'assets/avatars/vox.png',
  ),
];

RivalPersona? rivalById(String id) {
  for (final r in rivalPersonas) {
    if (r.id == id) return r;
  }
  return null;
}

RivalPersona? rivalByHandle(String handle) {
  for (final r in rivalPersonas) {
    if (r.handle == handle || r.id == handle) return r;
  }
  return null;
}

RivalPersona rivalByIndex(int i) =>
    rivalPersonas[i.abs() % rivalPersonas.length];

/// How many rivals appear on the weekly board.
int rivalBoardSizeForLevel(int businessLevel) {
  if (businessLevel >= 11) return 16;
  if (businessLevel >= 6) return 14;
  if (businessLevel >= 3) return 10;
  return 6;
}
