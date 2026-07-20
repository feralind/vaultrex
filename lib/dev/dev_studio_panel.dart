import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../ui/dev_hub_screen.dart';
import 'dev_studio.dart';

/// Long-press card art → open Dev Hub with that image pre-selected for swap.
void devSelectImageSource(
  BuildContext context,
  String urlOrPath, {
  String label = 'Artwork',
}) {
  if (!kDebugMode) return;
  final studio = DevStudio.instance;
  studio.select('img:${urlOrPath.hashCode}', label: label);
  openDevHub(context, imageTarget: urlOrPath);
}
