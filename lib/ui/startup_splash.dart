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
    final pct = (p * 100).round().clamp(0, 100);

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
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: CC.scan.withValues(alpha: 0.22),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: CC.accent.withValues(alpha: 0.18),
                          blurRadius: 36,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        AppBrand.logoAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const ColoredBox(
                          color: CC.card,
                          child: Center(child: RiftMark(size: 48)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    AppBrand.name,
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: 0.4,
                      color: CC.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status,
                    textAlign: TextAlign.center,
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: CC.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      height: 6,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          const ColoredBox(color: CC.line),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: p <= 0 ? 0.04 : p,
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
                  const SizedBox(height: 10),
                  Text(
                    '$pct%',
                    style: AppText.jakarta(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.8,
                      color: CC.scan,
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
