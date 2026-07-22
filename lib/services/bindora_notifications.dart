import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../game/game_controller.dart';
import '../models/engagement.dart';

/// Local push reminders for daily / PSA / auction / rental / comeback.
class BindoraNotifications {
  BindoraNotifications._();
  static final BindoraNotifications instance = BindoraNotifications._();

  static const _prefsDaily = 'notif_daily';
  static const _prefsPsa = 'notif_psa';
  static const _prefsAuction = 'notif_auction';
  static const _prefsRental = 'notif_rental';
  static const _prefsComeback = 'notif_comeback';

  static const _idDaily = 1001;
  static const _idAuction = 1002;
  static const _idRental = 1003;
  static const _idComeback = 1004;
  static const _idPsaBase = 2000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  Future<void>? _initFuture;

  Future<void> init() async {
    if (kIsWeb || _ready) return;
    return _initFuture ??= _initBody();
  }

  Future<void> _initBody() async {
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (e) {
        debugPrint('Timezone setup failed: $e');
      }

      const android = AndroidInitializationSettings('@drawable/ic_stat_bindora');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );

      if (Platform.isAndroid) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            'bindora_alerts',
            'Bindora alerts',
            description: 'Daily rewards, grading, auctions, and rentals',
            importance: Importance.defaultImportance,
          ),
        );
      }
      _ready = true;
    } catch (e, st) {
      // Never let notification setup crash / hang the app shell.
      debugPrint('BindoraNotifications.init failed: $e\n$st');
      _ready = false;
      _initFuture = null; // allow a later retry
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready || kIsWeb) return false;
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final ok = await android?.requestNotificationsPermission();
      return ok ?? false;
    }
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final ok = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return ok ?? false;
    }
    return true;
  }

  Future<NotificationPrefs> loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    return NotificationPrefs(
      daily: p.getBool(_prefsDaily) ?? true,
      psa: p.getBool(_prefsPsa) ?? true,
      auction: p.getBool(_prefsAuction) ?? true,
      rental: p.getBool(_prefsRental) ?? true,
      comeback: p.getBool(_prefsComeback) ?? true,
    );
  }

  Future<void> savePrefs(NotificationPrefs prefs) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefsDaily, prefs.daily);
    await p.setBool(_prefsPsa, prefs.psa);
    await p.setBool(_prefsAuction, prefs.auction);
    await p.setBool(_prefsRental, prefs.rental);
    await p.setBool(_prefsComeback, prefs.comeback);
  }

  /// Cancel + reschedule based on game state and toggles.
  Future<void> syncFromGame(GameState state) async {
    if (kIsWeb || !state.ready) return;
    if (!_ready) await init();
    if (!_ready) return;
    final prefs = await loadPrefs();
    await _plugin.cancel(id: _idDaily);
    await _plugin.cancel(id: _idAuction);
    await _plugin.cancel(id: _idRental);
    await _plugin.cancel(id: _idComeback);
    for (var i = 0; i < 32; i++) {
      await _plugin.cancel(id: _idPsaBase + i);
    }

    final anyOn = prefs.daily ||
        prefs.psa ||
        prefs.auction ||
        prefs.rental ||
        prefs.comeback;
    if (!anyOn) return;

    if (prefs.daily) {
      final claimed = state.engagement.dailyClaimDate == engagementDayKey();
      if (!claimed) {
        await _schedule(
          id: _idDaily,
          when: _nextLocal(hour: 19, minute: 0),
          title: 'Daily candy waiting',
          body: 'Claim your streak before it cools off.',
        );
      } else {
        await _schedule(
          id: _idDaily,
          when: _nextLocal(hour: 10, minute: 0, dayOffset: 1),
          title: 'Streak check-in',
          body: 'Keep your Bindora streak alive.',
        );
      }
    }

    if (prefs.psa) {
      var i = 0;
      for (final g in state.grading) {
        if (g.revealed || g.readyAtMs == null) continue;
        final when = tz.TZDateTime.fromMillisecondsSinceEpoch(
          tz.local,
          g.readyAtMs!,
        );
        if (when.isBefore(tz.TZDateTime.now(tz.local))) continue;
        await _schedule(
          id: _idPsaBase + i,
          when: when,
          title: 'PSA slab ready',
          body: 'Your graded card is back — check Collection.',
        );
        i++;
        if (i >= 32) break;
      }
    }

    if (prefs.auction && state.auctions.isNotEmpty) {
      await _schedule(
        id: _idAuction,
        when: tz.TZDateTime.now(tz.local).add(const Duration(hours: 3)),
        title: '${state.auctions.length} lots in the Pit',
        body: 'Rivals are bidding — jump back in.',
      );
    }

    if (prefs.rental) {
      var pending = 0;
      for (final r in state.activeRentals.values) {
        pending += r.calculateEarnings();
      }
      if (pending > 0) {
        await _schedule(
          id: _idRental,
          when: tz.TZDateTime.now(tz.local).add(const Duration(hours: 2)),
          title: 'Rental candy ready',
          body: 'Claim ~$pending candy from loans.',
        );
      }
    }

    if (prefs.comeback) {
      await _schedule(
        id: _idComeback,
        when: tz.TZDateTime.now(tz.local).add(const Duration(hours: 22)),
        title: 'Miss the rip?',
        body: 'New drops and rivals moved while you were away.',
      );
    }
  }

  tz.TZDateTime _nextLocal({
    required int hour,
    required int minute,
    int dayOffset = 0,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    var when = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).add(Duration(days: dayOffset));
    if (!when.isAfter(now)) {
      when = when.add(const Duration(days: 1));
    }
    return when;
  }

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
  }) async {
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'bindora_alerts',
            'Bindora alerts',
            channelDescription:
                'Daily rewards, grading, auctions, and rentals',
            icon: '@drawable/ic_stat_bindora',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Schedule notif $id failed: $e');
    }
  }
}

class NotificationPrefs {
  const NotificationPrefs({
    required this.daily,
    required this.psa,
    required this.auction,
    required this.rental,
    required this.comeback,
  });

  final bool daily;
  final bool psa;
  final bool auction;
  final bool rental;
  final bool comeback;

  NotificationPrefs copyWith({
    bool? daily,
    bool? psa,
    bool? auction,
    bool? rental,
    bool? comeback,
  }) {
    return NotificationPrefs(
      daily: daily ?? this.daily,
      psa: psa ?? this.psa,
      auction: auction ?? this.auction,
      rental: rental ?? this.rental,
      comeback: comeback ?? this.comeback,
    );
  }
}
