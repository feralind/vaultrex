enum Rarity {
  common,
  uncommon,
  rare,
  epic,
  showcase,
  overnumbered,
  signature,
  ultimate,
  promo,
  token,
  none,
}

enum Condition {
  damaged,
  heavilyPlayed,
  moderatelyPlayed,
  lightlyPlayed,
  nearMint,
  mint,
}

enum SellerType { clueless, serious, scammy, goblin, lgs, whale, flipper }

enum SealedKind { pack, box, deck, displayCase, other }

enum GradingCompany { psa }

enum PaymentMethod { cash, candy }

enum FactoryDefect { offCenter, bentCorner, whitening, printLine, miscut }

enum OnlineListingStatus { active, sold, cancelled }

enum MarketOfferStatus {
  pending,
  accepted,
  countered,
  rejected,
  expired,
  cancelled,
}

extension RarityX on Rarity {
  String get label => switch (this) {
        Rarity.common => 'Common',
        Rarity.uncommon => 'Uncommon',
        Rarity.rare => 'Rare',
        Rarity.epic => 'Epic',
        Rarity.showcase => 'Showcase',
        Rarity.overnumbered => 'Overnumbered',
        Rarity.signature => 'Signature',
        Rarity.ultimate => 'Ultimate',
        Rarity.promo => 'Promo',
        Rarity.token => 'Token',
        Rarity.none => 'Unknown',
      };

  bool get isRarePlus =>
      this == Rarity.rare ||
      this == Rarity.epic ||
      this == Rarity.showcase ||
      this == Rarity.overnumbered ||
      this == Rarity.signature ||
      this == Rarity.ultimate;
}

extension ConditionX on Condition {
  String get label => switch (this) {
        Condition.damaged => 'Damaged',
        Condition.heavilyPlayed => 'HP',
        Condition.moderatelyPlayed => 'MP',
        Condition.lightlyPlayed => 'LP',
        Condition.nearMint => 'NM',
        Condition.mint => 'Mint',
      };

  double get valueMult => switch (this) {
        Condition.damaged => 0.25,
        Condition.heavilyPlayed => 0.45,
        Condition.moderatelyPlayed => 0.65,
        Condition.lightlyPlayed => 0.85,
        Condition.nearMint => 1.0,
        Condition.mint => 1.12,
      };
}

extension SellerTypeX on SellerType {
  String get label => switch (this) {
        SellerType.clueless => 'Clueless Seller',
        SellerType.serious => 'Serious Seller',
        SellerType.scammy => 'Suspicious Seller',
        SellerType.goblin => 'Goblin Auction',
        SellerType.lgs => 'Local Game Store',
        SellerType.whale => 'Whale Collector',
        SellerType.flipper => 'Quick Flipper',
      };

  /// Short tip shown on buy / offer sheets.
  String get blurb => switch (this) {
        SellerType.clueless => 'Often takes ~86%+ offers · soft asks',
        SellerType.serious => 'Wants near ask · fair comps · ships fast',
        SellerType.scammy => 'Weak feedback · inspect carefully',
        SellerType.goblin => 'Haggles hard · loves counters',
        SellerType.lgs => 'Fair street · accepts ~92% · reliable',
        SellerType.whale => 'Premium asks · rarely budges below 97%',
        SellerType.flipper => 'Moves stock fast · open to 90% offers',
      };

  /// Default offer as fraction of ask when opening Make Offer.
  double get defaultOfferFraction => switch (this) {
        SellerType.clueless => 0.86,
        SellerType.serious => 0.95,
        SellerType.scammy => 0.88,
        SellerType.goblin => 0.90,
        SellerType.lgs => 0.92,
        SellerType.whale => 0.97,
        SellerType.flipper => 0.90,
      };

  /// Simulated positive feedback % for Feebay-style listings.
  double get rating => switch (this) {
        SellerType.serious => 98.5,
        SellerType.lgs => 97.2,
        SellerType.whale => 96.0,
        SellerType.clueless => 94.0,
        SellerType.flipper => 93.1,
        SellerType.goblin => 91.2,
        SellerType.scammy => 72.4,
      };

  int get typicalSales => switch (this) {
        SellerType.serious => 4200,
        SellerType.lgs => 9800,
        SellerType.flipper => 2100,
        SellerType.whale => 640,
        SellerType.goblin => 860,
        SellerType.clueless => 180,
        SellerType.scammy => 45,
      };

  int get shipsInDays => switch (this) {
        SellerType.serious => 1,
        SellerType.lgs => 1,
        SellerType.flipper => 2,
        SellerType.goblin => 2,
        SellerType.whale => 2,
        SellerType.clueless => 3,
        SellerType.scammy => 5,
      };
}

extension SealedKindX on SealedKind {
  String get label => switch (this) {
        SealedKind.pack => 'Booster Pack',
        SealedKind.box => 'Booster Box',
        SealedKind.deck => 'Champion Deck',
        SealedKind.displayCase => 'Display Case',
        SealedKind.other => 'Sealed',
      };
}

extension GradingCompanyX on GradingCompany {
  String get label => 'PSA';

  String get blurb => 'Prestige slabs. Fast sim turnaround, respected.';

  int get fee => 35;

  /// Legacy day-ticks (Advance Day). Realtime grading uses ~10s wall clock.
  int get turns => 0;

  /// Simulated PSA wait in the app (not multi-day).
  int get realtimeSeconds => 10;

  /// Maps legacy save values (zag / pza / bucket) onto PSA.
  static GradingCompany parse(String? name) {
    if (name == null || name.isEmpty) return GradingCompany.psa;
    return GradingCompany.psa;
  }
}
