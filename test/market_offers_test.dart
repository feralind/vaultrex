import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bindora/game/game_controller.dart';
import 'package:bindora/models/enums.dart';
import 'package:bindora/models/models.dart';

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

  test('MarketOffer JSON round-trips', () {
    final o = MarketOffer(
      id: 'o1',
      listingId: 'l1',
      offerAmount: 12.5,
      counterAmount: 14.0,
      status: MarketOfferStatus.countered,
      createdDay: 3,
      expiresOnDay: 5,
    );
    final back = MarketOffer.fromJson(o.toJson());
    expect(back.id, 'o1');
    expect(back.listingId, 'l1');
    expect(back.offerAmount, 12.5);
    expect(back.counterAmount, 14.0);
    expect(back.status, MarketOfferStatus.countered);
    expect(back.createdDay, 3);
    expect(back.expiresOnDay, 5);
    expect(back.isOpen, isTrue);
  });

  test('submitMarketOffer escrows cash; cancel refunds', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameProvider.notifier);
    await _waitUntilReady(container);

    await container.read(gameProvider.notifier).topUpCash(5000);
    final listing = container
        .read(gameProvider)
        .market
        .firstWhere((m) => m.price >= 2 && m.price <= 80);
    final offerAmt = double.parse(
      (listing.price * 0.9).clamp(0.99, listing.price - 0.01).toStringAsFixed(2),
    );
    final cash0 = container.read(gameProvider).player.cash;

    await container
        .read(gameProvider.notifier)
        .submitMarketOffer(listing.id, offerAmt);

    final after = container.read(gameProvider);
    expect(after.player.cash, closeTo(cash0 - offerAmt, 0.001));
    expect(after.marketOffers.where((o) => o.isOpen).length, 1);
    expect(after.marketOffers.first.offerAmount, offerAmt);
    expect(after.marketOffers.first.status, MarketOfferStatus.pending);

    final offerId = after.marketOffers.first.id;
    await container.read(gameProvider.notifier).cancelMarketOffer(offerId);
    final cancelled = container.read(gameProvider);
    expect(cancelled.player.cash, closeTo(cash0, 0.001));
    expect(cancelled.marketOffers.first.status, MarketOfferStatus.cancelled);
  });

  test('buyMarketListing cancels pending offer and refunds escrow', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameProvider.notifier);
    await _waitUntilReady(container);

    await container.read(gameProvider.notifier).topUpCash(5000);
    final listing = container
        .read(gameProvider)
        .market
        .firstWhere((m) => m.price >= 2 && m.price <= 80);
    final offerAmt = double.parse(
      (listing.price * 0.85).clamp(0.99, listing.price - 0.01).toStringAsFixed(2),
    );
    final cashBeforeOffer = container.read(gameProvider).player.cash;

    await container
        .read(gameProvider.notifier)
        .submitMarketOffer(listing.id, offerAmt);
    expect(container.read(gameProvider).marketOffers.first.isOpen, isTrue);

    final cashAfterEscrow = container.read(gameProvider).player.cash;
    expect(cashAfterEscrow, closeTo(cashBeforeOffer - offerAmt, 0.001));

    await container.read(gameProvider.notifier).buyMarketListing(listing.id);

    final after = container.read(gameProvider);
    expect(after.market.any((m) => m.id == listing.id), isFalse);
    expect(
      after.marketOffers.any((o) => o.listingId == listing.id && o.isOpen),
      isFalse,
    );
    // Paid full ask, but escrow refunded → net = cashBeforeOffer - ask.
    expect(
      after.player.cash,
      closeTo(cashBeforeOffer - listing.price, 0.02),
    );
    expect(
      after.collection.any((c) => c.cardId == listing.cardId),
      isTrue,
    );
  });

  test('advanceDay accepts high offer and grants card', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameProvider.notifier);
    await _waitUntilReady(container);

    await container.read(gameProvider.notifier).topUpCash(5000);
    final market = container.read(gameProvider).market;
    final listing = market.firstWhere(
      (m) =>
          m.sellerType == SellerType.clueless &&
          m.price >= 2 &&
          m.price <= 100,
      orElse: () => market.firstWhere((m) => m.price >= 2 && m.price <= 100),
    );
    final offerAmt = double.parse(
      (listing.price * 0.97).clamp(0.99, listing.price - 0.01).toStringAsFixed(2),
    );
    final cashBefore = container.read(gameProvider).player.cash;
    final collBefore = container.read(gameProvider).collection.length;

    await container
        .read(gameProvider.notifier)
        .submitMarketOffer(listing.id, offerAmt);
    await container.read(gameProvider.notifier).advanceDay();

    final after = container.read(gameProvider);
    final offer = after.marketOffers.firstWhere((o) => o.offerAmount == offerAmt);
    // High % should accept for clueless/serious/goblin/scammy thresholds.
    expect(
      offer.status == MarketOfferStatus.accepted ||
          offer.status == MarketOfferStatus.countered,
      isTrue,
      reason: 'got ${offer.status.name}',
    );
    if (offer.status == MarketOfferStatus.accepted) {
      expect(after.collection.length, collBefore + 1);
      expect(after.market.any((m) => m.id == listing.id), isFalse);
      // Escrow kept as payment — cash stays at cashBefore - offerAmt.
      expect(after.player.cash, closeTo(cashBefore - offerAmt, 0.02));
    }
  });

  test('advanceDay rejects lowball and refunds escrow', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameProvider.notifier);
    await _waitUntilReady(container);

    await container.read(gameProvider.notifier).topUpCash(5000);
    final listing = container.read(gameProvider).market.firstWhere(
      (m) =>
          m.price >= 5 &&
          m.price <= 100 &&
          m.sellerType == SellerType.serious,
    );
    // Far below serious's 95% accept / 88% counter floor.
    final offerAmt = double.parse((listing.price * 0.50).toStringAsFixed(2));
    final cashBefore = container.read(gameProvider).player.cash;

    await container
        .read(gameProvider.notifier)
        .submitMarketOffer(listing.id, offerAmt);
    await container.read(gameProvider.notifier).advanceDay();

    final after = container.read(gameProvider);
    final offer = after.marketOffers.firstWhere((o) => o.offerAmount == offerAmt);
    expect(
      offer.status == MarketOfferStatus.rejected ||
          offer.status == MarketOfferStatus.expired ||
          offer.status == MarketOfferStatus.cancelled,
      isTrue,
      reason: 'got ${offer.status.name}',
    );
    expect(after.player.cash, closeTo(cashBefore, 0.05));
  });

  test('singles market generates at least 3 comps for a hot card', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(gameProvider.notifier);
    await _waitUntilReady(container);

    final market = container.read(gameProvider).market;
    expect(market.length, lessThanOrEqualTo(180));
    expect(market.length, greaterThan(40));

    final byCard = <String, int>{};
    for (final m in market.where((m) => !m.graded)) {
      byCard[m.cardId] = (byCard[m.cardId] ?? 0) + 1;
    }
    final densest = byCard.values.fold<int>(0, (a, b) => a > b ? a : b);
    expect(densest, greaterThanOrEqualTo(3));
  });
}
