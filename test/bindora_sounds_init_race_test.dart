import 'package:flutter_test/flutter_test.dart';
import 'package:bindora/services/bindora_feel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('concurrent init shares a single init body', () async {
    BindoraSounds.resetForTest();

    await Future.wait<void>([
      BindoraSounds.init(),
      BindoraSounds.init(),
      BindoraSounds.init(),
    ]);

    expect(BindoraSounds.initBodyRunsForTest, 1);
  });
}
