import 'package:flutter_test/flutter_test.dart';

import 'package:bindora/game/featured_pack_opener.dart';
import 'package:bindora/models/engagement.dart';

void main() {
  group('featured pity dopamine curve', () {
    test('heat saturates at hard pity', () {
      expect(pityHeatPercent(0), 0);
      expect(pityHeatPercent(6), 50);
      expect(pityHeatPercent(kFeaturedHardPityDry), 100);
      expect(pityHeatPercent(99), 100);
    });

    test('soft boost ramps before hard pity', () {
      expect(pityWeightBoost(0), 1.0);
      expect(pityWeightBoost(2), closeTo(1.23, 0.01));
      expect(pityWeightBoost(10), greaterThan(2.0));
      expect(pityWeightBoost(20), 2.15); // capped 1 + 1.15
    });

    test('chase threshold scales at ~95% of pack price', () {
      expect(featuredChaseFairThreshold(4.99), 12.0);
      expect(featuredChaseFairThreshold(24.99), closeTo(23.741, 0.02));
      expect(featuredChaseFairThreshold(49.99), closeTo(47.491, 0.02));
      expect(featuredChaseFairThreshold(179.99), closeTo(170.991, 0.05));
    });

    test('pity chase ignores cheap hits on premium packs', () {
      expect(
        isFeaturedPityChase(maxFair: 9, packPriceUsd: 49.99),
        isFalse,
      );
      expect(
        isFeaturedPityChase(maxFair: 48, packPriceUsd: 49.99),
        isTrue,
      );
      expect(
        isFeaturedPityChase(maxFair: 12, packPriceUsd: 4.99),
        isTrue,
      );
      expect(
        isFeaturedPityChase(maxFair: 20, packPriceUsd: 24.99),
        isFalse,
      );
    });

    test('daily claim candy is juicier for entry rips', () {
      expect(dailyClaimCandyForStreak(1), 330);
      expect(dailyClaimCandyForStreak(7), 870);
    });

    test('exchange rate tiers junk vs chase', () {
      expect(exchangeRateForFair(0.50), 0.45);
      expect(exchangeRateForFair(8), 0.58);
      expect(exchangeRateForFair(40), 0.74);
      // Dumping a set-hole card pays worse.
      expect(exchangeRateForFair(8, fillsSetHole: true), closeTo(0.48, 0.001));
    });

    test('keep urge fires on pity clear and set holes', () {
      expect(
        shouldUrgeKeep(fair: 30, packPriceUsd: 24.99, pityCleared: true),
        isTrue,
      );
      expect(
        shouldUrgeKeep(fair: 3, packPriceUsd: 24.99, fillsSetHole: true),
        isTrue,
      );
      expect(
        shouldUrgeKeep(fair: 3, packPriceUsd: 24.99),
        isFalse,
      );
    });

    test('soft pity jackpot rises on whale packs', () {
      expect(softPityJackpotChance(25), 0.08);
      expect(softPityJackpotChance(130), 0.14);
      expect(softPityJackpotChance(250), 0.20);
    });
  });

  group('price-scaled hit rate', () {
    test('EV exponent steepens with pack price', () {
      expect(FeaturedPackOpener.highlightEvExponent(5), 1.18);
      expect(FeaturedPackOpener.highlightEvExponent(50), 1.22);
      expect(FeaturedPackOpener.highlightEvExponent(130), 1.38);
      expect(FeaturedPackOpener.highlightEvExponent(250), 1.48);
      expect(FeaturedPackOpener.highlightEvExponent(350), 1.58);
      expect(FeaturedPackOpener.highlightEvExponent(500), 1.70);
    });

    test('premium floor chance scales toward whale packs', () {
      expect(FeaturedPackOpener.premiumFloorChance(50), 0);
      expect(
        FeaturedPackOpener.premiumFloorChance(130),
        closeTo(0.2484, 0.01),
      );
      expect(
        FeaturedPackOpener.premiumFloorChance(500),
        closeTo(0.50, 0.01),
      );
    });

    test('near-miss chance rises with pack price', () {
      expect(FeaturedPackOpener.nearMissChance(5), 0.24);
      expect(FeaturedPackOpener.nearMissChance(25), 0.32);
      expect(FeaturedPackOpener.nearMissChance(130), 0.40);
    });
  });
}
