import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight JSON save store (works on Android + Web).
class AppDatabase {
  static const _key = 'cardflip_game_v2';

  Future<Map<String, dynamic>?> loadPayload() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> savePayload(Map<String, dynamic> payload) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(payload));
  }

  Future<void> close() async {}
}
