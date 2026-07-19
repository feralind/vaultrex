import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:vaultrex/data/riftbound_catalog.dart';
import 'package:vaultrex/game/pack_opener.dart';
import 'package:vaultrex/models/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameCatalog catalog;
  late String setCode;

  setUpAll(() async {
    GameCatalog.clearCache();
    catalog = await GameCatalog.load('riftbound');
    setCode = catalog.bySet.keys.firstWhere(
      (code) {
        final commons = catalog.pool(code, Rarity.common);
        final uncommons = catalog.pool(code, Rarity.uncommon);
        final rares = catalog.pool(code, Rarity.rare);
        return commons.isNotEmpty &&
            uncommons.isNotEmpty &&
            rares.isNotEmpty;
      },
    );
  });

  test('openPack returns 14 cards for riftbound', () {
    final opener = RiftboundPackOpener(catalog, rng: Random(1));
    final pack = opener.openPack(setCode);
    expect(pack, hasLength(14));
  });

  test('seeded opener produces foils', () {
    final opener = RiftboundPackOpener(catalog, rng: Random(42));
    final pack = opener.openPack(setCode);
    expect(pack.any((c) => c.foil), isTrue);
  });

  test('openPack for pokemon catalog returns 10 cards', () async {
    GameCatalog.clearCache();
    final pokemon = await GameCatalog.load('pokemon');
    // Pokémon catalog may omit Uncommon; require Common + Rare at minimum.
    final pokeSet = pokemon.bySet.keys.firstWhere(
      (code) {
        final commons = pokemon.pool(code, Rarity.common);
        final rares = pokemon.pool(code, Rarity.rare);
        return commons.isNotEmpty && rares.isNotEmpty;
      },
    );
    final opener = RiftboundPackOpener(pokemon, rng: Random(7));
    expect(opener.openPack(pokeSet), hasLength(10));
  });

  test('condition distribution is mostly mint or nearMint', () {
    final opener = RiftboundPackOpener(catalog, rng: Random(99));
    var mintOrNm = 0;
    var total = 0;
    for (var i = 0; i < 200; i++) {
      for (final card in opener.openPack(setCode)) {
        total++;
        if (card.condition == Condition.mint ||
            card.condition == Condition.nearMint) {
          mintOrNm++;
        }
      }
    }
    expect(mintOrNm / total, greaterThan(0.80));
  });
}
