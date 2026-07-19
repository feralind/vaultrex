import 'package:flutter_test/flutter_test.dart';
import 'package:bindora/data/pricing.dart';
import 'package:bindora/data/riftbound_catalog.dart';
import 'package:bindora/data/tcgcsv_price_refresh.dart';
import 'package:bindora/models/enums.dart';
import 'package:bindora/models/models.dart';

CardDef _card({
  required String id,
  required String setCode,
  required Rarity rarity,
  required double marketPrice,
  String? number,
  String name = 'Test Card',
}) {
  return CardDef(
    id: id,
    productId: 1,
    setCode: setCode,
    setName: 'Test Set',
    name: name,
    rarity: rarity,
    marketPrice: marketPrice,
    imageUrl: '',
    imageUrlSmall: '',
    imageKey: id,
    number: number,
  );
}

OwnedCard _owned(String cardId) {
  return OwnedCard(
    instanceId: 'i1',
    cardId: cardId,
    foil: false,
    condition: Condition.nearMint,
    centeringLR: 50,
    centeringTB: 50,
    surface: 9,
    edges: 9,
    corners: 9,
    defects: const [],
  );
}

void main() {
  group('TcgcsvPriceRefresh.mergePriceRows', () {
    test('updates normal and foil spots from TCGCSV rows', () {
      final out = <int, SpotPrice>{};
      TcgcsvPriceRefresh.mergePriceRows(out, [
        {
          'productId': 1001,
          'subTypeName': 'Normal',
          'marketPrice': 12.5,
        },
        {
          'productId': 1001,
          'subTypeName': 'Foil',
          'marketPrice': 28.0,
        },
        {
          'productId': 1002,
          'subTypeName': 'Holofoil',
          'marketPrice': 40.0,
        },
        {
          'productId': 1003,
          'subTypeName': 'Normal',
          'marketPrice': 0,
        },
      ]);

      expect(out[1001]?.marketPrice, 12.5);
      expect(out[1001]?.foilMarketPrice, 28.0);
      expect(out[1002]?.marketPrice, 40.0);
      expect(out[1002]?.foilMarketPrice, 40.0);
      expect(out.containsKey(1003), isFalse);
    });
  });

  group('market pool / slab guard', () {
    test('isSlabEligibleCard requires marketPrice > 0', () {
      final unlisted = _card(
        id: 'pkm_x',
        setCode: 'MEW',
        rarity: Rarity.rare,
        marketPrice: 0,
        number: '151',
      );
      expect(unlisted.isUnlisted, isTrue);
      expect(isSlabEligibleCard(unlisted), isFalse);

      final listed = _card(
        id: 'pkm_y',
        setCode: 'MEW',
        rarity: Rarity.rare,
        marketPrice: 40,
        number: '151',
        name: 'Mew',
      );
      expect(isSlabEligibleCard(listed), isTrue);
    });
  });

  group('speculative fairValue', () {
    test('unlisted cards price above rarity floor', () {
      final def = _card(
        id: 'rb_x',
        setCode: 'OGN',
        rarity: Rarity.rare,
        marketPrice: 0,
      );
      final fair = Pricing.fairValue(def, _owned(def.id));
      expect(fair, greaterThan(4.0));
      expect(fair, greaterThanOrEqualTo(Pricing.speculativeBase(def) * 0.8));
    });
  });

  group('franchiseTag', () {
    test('pokemon prefix tags as POKÉMON', () {
      final pkm = _card(
        id: 'pkm_1',
        setCode: 'MEW',
        rarity: Rarity.common,
        marketPrice: 1,
        name: 'Pikachu',
      );
      final rb = _card(
        id: '123',
        setCode: 'OGN',
        rarity: Rarity.common,
        marketPrice: 1,
        name: 'Ahri',
      );
      expect(pkm.franchiseTag, 'POKÉMON');
      expect(rb.franchiseTag, 'RIFTBOUND');
    });
  });
}
