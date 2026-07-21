import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bindora/widgets/pack_peel_scrub.dart';

void main() {
  test('frameExact is continuous across progress (no discrete jumps)', () {
    final samples = <double>[];
    for (var i = 0; i <= 200; i++) {
      samples.add(ScrubPeelStage.frameExact(i / 200));
    }
    // Adjacent progress samples must advance by less than one full frame.
    for (var i = 1; i < samples.length; i++) {
      final step = samples[i] - samples[i - 1];
      expect(step, greaterThanOrEqualTo(0));
      expect(step, lessThan(1.0),
          reason: 'progress ${i / 200} jumped $step frames');
    }
    expect(samples.first, 0);
    expect(samples.last, ScrubPeelStage.lastGoodFrame.toDouble());
  });

  test('legacy frame asset helpers still cover dense bake set', () {
    expect(ScrubPeelStage.frameCount, 96);
    expect(ScrubPeelStage.lastGoodFrame, 95);
    expect(ScrubPeelStage.frameAsset(0), 'assets/rip/frames/peel_00.png');
    expect(ScrubPeelStage.frameAsset(95), 'assets/rip/frames/peel_95.png');
  });

  test('resolvePackUrl prefers live pack art over Bindora bake', () {
    expect(
      ScrubPeelStage.resolvePackUrl(
        'assets/featured_packs/mtg/pack_legendary.png',
      ),
      'assets/featured_packs/mtg/pack_legendary.png',
    );
    expect(
      ScrubPeelStage.resolvePackUrl('https://cdn.example/pack.jpg'),
      'https://cdn.example/pack.jpg',
    );
    expect(
      ScrubPeelStage.resolvePackUrl(null),
      ScrubPeelStage.sealedFallbackPack,
    );
    expect(
      ScrubPeelStage.resolvePackUrl(''),
      ScrubPeelStage.sealedFallbackPack,
    );
    // Fallback must be a real featured pack — never the baked Bindora peel.
    expect(ScrubPeelStage.sealedFallbackPack, isNot(ScrubPeelStage.sealedAsset));
    expect(ScrubPeelStage.sealedFallbackPack, contains('featured_packs'));
  });

  test('PeelGeometry advances tip top→bottom with progress', () {
    final sealed = PeelGeometry.fromProgress(0);
    final mid = PeelGeometry.fromProgress(0.4);
    final done = PeelGeometry.fromProgress(1);
    expect(sealed.peelT, lessThan(0.02));
    expect(mid.peelT, greaterThan(sealed.peelT));
    expect(done.peelT, greaterThan(mid.peelT));
    expect(done.exitT, greaterThan(0.9));

    const size = Size(200, 400);
    expect(mid.tipYFor(size), greaterThan(sealed.tipYFor(size)));
    expect(done.tipYFor(size), greaterThan(mid.tipYFor(size)));
  });

  testWidgets('ScrubPeelStage peels live packImageUrl (not baked frames)',
      (tester) async {
    const pack = 'assets/featured_packs/pokemon/pack_common.png';
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScrubPeelStage(
            progress: 0.45,
            showHint: false,
            interactive: false,
            packImageUrl: pack,
            cardBackAsset: 'assets/card_backs/pokemon_back.png',
          ),
        ),
      ),
    );
    await tester.pump();
    // Allow KnockoutProductImage / asset decode a couple frames.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(ScrubPeelStage), findsOneWidget);
    // Must not mount the old baked peel frame Image.asset paths.
    expect(find.text('Swipe down to rip'), findsNothing);
    // Live peel uses ClipPath for the V-tear remaining pack.
    expect(find.byType(ClipPath), findsWidgets);
  });

  test('PeelDragMapper maps downward travel smoothly', () {
    final m = PeelDragMapper(fullTravelPx: 240, maxAccumPx: 320);
    expect(m.progress, 0);

    final a = m.applyDelta(24); // 10% raw
    final b = m.applyDelta(24); // 20% raw
    expect(a, greaterThan(0));
    expect(b, greaterThan(a));
    expect(b, lessThan(0.35));

    // Upward deltas ignored by caller; mapper only gets positive.
    final same = m.applyDelta(0);
    expect(same, b);

    m.reset();
    expect(m.progress, 0);
  });

  test('PeelDragMapper inertiaBoost scales with flick velocity', () {
    final m = PeelDragMapper();
    final soft = m.inertiaBoost(
      DragEndDetails(
        velocity: const Velocity(pixelsPerSecond: Offset(0, 400)),
        primaryVelocity: 400,
      ),
    );
    final hard = m.inertiaBoost(
      DragEndDetails(
        velocity: const Velocity(pixelsPerSecond: Offset(0, 1800)),
        primaryVelocity: 1800,
      ),
    );
    // 400px/s → 0.04; 1800px/s → 0.18
    expect(soft, closeTo(0.04, 0.005));
    expect(hard, closeTo(0.18, 0.005));
    expect(hard, greaterThan(soft));
  });
}
