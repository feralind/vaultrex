import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'ui/pack_theater_soft_lift_preview.dart';

/// Standalone pack-peel preview — no game load, no Riverpod, no save.
///
/// Run:
///   flutter run -t lib/main_theater_preview.dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TheaterPreviewApp());
}

class TheaterPreviewApp extends StatelessWidget {
  const TheaterPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bindora · Pack Peel Preview',
      debugShowCheckedModeBanner: false,
      theme: CC.dark(),
      home: const PackTheaterSoftLiftPreview(),
    );
  }
}
