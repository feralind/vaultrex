import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboarded = 'cardcandy_onboarded_v1';
const _kGame = 'cardcandy_selected_game';
const _kFastRip = 'vaultrex_fast_rip';

class OnboardingStore {
  static Future<bool> isDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kOnboarded) ?? false;
  }

  static Future<void> complete({required String gameId}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kOnboarded, true);
    await p.setString(_kGame, gameId);
  }

  static Future<String> selectedGame() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kGame) ?? 'riftbound';
  }

  static Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kOnboarded);
    await p.remove(_kGame);
  }

  static Future<bool> isFastRip() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kFastRip) ?? false;
  }

  static Future<void> setFastRip(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kFastRip, value);
  }
}

class GameOption {
  const GameOption({
    required this.id,
    required this.name,
    required this.enabled,
    required this.color,
    required this.logoAsset,
    /// Visual weight vs wordmark logos (icon marks need a bump).
    this.logoScale = 1,
  });

  final String id;
  final String name;
  final bool enabled;
  final Color color;
  final String logoAsset;
  final double logoScale;
}

const kGames = [
  GameOption(
    id: 'riftbound',
    name: 'Riftbound',
    enabled: true,
    color: Color(0xFFF4820A),
    // Orange swirl — franchise selection / picker only (not pack art).
    logoAsset: 'assets/logos/riftbound.png',
    // Square icon mark — scale up to balance Pokémon / other wordmarks.
    logoScale: 1.22,
  ),
  GameOption(
    id: 'pokemon',
    name: 'Pokémon',
    enabled: true,
    color: Color(0xFFFFCB05),
    logoAsset: 'assets/logos/pokemon.svg',
  ),
  GameOption(
    id: 'mtg',
    name: 'Magic',
    enabled: true,
    color: Color(0xFFF97316),
    logoAsset: 'assets/logos/mtg.png',
    logoScale: 1.12,
  ),
  GameOption(
    id: 'onepiece',
    name: 'One Piece',
    enabled: true,
    color: Color(0xFFEF4444),
    logoAsset: 'assets/logos/onepiece.png',
  ),
  GameOption(
    id: 'lorcana',
    name: 'Lorcana',
    enabled: false,
    color: Color(0xFFA78BFA),
    logoAsset: 'assets/logos/lorcana.png',
  ),
  GameOption(
    id: 'gundam',
    name: 'Gundam',
    enabled: false,
    color: Color(0xFF22D3EE),
    logoAsset: 'assets/logos/gundam.png',
  ),
];
