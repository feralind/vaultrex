import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vaultrex/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Stay on onboarding so Instapacks network image timers never start.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Vaultrex boots', (tester) async {
    // Tall surface avoids OnboardingFlow RenderFlex overflow in tests.
    await tester.binding.setSurfaceSize(const Size(400, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ProviderScope(child: VaultrexApp()));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    expect(find.byType(VaultrexApp), findsOneWidget);
  });
}
