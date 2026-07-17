import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kOnboarded = 'cardcandy_onboarded_v1';
const _kGame = 'cardcandy_selected_game';

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
}

class GameOption {
  const GameOption({
    required this.id,
    required this.name,
    required this.enabled,
    required this.color,
    required this.logoAsset,
  });

  final String id;
  final String name;
  final bool enabled;
  final Color color;
  final String logoAsset;
}

const kGames = [
  GameOption(
    id: 'riftbound',
    name: 'Riftbound',
    enabled: true,
    color: Color(0xFF5B8CFF),
    logoAsset: 'assets/logos/riftbound.png',
  ),
  GameOption(
    id: 'pokemon',
    name: 'Pokémon',
    enabled: false,
    color: Color(0xFFFFCB05),
    logoAsset: 'assets/logos/pokemon.svg',
  ),
  GameOption(
    id: 'mtg',
    name: 'Magic',
    enabled: false,
    color: Color(0xFFF97316),
    logoAsset: 'assets/logos/mtg.png',
  ),
  GameOption(
    id: 'onepiece',
    name: 'One Piece',
    enabled: false,
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
