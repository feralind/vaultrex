import 'dart:collection';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/featured_packs.dart';
import '../data/onboarding.dart';
import '../data/riftbound_catalog.dart';
import '../widgets/brand.dart';
import '../widgets/knockout_image.dart';
import '../widgets/pack_peel_scrub.dart';

/// Progress snapshot for the cold-start splash.
class StartupPreloadProgress {
  const StartupPreloadProgress({
    required this.fraction,
    required this.status,
  });

  /// 0..1 overall progress.
  final double fraction;
  final String status;
}

/// Warm-caches pack / card / chrome images before the main shell is usable.
///
/// Failures are swallowed silently. On Flutter Web, only local raster assets
/// are precached — cross-origin CDN bytes often lack CORS and CanvasKit throws
/// `EncodingError: The source image cannot be decoded` (engine-logged spam).
abstract final class StartupPreload {
  static const softTimeout = Duration(seconds: 18);
  static const concurrency = 8;

  /// Max catalog card thumbs after priority display arts (keeps MTG practical).
  /// Web skips network entirely; keep a small native budget.
  static const maxThumbUrlsNative = 120;
  static const maxThumbUrlsWeb = 0;

  static Future<void> run({
    required BuildContext context,
    required void Function(StartupPreloadProgress) onProgress,
    String? gameId,
    Duration timeout = softTimeout,
    int parallel = concurrency,
  }) async {
    void report(double fraction, String status) {
      onProgress(
        StartupPreloadProgress(
          fraction: fraction.clamp(0.0, 1.0),
          status: status,
        ),
      );
    }

    report(0.02, 'Starting…');

    final id = GameCatalog.normalizeId(
      gameId ?? await OnboardingStore.selectedGame(),
    );

    report(0.06, 'Loading catalog…');
    GameCatalog catalog;
    try {
      catalog = await GameCatalog.load(id);
    } catch (_) {
      report(1.0, 'Ready');
      return;
    }

    if (!context.mounted) return;

    final critical = _filterUrls(_criticalAssets());
    final packs = _filterUrls(_packImageUrls(catalog, id));
    final cards = _filterUrls(_cardImageUrls(catalog, id));

    final phases = <({String status, List<String> urls, double weight})>[
      (status: 'Loading chrome…', urls: critical, weight: 0.12),
      (status: 'Loading packs…', urls: packs, weight: 0.28),
      (status: 'Loading cards…', urls: cards, weight: 0.60),
    ];

    final totalWeight =
        phases.fold<double>(0, (a, p) => a + (p.urls.isEmpty ? 0 : p.weight));
    var doneWeight = 0.0;

    final deadline = DateTime.now().add(timeout);

    for (final phase in phases) {
      if (!context.mounted) return;
      if (DateTime.now().isAfter(deadline)) {
        report(1.0, 'Ready');
        return;
      }
      if (phase.urls.isEmpty) continue;

      report(
        totalWeight <= 0 ? 1.0 : doneWeight / totalWeight,
        phase.status,
      );

      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        report(1.0, 'Ready');
        return;
      }

      var completed = 0;
      final total = phase.urls.length;

      await _precachePool(
        context: context,
        urls: phase.urls,
        parallel: parallel,
        timeout: remaining,
        onOneDone: () {
          completed++;
          final local = completed / total;
          final frac = totalWeight <= 0
              ? 1.0
              : (doneWeight + phase.weight * local) / totalWeight;
          report(frac, phase.status);
        },
      );

      if (DateTime.now().isAfter(deadline)) {
        report(1.0, 'Ready');
        return;
      }

      doneWeight += phase.weight;
    }

    report(1.0, 'Ready');
  }

  static List<String> _criticalAssets() {
    final out = <String>{
      AppBrand.logoAsset,
      'assets/logos/riftbound.png',
      'assets/logos/mtg.png',
      'assets/card_backs/riftbound_back.png',
      'assets/card_backs/pokemon_back.png',
      'assets/card_backs/mtg_back.png',
      'assets/card_backs/onepiece_back.png',
      ScrubPeelStage.sealedAsset,
      ScrubPeelStage.sealedFallbackPack,
      'assets/instapacks/border_left.png',
      'assets/instapacks/border_middle.png',
      'assets/instapacks/border_right.png',
    };

    for (final g in kGames) {
      if (!g.enabled) continue;
      final logo = g.logoAsset;
      if (_isRasterPath(logo)) out.add(logo);
    }

    // All featured pack arts (small set; switching franchise stays warm).
    for (final folder in const ['riftbound', 'pokemon', 'mtg', 'onepiece']) {
      for (final tier in FeaturedPackTier.values) {
        out.add('assets/featured_packs/$folder/pack_${tier.name}.png');
      }
    }

    return out.toList(growable: false);
  }

  static List<String> _packImageUrls(GameCatalog catalog, String gameId) {
    final seen = <String>{};
    final out = <String>[];

    void add(String? url) {
      final u = url?.trim() ?? '';
      if (!_isPrecacheCandidate(u)) return;
      if (seen.add(u)) out.add(u);
    }

    for (final p in catalog.sealed) {
      add(p.displayArtUrl);
    }

    for (final pack in featuredPacksFor(gameId)) {
      add(pack.assetPath);
    }

    return out;
  }

  static List<String> _cardImageUrls(GameCatalog catalog, String gameId) {
    final seen = <String>{};
    final priority = <String>[];
    final thumbs = <String>[];
    final maxThumbs = kIsWeb ? maxThumbUrlsWeb : maxThumbUrlsNative;

    void addPriority(String? url) {
      final u = url?.trim() ?? '';
      if (!_isPrecacheCandidate(u)) return;
      if (seen.add(u)) priority.add(u);
    }

    void addThumb(String? url) {
      final u = url?.trim() ?? '';
      if (!_isPrecacheCandidate(u)) return;
      if (seen.add(u)) thumbs.add(u);
    }

    // Featured top hits — display art (shown on Instapacks tiles).
    for (final pack in featuredPacksFor(gameId)) {
      for (final hit in pack.topHitIds) {
        final c = catalog.byId[hit.cardId];
        if (c != null) addPriority(c.displayArtUrl);
      }
    }

    // A handful of chase display arts from the richest sealed sets.
    final sealedSets = <String>{
      for (final p in catalog.sealed) p.setCode,
    }.toList()
      ..sort();
    var chaseBudget = kIsWeb ? 0 : 36;
    for (final code in sealedSets) {
      if (chaseBudget <= 0) break;
      final urls = chaseArtUrlsForSet(catalog, code, count: 4);
      for (final url in urls) {
        if (chaseBudget <= 0) break;
        final before = priority.length;
        addPriority(url);
        if (priority.length > before) chaseBudget--;
      }
    }

    // Remaining catalog thumbs for browsing (capped for large franchises).
    if (maxThumbs > 0) {
      final ranked = [...catalog.cards]
        ..sort((a, b) {
          final price = b.marketPrice.compareTo(a.marketPrice);
          if (price != 0) return price;
          return a.id.compareTo(b.id);
        });

      for (final c in ranked) {
        if (thumbs.length >= maxThumbs) break;
        addThumb(c.thumbArtUrl);
      }
    }

    return [...priority, ...thumbs];
  }

  /// Raster assets always; network only when we can safely decode (not Web).
  static List<String> _filterUrls(List<String> urls) {
    final out = <String>[];
    final seen = <String>{};
    for (final raw in urls) {
      final u = raw.trim();
      if (!_isPrecacheCandidate(u)) continue;
      if (kIsWeb && !isAssetImageUrl(u)) continue;
      if (seen.add(u)) out.add(u);
    }
    return out;
  }

  static bool _isRasterPath(String url) {
    final lower = url.toLowerCase().split('?').first;
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp');
  }

  static bool _isPrecacheCandidate(String url) {
    if (url.isEmpty) return false;
    final lower = url.toLowerCase();
    if (lower.endsWith('.svg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.webm')) {
      return false;
    }
    if (isAssetImageUrl(url)) return _isRasterPath(url);
    // Network: require a real raster extension. Skip extensionless Scrydex
    // (`…/large`) and HTML error pages disguised as images.
    return _isRasterPath(url);
  }

  static Future<void> _precachePool({
    required BuildContext context,
    required List<String> urls,
    required int parallel,
    required Duration timeout,
    required void Function() onOneDone,
  }) async {
    final queue = Queue<String>.of(urls);
    final workers = List.generate(parallel.clamp(1, 16), (_) async {
      while (true) {
        if (!context.mounted) return;
        if (queue.isEmpty) return;
        final url = queue.removeFirst();
        try {
          await _precacheOne(context, url);
        } catch (_) {
          // Swallow — never spam console (engine may still log decode errors
          // if we pass bad bytes; filtering above prevents that).
        }
        onOneDone();
      }
    });

    try {
      await Future.any([
        Future.wait(workers),
        Future<void>.delayed(timeout),
      ]);
    } catch (_) {
      // Soft timeout / pool abort — launch with whatever warmed.
    }
  }

  static Future<void> _precacheOne(BuildContext context, String url) async {
    if (!context.mounted) return;
    if (!_isPrecacheCandidate(url)) return;
    // Belt-and-suspenders: never hit network decode on Web.
    if (kIsWeb && !isAssetImageUrl(url)) return;

    final ImageProvider provider;
    if (isAssetImageUrl(url)) {
      provider = AssetImage(normalizeAssetPath(url));
    } else {
      provider = CachedNetworkImageProvider(url);
    }
    await precacheImage(provider, context).timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  }
}
