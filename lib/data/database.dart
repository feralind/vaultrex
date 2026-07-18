import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'riftbound_catalog.dart';

/// Lightweight JSON save store (works on Android + Web).
///
/// Each franchise has its own economy slot so markets never overwrite each other.
/// Wallet (cash/candy/xp) is shared separately.
class AppDatabase {
  static const _legacyKey = 'cardflip_game_v2';
  static const _walletKey = 'cardflip_wallet_v1';

  static String _slotKey(String gameId) {
    final id = GameCatalog.normalizeId(gameId);
    return 'cardflip_game_v2_$id';
  }

  /// One-time: move legacy single-slot save into the selected franchise slot.
  Future<void> migrateLegacyIfNeeded(String selectedGameId) async {
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_legacyKey);
    if (legacy == null || legacy.isEmpty) return;

    final target = _slotKey(selectedGameId);
    if (!prefs.containsKey(target) || (prefs.getString(target)?.isEmpty ?? true)) {
      await prefs.setString(target, legacy);
      // Seed shared wallet from legacy player blob if missing.
      if (!prefs.containsKey(_walletKey)) {
        try {
          final map = jsonDecode(legacy) as Map<String, dynamic>;
          final player = map['player'];
          if (player is Map<String, dynamic>) {
            await prefs.setString(_walletKey, jsonEncode(player));
          }
        } catch (_) {}
      }
    }
    await prefs.remove(_legacyKey);
  }

  Future<Map<String, dynamic>?> loadPayload(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_slotKey(gameId));
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> savePayload(String gameId, Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_slotKey(gameId), jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> loadWallet() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_walletKey);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> saveWallet(Map<String, dynamic> playerJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_walletKey, jsonEncode(playerJson));
  }

  Future<void> close() async {}
}
