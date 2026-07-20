import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../data/engagement_defs.dart';

/// Phase 9 haptic taxonomy — distinct patterns by reveal tier.
enum HapticTier { common, uncommon, rare, chase }

class BindoraHaptics {
  static Future<void> forTier(HapticTier tier) async {
    switch (tier) {
      case HapticTier.common:
        await HapticFeedback.selectionClick();
      case HapticTier.uncommon:
        await HapticFeedback.lightImpact();
      case HapticTier.rare:
        await HapticFeedback.mediumImpact();
        await Future<void>.delayed(const Duration(milliseconds: 40));
        await HapticFeedback.lightImpact();
      case HapticTier.chase:
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 55));
        await HapticFeedback.heavyImpact();
        await Future<void>.delayed(const Duration(milliseconds: 45));
        await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> peelTick() => HapticFeedback.selectionClick();

  static Future<void> peelRip() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 35));
    await HapticFeedback.lightImpact();
  }

  static Future<void> packOpen() => HapticFeedback.heavyImpact();

  static Future<void> flipStart() => HapticFeedback.lightImpact();

  static Future<void> swipeKeep() async {
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await HapticFeedback.selectionClick();
  }

  static Future<void> swipeSell() => HapticFeedback.mediumImpact();

  static Future<void> tearProgress(double tear) async {
    if (tear >= 0.8 && tear < 0.82) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> success() => HapticFeedback.lightImpact();
  static Future<void> claim() => HapticFeedback.mediumImpact();
}

HapticTier hapticTierFor({
  required bool isChase,
  required bool foil,
  required bool rarePlus,
}) {
  if (isChase) return HapticTier.chase;
  if (rarePlus) return HapticTier.rare;
  if (foil) return HapticTier.uncommon;
  return HapticTier.common;
}

/// Rare Candy–style SFX pool (low-latency overlapping short WAVs).
class BindoraSounds {
  static bool _ready = false;
  static bool _muted = false;
  static final List<AudioPlayer> _pool = [];
  static int _cursor = 0;
  static const _poolSize = 6;

  static const peelTickAsset = 'sfx/peel_tick.wav';
  static const peelRipAsset = 'sfx/peel_rip.wav';
  static const packOpenAsset = 'sfx/pack_open.wav';
  static const flipAsset = 'sfx/flip.wav';
  static const swipeKeepAsset = 'sfx/swipe_keep.wav';
  static const swipeSellAsset = 'sfx/swipe_sell.wav';
  static const revealCommonAsset = 'sfx/reveal_common.wav';
  static const revealUncommonAsset = 'sfx/reveal_uncommon.wav';
  static const revealRareAsset = 'sfx/reveal_rare.wav';
  static const revealChaseAsset = 'sfx/reveal_chase.wav';
  static const foilShimmerAsset = 'sfx/foil_shimmer.wav';
  static const cardLandAsset = 'sfx/card_land.wav';
  static const uiClickAsset = 'sfx/ui_click.wav';

  static Future<void> init() async {
    if (_ready) return;
    try {
      // AssetSource paths are relative to the Flutter assets/ folder.
      for (var i = 0; i < _poolSize; i++) {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setVolume(0.85);
        _pool.add(p);
      }
      _ready = true;
    } catch (e) {
      debugPrint('BindoraSounds.init failed: $e');
      _ready = false;
    }
  }

  static void setMuted(bool muted) => _muted = muted;

  static Future<void> _play(String asset, {double volume = 0.85}) async {
    if (_muted) return;
    if (!_ready) await init();
    if (_pool.isEmpty) {
      // Last-resort click so something still feedbacks.
      await SystemSound.play(SystemSoundType.click);
      return;
    }
    try {
      final player = _pool[_cursor % _pool.length];
      _cursor++;
      await player.stop();
      await player.setVolume(volume.clamp(0.0, 1.0));
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('BindoraSounds play($asset): $e');
    }
  }

  static Future<void> peelTick() => _play(peelTickAsset, volume: 0.55);
  static Future<void> peelRip() => _play(peelRipAsset, volume: 0.9);
  static Future<void> packOpen() => _play(packOpenAsset, volume: 0.95);
  static Future<void> flip() => _play(flipAsset, volume: 0.8);
  static Future<void> swipeKeep() => _play(swipeKeepAsset, volume: 0.85);
  static Future<void> swipeSell() => _play(swipeSellAsset, volume: 0.8);
  static Future<void> cardLand() => _play(cardLandAsset, volume: 0.7);
  static Future<void> uiClick() => _play(uiClickAsset, volume: 0.5);
  static Future<void> foilShimmer() => _play(foilShimmerAsset, volume: 0.75);

  static Future<void> revealForTier(HapticTier tier) {
    return switch (tier) {
      HapticTier.common => _play(revealCommonAsset, volume: 0.7),
      HapticTier.uncommon => _play(revealUncommonAsset, volume: 0.8),
      HapticTier.rare => _play(revealRareAsset, volume: 0.9),
      HapticTier.chase => _play(revealChaseAsset, volume: 1.0),
    };
  }

  /// Alias used by older chase-stinger call sites.
  static Future<void> chaseStinger() => _play(revealChaseAsset, volume: 1.0);

  static Future<void> gemClink() => _play(revealChaseAsset, volume: 0.95);

  static Future<void> shopAmbientStub(int businessLevel) async {
    if (businessLevel >= 12) await uiClick();
  }
}

/// Rip presentation tier from pack contents (known at rip start).
enum RipPresentationTier { quiet, standard, heated, legendary }

RipPresentationTier ripTierForPulls({
  required bool anyChase,
  required bool anyRarePlus,
  required double maxFair,
}) {
  if (anyChase || maxFair >= 40) return RipPresentationTier.legendary;
  if (anyRarePlus || maxFair >= 12) return RipPresentationTier.heated;
  if (maxFair >= 4) return RipPresentationTier.standard;
  return RipPresentationTier.quiet;
}

Duration peelDurationForTier(RipPresentationTier tier, {required bool fast}) {
  if (fast) return const Duration(milliseconds: 80);
  return switch (tier) {
    RipPresentationTier.quiet => const Duration(milliseconds: 280),
    RipPresentationTier.standard => const Duration(milliseconds: 380),
    RipPresentationTier.heated => const Duration(milliseconds: 520),
    RipPresentationTier.legendary => const Duration(milliseconds: 680),
  };
}

String businessBlurb(int level) {
  for (final b in businessTitles.reversed) {
    if (level >= b.minLevel) return b.blurb;
  }
  return businessTitles.first.blurb;
}
