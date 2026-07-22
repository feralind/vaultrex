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

    test('chase threshold is tier-relative', () {
      expect(featuredChaseFairThreshold(4.99), 12.0);
      expect(featuredChaseFairThreshold(24.99), 12.0);
      expect(featuredChaseFairThreshold(49.99), closeTo(23.995, 0.02));
      expect(featuredChaseFairThreshold(179.99), closeTo(86.395, 0.05));
    });

    test('pity chase ignores cheap 8-dollar hits on premium packs', () {
      expect(
        isFeaturedPityChase(maxFair: 9, packPriceUsd: 49.99),
        isFalse,
      );
      expect(
        isFeaturedPityChase(maxFair: 30, packPriceUsd: 49.99),
        isTrue,
      );
      expect(
        isFeaturedPityChase(maxFair: 12, packPriceUsd: 4.99),
        isTrue,
      );
    });

    test('daily claim candy is juicier for entry rips', () {
      expect(dailyClaimCandyForStreak(1), 330);
      expect(dailyClaimCandyForStreak(7), 870);
    });
  });

  group('price-scaled hit rate', () {
    test('EV exponent steepens with pack price', () {
      expect(FeaturedPackOpener.highlightEvExponent(5), 1.18);
      expect(FeaturedPackOpener.highlightEvExponent(50), 1.35);
      expect(FeaturedPackOpener.highlightEvExponent(130), 1.42);
      expect(FeaturedPackOpener.highlightEvExponent(250), 1.52);
      expect(FeaturedPackOpener.highlightEvExponent(350), 1.60);
      expect(FeaturedPackOpener.highlightEvExponent(500), 1.72);
    });

    test('premium floor chance scales toward whale packs', () {
      expect(FeaturedPackOpener.premiumFloorChance(50), 0);
      expect(
        FeaturedPackOpener.premiumFloorChance(130),
        closeTo(0.178, 0.01),
      );
      expect(
        FeaturedPackOpener.premiumFloorChance(500),
        closeTo(0.40, 0.01),
      );
    });
  });
}
