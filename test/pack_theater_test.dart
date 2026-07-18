import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bindora/game/game_controller.dart';
import 'package:bindora/models/enums.dart';
import 'package:bindora/widgets/pack_theater.dart';

Future<void> _waitUntilReady(ProviderContainer container) async {
  for (var i = 0; i < 100; i++) {
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

  testWidgets('PackRipTheater builds with fast bolt and close control',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    late List pulls;
    await tester.runAsync(() async {
      container.read(gameProvider.notifier);
      await _waitUntilReady(container);

      final listings = container.read(gameProvider).sealedListings;
      expect(listings, isNotEmpty);
      final cash = container.read(gameProvider).player.cash;
      final listing = listings.firstWhere(
        (l) => l.price <= cash,
        orElse: () => listings.first,
      );
      await container.read(gameProvider.notifier).buySealed(
            listing.id,
            payWith: listing.price <= cash
                ? PaymentMethod.cash
                : PaymentMethod.candy,
          );
      await container.read(gameProvider.notifier).openPack();
      pulls = List.from(container.read(gameProvider).lastRip!);
      expect(pulls, isNotEmpty);
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: PackRipTheater(
            pulls: List.from(pulls),
            onDone: () {},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(PackRipTheater), findsOneWidget);
    expect(find.byIcon(Icons.bolt_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('Keep all'), findsNothing);
    expect(find.textContaining('Swipe down'), findsOneWidget);
  });
}
