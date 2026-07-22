import 'package:flutter/material.dart';

import '../theme/app_text.dart';
import '../theme/app_theme.dart';
import '../widgets/brand.dart';

/// Polished cold-start splash shown while [StartupPreload] warms the image cache.
class StartupSplash extends StatelessWidget {
  const StartupSplash({
    super.key,
    required this.progress,
    required this.status,
  });

  /// 0..1
  final double progress;
  final String status;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: CC.bg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0E1410),
              CC.bg,
              Color(0xFF0A1218),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: CC.scan.withValues(alpha: 0.20),
                          blurRadius: 32,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: CC.accent.withValues(alpha: 0.14),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.asset(
                        AppBrand.logoAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: CC.card,
                          child: Center(child: RiftMark(size: 52)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    AppBrand.name,
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w800,
                      fontSize: 30,
                      letterSpacing: 0.5,
                      color: CC.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: CC.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 4,
                      width: 168,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: CC.line.withValues(alpha: 0.7),
                          ),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: p <= 0 ? 0.06 : p,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF8BC34A),
                                    CC.scan,
                                    Color(0xFFD4FF4F),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
