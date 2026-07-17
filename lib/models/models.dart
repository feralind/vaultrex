import 'enums.dart';

class CardDef {
  const CardDef({
    required this.id,
    required this.productId,
    required this.setCode,
    required this.setName,
    required this.name,
    required this.rarity,
    required this.marketPrice,
    required this.imageUrl,
    required this.imageUrlSmall,
    required this.imageKey,
    this.number,
    this.cardType,
    this.domain,
    this.foilMarketPrice,
  });

  final String id;
  final int productId;
  final String setCode;
  final String setName;
  final String name;
  final String? number;
  final Rarity rarity;
  final String? cardType;
  final String? domain;
  final double marketPrice;
  final double? foilMarketPrice;
  final String imageUrl;
  final String imageUrlSmall;
  final String imageKey;

  /// Full-res art for grids, slabs, and detail. Prefer [imageUrl] (HD CDN).
  String get displayArtUrl =>
      imageUrl.isNotEmpty ? imageUrl : imageUrlSmall;

  /// Tiny thumbs only (list rows ~64px). Prefer small when present.
  String get thumbArtUrl =>
      imageUrlSmall.isNotEmpty ? imageUrlSmall : imageUrl;

  /// Riftbound Battlefields are printed landscape; TCGPlayer art is face-on
  /// (horizontal long edge) — use landscape frame + [BoxFit.contain], do not
  /// force a 90° rotate unless an asset is known to be sideways.
  bool get isLandscapeCard {
    final t = (cardType ?? '').toLowerCase();
    return t.contains('battlefield');
  }

  /// Face-on layout aspect (width / height): portrait 2.5:3.5, landscape 3.5:2.5.
  double get artAspectRatio =>
      isLandscapeCard ? 3.5 / 2.5 : 2.5 / 3.5;

  /// Pokémon catalog ids are prefixed `pkm_`; everything else is Riftbound.
  bool get isPokemonCard =>
      id.startsWith('pkm_') || id.startsWith('pokemon_');

  String get franchiseId => isPokemonCard ? 'pokemon' : 'riftbound';

  /// Uppercase chip label for detail / collection tags.
  String get franchiseTag => isPokemonCard ? 'POKÉMON' : 'RIFTBOUND';

  String get franchiseDisplayName =>
      isPokemonCard ? 'Pokémon' : 'Riftbound';

  /// Approximate print year for slab / detail chrome.
  String get setYear => switch (setCode) {
        'OGS' || 'OGN' || 'SFD' || 'UNL' => '2025',
        'MEW' || 'OBF' || 'PAL' => '2023',
        'TWM' || 'SSP' || 'PRE' => '2024',
        _ => isPokemonCard ? '2024' : '2025',
      };

  /// PSA slab set line, e.g. "2023 SV: SCARLET & VIOLET 151".
  String get slabSetLabel => '$setYear $setName'.toUpperCase();

  /// No real secondary-market spot (TCGCSV/TCGplayer) — rip-only / speculative.
  bool get isUnlisted => marketPrice <= 0;

  CardDef copyWith({
    String? id,
    int? productId,
    String? setCode,
    String? setName,
    String? name,
    Rarity? rarity,
    double? marketPrice,
    String? imageUrl,
    String? imageUrlSmall,
    String? imageKey,
    String? number,
    String? cardType,
    String? domain,
    double? foilMarketPrice,
    bool clearFoilMarketPrice = false,
  }) {
    return CardDef(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      setCode: setCode ?? this.setCode,
      setName: setName ?? this.setName,
      name: name ?? this.name,
      rarity: rarity ?? this.rarity,
      marketPrice: marketPrice ?? this.marketPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrlSmall: imageUrlSmall ?? this.imageUrlSmall,
      imageKey: imageKey ?? this.imageKey,
      number: number ?? this.number,
      cardType: cardType ?? this.cardType,
      domain: domain ?? this.domain,
      foilMarketPrice: clearFoilMarketPrice
          ? null
          : (foilMarketPrice ?? this.foilMarketPrice),
    );
  }

  factory CardDef.fromJson(Map<String, dynamic> m) {
    return CardDef(
      id: m['id'] as String,
      productId: m['productId'] as int,
      setCode: m['setCode'] as String,
      setName: m['setName'] as String,
      name: m['name'] as String,
      number: m['number'] as String?,
      rarity: _rarity(m['rarity'] as String?),
      cardType: m['cardType'] as String?,
      domain: m['domain'] as String?,
      marketPrice: (m['marketPrice'] as num?)?.toDouble() ?? 0,
      foilMarketPrice: (m['foilMarketPrice'] as num?)?.toDouble(),
      imageUrl: m['imageUrl'] as String? ?? '',
      imageUrlSmall: m['imageUrlSmall'] as String? ?? '',
      imageKey: m['imageKey'] as String? ?? m['id'] as String,
    );
  }

  static Rarity _rarity(String? raw) {
    if (raw == null) return Rarity.none;
    switch (raw.toLowerCase()) {
      case 'common':
        return Rarity.common;
      case 'uncommon':
        return Rarity.uncommon;
      case 'rare':
        return Rarity.rare;
      case 'epic':
        return Rarity.epic;
      case 'showcase':
        return Rarity.showcase;
      case 'overnumbered':
        return Rarity.overnumbered;
      case 'signature':
        return Rarity.signature;
      case 'ultimate':
        return Rarity.ultimate;
      case 'promo':
        return Rarity.promo;
      case 'token':
        return Rarity.token;
      default:
        return Rarity.none;
    }
  }
}

class SealedProduct {
  const SealedProduct({
    required this.id,
    required this.productId,
    required this.setCode,
    required this.setName,
    required this.name,
    required this.kind,
    required this.marketPrice,
    required this.imageUrl,
    required this.imageUrlSmall,
    this.packsPerBox,
  });

  final String id;
  final int productId;
  final String setCode;
  final String setName;
  final String name;
  final SealedKind kind;
  final double marketPrice;
  final String imageUrl;
  final String imageUrlSmall;
  final int? packsPerBox;

  /// Bundled transparent cutouts (prefer over JPG / CDN).
  static const Set<int> _localPngIds = {
    493975,
    493976,
    496927,
    501256,
    501257,
    504467,
    534087,
    543843,
    543846,
    544170,
    565602,
    565603,
    565604,
    565606,
    593294,
    635366,
    635368,
    635369,
    635371,
    635372,
    635373,
    635374,
    635375,
    635458,
    635459,
    635460,
    649413,
    649421,
    661934,
    661937,
    661939,
    661942,
    661948,
    661949,
    661954,
    678149,
    678150,
    678152,
    678153,
    678154,
    678155,
    678157,
    678162,
    678766,
    690173,
    690174,
    690175,
    696523,
  };

  /// Legacy JPG product shots (prefer PNG cutouts when both exist).
  static const Set<int> _localJpgIds = <int>{};

  /// Prefer local HD / transparent cutouts over CDN JPGs.
  String get displayArtUrl {
    if (_localPngIds.contains(productId)) {
      return 'assets/sealed/tcg_$productId.png';
    }
    if (_localJpgIds.contains(productId)) {
      return 'assets/sealed/tcg_$productId.jpg';
    }
    return imageUrl.isNotEmpty ? imageUrl : imageUrlSmall;
  }

  factory SealedProduct.fromJson(Map<String, dynamic> m) {
    return SealedProduct(
      id: m['id'] as String,
      productId: m['productId'] as int,
      setCode: m['setCode'] as String,
      setName: m['setName'] as String,
      name: m['name'] as String,
      kind: SealedKind.values.firstWhere(
        (k) => k.name == (m['kind'] as String? ?? 'other'),
        orElse: () => SealedKind.other,
      ),
      marketPrice: (m['marketPrice'] as num?)?.toDouble() ?? 0,
      imageUrl: m['imageUrl'] as String? ?? '',
      imageUrlSmall: m['imageUrlSmall'] as String? ?? '',
      packsPerBox: m['packsPerBox'] as int?,
    );
  }
}

class OwnedCard {
  OwnedCard({
    required this.instanceId,
    required this.cardId,
    required this.foil,
    required this.condition,
    required this.centeringLR,
    required this.centeringTB,
    required this.surface,
    required this.edges,
    required this.corners,
    required this.defects,
    this.graded = false,
    this.grade,
    this.gradingCompany,
    this.inShowcase = false,
    this.listedAsk,
  });

  final String instanceId;
  final String cardId;
  bool foil;
  Condition condition;
  double centeringLR; // 0..100 left bias; 50 perfect
  double centeringTB;
  double surface; // 1..10
  double edges;
  double corners;
  List<FactoryDefect> defects;
  bool graded;
  double? grade;
  GradingCompany? gradingCompany;
  bool inShowcase;
  double? listedAsk;

  double get centeringScore {
    final lr = 100 - (centeringLR - 50).abs() * 2;
    final tb = 100 - (centeringTB - 50).abs() * 2;
    return ((lr + tb) / 2).clamp(0, 100);
  }

  OwnedCard copyWith({
    bool? foil,
    Condition? condition,
    double? centeringLR,
    double? centeringTB,
    double? surface,
    double? edges,
    double? corners,
    List<FactoryDefect>? defects,
    bool? graded,
    double? grade,
    GradingCompany? gradingCompany,
    bool? inShowcase,
    double? listedAsk,
    bool clearListedAsk = false,
    bool clearGrade = false,
  }) {
    return OwnedCard(
      instanceId: instanceId,
      cardId: cardId,
      foil: foil ?? this.foil,
      condition: condition ?? this.condition,
      centeringLR: centeringLR ?? this.centeringLR,
      centeringTB: centeringTB ?? this.centeringTB,
      surface: surface ?? this.surface,
      edges: edges ?? this.edges,
      corners: corners ?? this.corners,
      defects: defects ?? List.of(this.defects),
      graded: graded ?? this.graded,
      grade: clearGrade ? null : (grade ?? this.grade),
      gradingCompany:
          clearGrade ? null : (gradingCompany ?? this.gradingCompany),
      inShowcase: inShowcase ?? this.inShowcase,
      listedAsk: clearListedAsk ? null : (listedAsk ?? this.listedAsk),
    );
  }

  Map<String, dynamic> toJson() => {
        'instanceId': instanceId,
        'cardId': cardId,
        'foil': foil,
        'condition': condition.name,
        'centeringLR': centeringLR,
        'centeringTB': centeringTB,
        'surface': surface,
        'edges': edges,
        'corners': corners,
        'defects': defects.map((d) => d.name).toList(),
        'graded': graded,
        'grade': grade,
        'gradingCompany': gradingCompany?.name,
        'inShowcase': inShowcase,
        'listedAsk': listedAsk,
      };

  factory OwnedCard.fromJson(Map<String, dynamic> j) => OwnedCard(
        instanceId: j['instanceId'] as String,
        cardId: j['cardId'] as String,
        foil: j['foil'] as bool? ?? false,
        condition: Condition.values.byName(j['condition'] as String),
        centeringLR: (j['centeringLR'] as num?)?.toDouble() ?? 50,
        centeringTB: (j['centeringTB'] as num?)?.toDouble() ?? 50,
        surface: (j['surface'] as num?)?.toDouble() ?? 9,
        edges: (j['edges'] as num?)?.toDouble() ?? 9,
        corners: (j['corners'] as num?)?.toDouble() ?? 9,
        defects: ((j['defects'] as List?) ?? [])
            .map((e) => FactoryDefect.values.byName(e as String))
            .toList(),
        graded: j['graded'] as bool? ?? false,
        grade: (j['grade'] as num?)?.toDouble(),
        gradingCompany: j['gradingCompany'] == null
            ? null
            : GradingCompanyX.parse(j['gradingCompany'] as String?),
        inShowcase: j['inShowcase'] as bool? ?? false,
        listedAsk: (j['listedAsk'] as num?)?.toDouble(),
      );
}

class UnopenedPack {
  const UnopenedPack({
    required this.id,
    required this.sealedProductId,
    required this.setCode,
  });

  final String id;
  final String sealedProductId;
  final String setCode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sealedProductId': sealedProductId,
        'setCode': setCode,
      };

  factory UnopenedPack.fromJson(Map<String, dynamic> j) => UnopenedPack(
        id: j['id'] as String,
        sealedProductId: j['sealedProductId'] as String,
        setCode: j['setCode'] as String,
      );
}

class SealedListing {
  SealedListing({
    required this.id,
    required this.sealedProductId,
    required this.price,
    required this.stock,
    required this.sellerAlias,
    this.trendTag,
  });

  final String id;
  final String sealedProductId;
  double price;
  int stock;
  final String sellerAlias;
  String? trendTag;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sealedProductId': sealedProductId,
        'price': price,
        'stock': stock,
        'sellerAlias': sellerAlias,
        'trendTag': trendTag,
      };

  factory SealedListing.fromJson(Map<String, dynamic> j) => SealedListing(
        id: j['id'] as String,
        sealedProductId: j['sealedProductId'] as String,
        price: (j['price'] as num).toDouble(),
        stock: j['stock'] as int,
        sellerAlias: j['sellerAlias'] as String,
        trendTag: j['trendTag'] as String?,
      );
}

class MarketListing {
  MarketListing({
    required this.id,
    required this.sellerType,
    required this.title,
    required this.price,
    required this.cardId,
    required this.foil,
    required this.condition,
    required this.centeringLR,
    required this.centeringTB,
    required this.isFake,
    this.graded = false,
    this.grade,
    this.gradingCompany,
    this.sellerAlias,
    this.rating,
    this.salesCount,
    this.shipsInDays,
  });

  final String id;
  final SellerType sellerType;
  final String title;
  final double price;
  final String cardId;
  final bool foil;
  final Condition condition;
  final double centeringLR;
  final double centeringTB;
  final bool isFake;
  final bool graded;
  final double? grade;
  final GradingCompany? gradingCompany;
  final String? sellerAlias;
  final double? rating;
  final int? salesCount;
  final int? shipsInDays;

  double get displayRating => rating ?? sellerType.rating;
  int get displaySales => salesCount ?? sellerType.typicalSales;
  int get displayShipsInDays => shipsInDays ?? sellerType.shipsInDays;

  Map<String, dynamic> toJson() => {
        'id': id,
        'sellerType': sellerType.name,
        'title': title,
        'price': price,
        'cardId': cardId,
        'foil': foil,
        'condition': condition.name,
        'centeringLR': centeringLR,
        'centeringTB': centeringTB,
        'isFake': isFake,
        'graded': graded,
        'grade': grade,
        'gradingCompany': gradingCompany?.name,
        'sellerAlias': sellerAlias,
        'rating': rating,
        'salesCount': salesCount,
        'shipsInDays': shipsInDays,
      };

  factory MarketListing.fromJson(Map<String, dynamic> j) {
    final seller = SellerType.values.byName(j['sellerType'] as String);
    return MarketListing(
      id: j['id'] as String,
      sellerType: seller,
      title: j['title'] as String,
      price: (j['price'] as num).toDouble(),
      cardId: j['cardId'] as String,
      foil: j['foil'] as bool? ?? false,
      condition: Condition.values.byName(j['condition'] as String),
      centeringLR: (j['centeringLR'] as num?)?.toDouble() ?? 50,
      centeringTB: (j['centeringTB'] as num?)?.toDouble() ?? 50,
      isFake: j['isFake'] as bool? ?? false,
      graded: j['graded'] as bool? ?? false,
      grade: (j['grade'] as num?)?.toDouble(),
      gradingCompany: j['gradingCompany'] != null
          ? GradingCompanyX.parse(j['gradingCompany'] as String?)
          : null,
      sellerAlias: j['sellerAlias'] as String?,
      rating: (j['rating'] as num?)?.toDouble() ?? seller.rating,
      salesCount: j['salesCount'] as int? ?? seller.typicalSales,
      shipsInDays: j['shipsInDays'] as int? ?? seller.shipsInDays,
    );
  }
}

class OnlineListing {
  OnlineListing({
    required this.id,
    required this.ownedInstanceId,
    required this.ask,
    required this.listedDay,
    this.status = OnlineListingStatus.active,
  });

  final String id;
  final String ownedInstanceId;
  double ask;
  final int listedDay;
  OnlineListingStatus status;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownedInstanceId': ownedInstanceId,
        'ask': ask,
        'listedDay': listedDay,
        'status': status.name,
      };

  factory OnlineListing.fromJson(Map<String, dynamic> j) => OnlineListing(
        id: j['id'] as String,
        ownedInstanceId: j['ownedInstanceId'] as String,
        ask: (j['ask'] as num).toDouble(),
        listedDay: j['listedDay'] as int,
        status: OnlineListingStatus.values.byName(
          j['status'] as String? ?? 'active',
        ),
      );
}

/// Player offer on an NPC [MarketListing] (cash escrowed until resolved).
class MarketOffer {
  MarketOffer({
    required this.id,
    required this.listingId,
    required this.offerAmount,
    required this.createdDay,
    required this.expiresOnDay,
    this.counterAmount,
    this.status = MarketOfferStatus.pending,
  });

  final String id;
  final String listingId;
  final double offerAmount;
  double? counterAmount;
  MarketOfferStatus status;
  final int createdDay;
  final int expiresOnDay;

  bool get isOpen =>
      status == MarketOfferStatus.pending ||
      status == MarketOfferStatus.countered;

  Map<String, dynamic> toJson() => {
        'id': id,
        'listingId': listingId,
        'offerAmount': offerAmount,
        'counterAmount': counterAmount,
        'status': status.name,
        'createdDay': createdDay,
        'expiresOnDay': expiresOnDay,
      };

  factory MarketOffer.fromJson(Map<String, dynamic> j) => MarketOffer(
        id: j['id'] as String,
        listingId: j['listingId'] as String,
        offerAmount: (j['offerAmount'] as num).toDouble(),
        counterAmount: (j['counterAmount'] as num?)?.toDouble(),
        status: MarketOfferStatus.values.byName(
          j['status'] as String? ?? 'pending',
        ),
        createdDay: j['createdDay'] as int? ?? 1,
        expiresOnDay: j['expiresOnDay'] as int? ?? 3,
      );
}

class GradingJob {
  GradingJob({
    required this.id,
    required this.ownedInstanceId,
    required this.company,
    required this.turnsLeft,
    this.ready = false,
    this.revealed = false,
    this.resultGrade,
    this.readyAtMs,
  });

  final String id;
  final String ownedInstanceId;
  final GradingCompany company;
  int turnsLeft;
  bool ready;
  bool revealed;
  double? resultGrade;
  /// Epoch ms when realtime grading completes (~10s). Null = legacy day jobs.
  int? readyAtMs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownedInstanceId': ownedInstanceId,
        'company': company.name,
        'turnsLeft': turnsLeft,
        'ready': ready,
        'revealed': revealed,
        'resultGrade': resultGrade,
        'readyAtMs': readyAtMs,
      };

  factory GradingJob.fromJson(Map<String, dynamic> j) => GradingJob(
        id: j['id'] as String,
        ownedInstanceId: j['ownedInstanceId'] as String,
        company: GradingCompanyX.parse(j['company'] as String?),
        turnsLeft: j['turnsLeft'] as int? ?? 0,
        ready: j['ready'] as bool? ?? false,
        revealed: j['revealed'] as bool? ?? false,
        resultGrade: (j['resultGrade'] as num?)?.toDouble(),
        readyAtMs: j['readyAtMs'] as int?,
      );
}

class AuctionLot {
  AuctionLot({
    required this.id,
    required this.cardId,
    required this.foil,
    required this.condition,
    required this.centeringLR,
    required this.centeringTB,
    required this.isFake,
    required this.currentBid,
    required this.minIncrement,
    required this.endsInTurns,
    this.playerIsHighBidder = false,
  });

  final String id;
  final String cardId;
  final bool foil;
  final Condition condition;
  final double centeringLR;
  final double centeringTB;
  final bool isFake;
  double currentBid;
  final double minIncrement;
  int endsInTurns;
  bool playerIsHighBidder;

  Map<String, dynamic> toJson() => {
        'id': id,
        'cardId': cardId,
        'foil': foil,
        'condition': condition.name,
        'centeringLR': centeringLR,
        'centeringTB': centeringTB,
        'isFake': isFake,
        'currentBid': currentBid,
        'minIncrement': minIncrement,
        'endsInTurns': endsInTurns,
        'playerIsHighBidder': playerIsHighBidder,
      };

  factory AuctionLot.fromJson(Map<String, dynamic> j) => AuctionLot(
        id: j['id'] as String,
        cardId: j['cardId'] as String,
        foil: j['foil'] as bool? ?? false,
        condition: Condition.values.byName(j['condition'] as String),
        centeringLR: (j['centeringLR'] as num?)?.toDouble() ?? 50,
        centeringTB: (j['centeringTB'] as num?)?.toDouble() ?? 50,
        isFake: j['isFake'] as bool? ?? false,
        currentBid: (j['currentBid'] as num).toDouble(),
        minIncrement: (j['minIncrement'] as num).toDouble(),
        endsInTurns: j['endsInTurns'] as int,
        playerIsHighBidder: j['playerIsHighBidder'] as bool? ?? false,
      );
}

class MarketEvent {
  const MarketEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.setCode,
    required this.multiplier,
    required this.turnsLeft,
  });

  final String id;
  final String title;
  final String description;
  final String setCode;
  final double multiplier;
  final int turnsLeft;

  MarketEvent copyWith({int? turnsLeft}) => MarketEvent(
        id: id,
        title: title,
        description: description,
        setCode: setCode,
        multiplier: multiplier,
        turnsLeft: turnsLeft ?? this.turnsLeft,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'setCode': setCode,
        'multiplier': multiplier,
        'turnsLeft': turnsLeft,
      };

  factory MarketEvent.fromJson(Map<String, dynamic> j) => MarketEvent(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String,
        setCode: (j['setCode'] as String?) ?? (j['setId'] as String? ?? 'OGN'),
        multiplier: (j['multiplier'] as num).toDouble(),
        turnsLeft: j['turnsLeft'] as int,
      );
}

class UpgradeDef {
  const UpgradeDef({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.requiredXp,
  });

  final String id;
  final String name;
  final String description;
  final int cost;
  final int requiredXp;
}

class PlayerStats {
  const PlayerStats({
    this.cash = 350,
    this.candy = 25000,
    this.xp = 0,
    this.businessLevel = 1,
    this.packsOpened = 0,
    this.cardsSold = 0,
    this.gemsPulled = 0,
    this.ownedUpgrades = const {},
    this.unlockedAchievements = const {},
  });

  final double cash;
  final int candy;
  final int xp;
  final int businessLevel;
  final int packsOpened;
  final int cardsSold;
  final int gemsPulled;
  final Set<String> ownedUpgrades;
  final Set<String> unlockedAchievements;

  PlayerStats copyWith({
    double? cash,
    int? candy,
    int? xp,
    int? businessLevel,
    int? packsOpened,
    int? cardsSold,
    int? gemsPulled,
    Set<String>? ownedUpgrades,
    Set<String>? unlockedAchievements,
  }) {
    return PlayerStats(
      cash: cash ?? this.cash,
      candy: candy ?? this.candy,
      xp: xp ?? this.xp,
      businessLevel: businessLevel ?? this.businessLevel,
      packsOpened: packsOpened ?? this.packsOpened,
      cardsSold: cardsSold ?? this.cardsSold,
      gemsPulled: gemsPulled ?? this.gemsPulled,
      ownedUpgrades: ownedUpgrades ?? this.ownedUpgrades,
      unlockedAchievements:
          unlockedAchievements ?? this.unlockedAchievements,
    );
  }

  Map<String, dynamic> toJson() => {
        'cash': cash,
        'candy': candy,
        'xp': xp,
        'businessLevel': businessLevel,
        'packsOpened': packsOpened,
        'cardsSold': cardsSold,
        'gemsPulled': gemsPulled,
        'ownedUpgrades': ownedUpgrades.toList(),
        'unlockedAchievements': unlockedAchievements.toList(),
      };

  factory PlayerStats.fromJson(Map<String, dynamic> j) {
    final cash = (j['cash'] as num?)?.toDouble() ?? 500;
    final candyRaw = j['candy'];
    return PlayerStats(
      cash: cash,
      candy: candyRaw == null ? (cash * 100).round() : (candyRaw as num).toInt(),
      xp: j['xp'] as int? ?? 0,
      businessLevel: j['businessLevel'] as int? ?? 1,
      packsOpened: j['packsOpened'] as int? ?? 0,
      cardsSold: j['cardsSold'] as int? ?? 0,
      gemsPulled: j['gemsPulled'] as int? ?? 0,
      ownedUpgrades: {...(j['ownedUpgrades'] as List? ?? []).cast<String>()},
      unlockedAchievements: {
        ...(j['unlockedAchievements'] as List? ?? []).cast<String>()
      },
    );
  }
}

/// Dated portfolio total for the Insights value chart.
class CollectionValuePoint {
  const CollectionValuePoint({required this.date, required this.value});

  final DateTime date;
  final double value;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'value': value,
      };

  factory CollectionValuePoint.fromJson(Map<String, dynamic> j) {
    return CollectionValuePoint(
      date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
      value: (j['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Named binder (page of owned instance IDs) for the Binders tab.
class Binder {
  const Binder({
    required this.id,
    required this.name,
    this.cardInstanceIds = const [],
    this.colorHex = 0xFF5B8CFF,
    this.isPrivate = false,
  });

  final String id;
  final String name;
  final List<String> cardInstanceIds;
  final int colorHex;
  final bool isPrivate;

  int get cardCount => cardInstanceIds.length;

  Binder copyWith({
    String? name,
    List<String>? cardInstanceIds,
    int? colorHex,
    bool? isPrivate,
  }) {
    return Binder(
      id: id,
      name: name ?? this.name,
      cardInstanceIds: cardInstanceIds ?? this.cardInstanceIds,
      colorHex: colorHex ?? this.colorHex,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cardInstanceIds': cardInstanceIds,
        'colorHex': colorHex,
        'isPrivate': isPrivate,
      };

  factory Binder.fromJson(Map<String, dynamic> j) {
    return Binder(
      id: j['id'] as String? ?? '',
      name: j['name'] as String? ?? 'Binder',
      cardInstanceIds: (j['cardInstanceIds'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      colorHex: (j['colorHex'] as num?)?.toInt() ?? 0xFF5B8CFF,
      isPrivate: j['isPrivate'] as bool? ?? false,
    );
  }
}
