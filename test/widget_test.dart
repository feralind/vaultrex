import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vaultrex/main.dart';

void main() {
  testWidgets('Vaultrex boots', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: VaultrexApp()));
    await tester.pump();
    expect(find.byType(VaultrexApp), findsOneWidget);
  });
}
