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

enum SellerType { clueless, serious, scammy, goblin }

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
      };

  /// Short personality line shown on market comps.
  String get personality => switch (this) {
        SellerType.serious =>
          'Prices near comps · ships fast · rarely counters soft offers.',
        SellerType.clueless =>
          'Undervalues often · slower ship · soft on offers.',
        SellerType.goblin =>
          'Loves to haggle · counters mid offers · mid ship speed.',
        SellerType.scammy =>
          'Low ratings · long ship times · rejects most offers.',
      };

  /// Simulated positive feedback % for Feebay-style listings.
  double get rating => switch (this) {
        SellerType.serious => 98.5,
        SellerType.clueless => 94.0,
        SellerType.goblin => 91.2,
        SellerType.scammy => 72.4,
      };

  int get typicalSales => switch (this) {
        SellerType.serious => 4200,
        SellerType.clueless => 180,
        SellerType.goblin => 860,
        SellerType.scammy => 45,
      };

  int get shipsInDays => switch (this) {
        SellerType.serious => 1,
        SellerType.clueless => 3,
        SellerType.goblin => 2,
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
