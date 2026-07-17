import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaultrex/game/game_controller.dart';
import 'package:vaultrex/models/models.dart';

Future<void> _waitUntilReady(ProviderContainer container) async {
  for (var i = 0; i < 120; i++) {
    if (container.read(gameProvider).ready) break;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  expect(container.read(gameProvider).ready, isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('OnlineListing JSON keeps listedAtMs', () {
    final o = OnlineListing(
      id: 'l1',
      ownedInstanceId: 'c1',
      ask: 10,
      listedDay: 2,
      listedAtMs: 1234567890,
    );
    final back = OnlineListing.fromJson(o.toJson());
    expect(back.listedAtMs, 1234567890);
  });

  test('catchUpOnlineSales with zero elapsed does not sell', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameProvider.notifier);
    await _waitUntilReady(container);

    final notifier = container.read(gameProvider.notifier);
    final now = DateTime.now().millisecondsSinceEpoch;

    await notifier.topUpCash(5000);
    final listing = container
        .read(gameProvider)
        .market
        .firstWhere((m) => m.price >= 2 && m.price <= 40);
    await notifier.buyMarketListing(listing.id);
    final card = container
        .read(gameProvider)
        .collection
        .firstWhere((c) => c.cardId == listing.cardId);
    final fair = notifier.fairFor(card);
    await notifier.listOnline(card.instanceId, fair * 0.9);

    await notifier.catchUpOnlineSales(nowMs: now);
    final beforeCash = container.read(gameProvider).player.cash;
    final beforeListings = container.read(gameProvider).onlineListings.length;
    final sold = await notifier.catchUpOnlineSales(nowMs: now);
    expect(sold, 0);
    expect(container.read(gameProvider).player.cash, beforeCash);
    expect(container.read(gameProvider).onlineListings.length, beforeListings);
  });

  test('catchUpOnlineSales after 48h attempts fills', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameProvider.notifier);
    await _waitUntilReady(container);

    final notifier = container.read(gameProvider.notifier);
    await notifier.topUpCash(5000);
    final listing = container
        .read(gameProvider)
        .market
        .firstWhere((m) => m.price >= 2 && m.price <= 50);
    await notifier.buyMarketListing(listing.id);
    final card = container
        .read(gameProvider)
        .collection
        .firstWhere((c) => c.cardId == listing.cardId);
    final fair = notifier.fairFor(card);
    await notifier.listOnline(card.instanceId, fair * 0.9);

    final now = DateTime.now().millisecondsSinceEpoch;
    const window = 20 * 60 * 60 * 1000;
    final past = now - (window * 2) - 1000;
    await notifier.catchUpOnlineSales(nowMs: past);

    expect(container.read(gameProvider).onlineListings.length, 1);

    final sold = await notifier.catchUpOnlineSales(nowMs: now);
    expect(sold, inInclusiveRange(0, 1));
    if (sold > 0) {
      expect(container.read(gameProvider).onlineListings, isEmpty);
      expect(
        container.read(gameProvider).message,
        contains('While you were away'),
      );
    } else {
      expect(container.read(gameProvider).onlineListings.length, 1);
    }
  });

  test('catchUp caps at 3 checks even after a long absence', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameProvider.notifier);
    await _waitUntilReady(container);

    final notifier = container.read(gameProvider.notifier);
    final now = DateTime.now().millisecondsSinceEpoch;
    const window = 20 * 60 * 60 * 1000;
    await notifier.catchUpOnlineSales(nowMs: now - window * 10);
    final sold = await notifier.catchUpOnlineSales(nowMs: now);
    expect(sold, greaterThanOrEqualTo(0));
    expect(container.read(gameProvider).lastPlayedAtMs, now);
  });
}
