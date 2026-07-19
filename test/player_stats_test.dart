import 'package:flutter_test/flutter_test.dart';
import 'package:bindora/models/enums.dart';
import 'package:bindora/models/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PlayerStats is immutable and copyWith updates cash', () {
    const original = PlayerStats(cash: 100, candy: 200);
    final updated = original.copyWith(cash: 250);

    expect(original.cash, 100);
    expect(updated.cash, 250);
    expect(updated.candy, 200);
    expect(identical(original, updated), isFalse);
  });

  test('JSON roundtrip preserves fields including ownedUpgrades', () {
    final stats = PlayerStats(
      cash: 1234.5,
      candy: 999,
      xp: 42,
      businessLevel: 3,
      packsOpened: 7,
      cardsSold: 11,
      gemsPulled: 2,
      ownedUpgrades: const {'fee_cut', 'auto_snipe'},
      unlockedAchievements: const {'first_rip'},
    );

    final roundtrip = PlayerStats.fromJson(stats.toJson());

    expect(roundtrip.cash, stats.cash);
    expect(roundtrip.candy, stats.candy);
    expect(roundtrip.xp, stats.xp);
    expect(roundtrip.businessLevel, stats.businessLevel);
    expect(roundtrip.packsOpened, stats.packsOpened);
    expect(roundtrip.cardsSold, stats.cardsSold);
    expect(roundtrip.gemsPulled, stats.gemsPulled);
    expect(roundtrip.ownedUpgrades, stats.ownedUpgrades);
    expect(roundtrip.unlockedAchievements, stats.unlockedAchievements);
  });

  test('CardDef franchise tags follow id prefix', () {
    const pkm = CardDef(
      id: 'pkm_502548',
      productId: 502548,
      setCode: 'MEW',
      setName: 'SV: Scarlet & Violet 151',
      name: 'Squirtle',
      rarity: Rarity.common,
      marketPrice: 0.27,
      imageUrl: '',
      imageUrlSmall: '',
      imageKey: 'pkm_502548',
    );
    const rb = CardDef(
      id: 'rb_123',
      productId: 123,
      setCode: 'OGN',
      setName: 'Origins',
      name: 'Ahri',
      rarity: Rarity.rare,
      marketPrice: 10,
      imageUrl: '',
      imageUrlSmall: '',
      imageKey: 'rb_123',
    );

    expect(pkm.isPokemonCard, isTrue);
    expect(pkm.franchiseTag, 'POKÉMON');
    expect(pkm.setYear, '2023');
    expect(rb.isPokemonCard, isFalse);
    expect(rb.franchiseTag, 'RIFTBOUND');
    expect(rb.setYear, '2025');
  });
}
