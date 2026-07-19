import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bindora/game/game_controller.dart';
import 'package:bindora/models/enums.dart';

Future<void> _waitUntilReady(ProviderContainer container) async {
  for (var i = 0; i < 100; i++) {
    if (container.read(gameProvider).ready) break;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  expect(container.read(gameProvider).ready, isTrue);
}

Future<void> _buyOnePack(ProviderContainer container) async {
  final listings = container.read(gameProvider).sealedListings;
  expect(listings, isNotEmpty);
  final cash = container.read(gameProvider).player.cash;
  final affordable = listings.where((l) => l.price <= cash).toList();
  final listing = affordable.isNotEmpty ? affordable.first : listings.first;
  final payWith =
      listing.price <= cash ? PaymentMethod.cash : PaymentMethod.candy;
  await container.read(gameProvider.notifier).buySealed(
        listing.id,
        payWith: payWith,
      );
  expect(container.read(gameProvider).unopened, isNotEmpty);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('exchangeRipCard awards candy and removes from rip', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(gameProvider.notifier);
    await _waitUntilReady(container);
    await _buyOnePack(container);

    await container.read(gameProvider.notifier).openPack();
    final rip = container.read(gameProvider).lastRip!;
    expect(rip, isNotEmpty);

    final id = rip.first.instanceId;
    final candyBefore = container.read(gameProvider).player.candy;
    await container.read(gameProvider.notifier).exchangeRipCard(id);

    expect(
      container.read(gameProvider).player.candy,
      greaterThan(candyBefore),
    );
    expect(
      container.read(gameProvider).lastRip!.any((c) => c.instanceId == id),
      isFalse,
    );
  });

  test('keepRipCard is idempotent and finalizeRip avoids duplicates', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(gameProvider.notifier);
    await _waitUntilReady(container);
    await _buyOnePack(container);

    await container.read(gameProvider.notifier).openPack();
    final rip = container.read(gameProvider).lastRip!;
    expect(rip, isNotEmpty);
    final id = rip.first.instanceId;

    await container.read(gameProvider.notifier).keepRipCard(id);
    final collectionAfterKeep = container.read(gameProvider).collection.length;
    expect(
      container.read(gameProvider).collection.any((c) => c.instanceId == id),
      isTrue,
    );

    await container.read(gameProvider.notifier).keepRipCard(id);
    expect(
      container.read(gameProvider).collection.length,
      collectionAfterKeep,
    );

    await container
        .read(gameProvider.notifier)
        .finalizeRip(keepRemaining: true);

    final ids =
        container.read(gameProvider).collection.map((c) => c.instanceId);
    expect(ids.length, ids.toSet().length);
    expect(container.read(gameProvider).lastRip, isNull);
  });

  test('openPack while lastRip non-empty is rejected', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(gameProvider.notifier);
    await _waitUntilReady(container);
    await _buyOnePack(container);
    await _buyOnePack(container);

    await container.read(gameProvider.notifier).openPack();
    expect(container.read(gameProvider).lastRip, isNotEmpty);

    final unopenedBefore = container.read(gameProvider).unopened.length;
    final opened = await container.read(gameProvider.notifier).openPack();

    expect(opened, isFalse);
    expect(container.read(gameProvider).unopened.length, unopenedBefore);
    expect(
      container.read(gameProvider).message,
      contains('Finish'),
    );
  });
}
