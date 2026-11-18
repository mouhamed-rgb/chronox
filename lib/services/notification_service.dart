import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_card.dart';
import '../screens/alarm_screen.dart';
import '../screens/pin_screen.dart';
import '../theme.dart';
import 'store.dart';

class NotificationService {
  static final plugin = FlutterLocalNotificationsPlugin();
  static final navKey = GlobalKey<NavigatorState>();
  static String? launchPayload;
  static bool appUnlocked = false;

  static const _dots = ['🔵', '🟠', '🔴'];

  static Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {}

    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) {
        final p = r.payload;
        if (p != null) openFor(p);
      },
    );

    final d = await plugin.getNotificationAppLaunchDetails();
    if (d?.didNotificationLaunchApp ?? false) {
      launchPayload = d!.notificationResponse?.payload;
    }
  }

  static Future<void> requestPermissions() async {
    final a = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await a?.requestNotificationsPermission();
    await a?.requestExactAlarmsPermission();
  }

  static void openFor(String payload) {
    final id = int.tryParse(payload);
    if (id == null) return;
    if (!appUnlocked) {
      launchPayload = payload;
      return;
    }
    _openAuthorized(id);
  }

  static Future<void> _openAuthorized(int id) async {
    final nav = navKey.currentState;
    final context = navKey.currentContext;
    if (nav == null || context == null) {
      launchPayload = '$id';
      return;
    }
    final card = Store.byId(id);
    if (card == null) return;
    if (card.locked && Store.hasPin) {
      final ok = await pinFlow(context, PinMode.verify);
      if (!ok || !appUnlocked) return;
    }
    nav.push(MaterialPageRoute(builder: (_) => AlarmScreen(cardId: id)));
  }

  static NotificationDetails _details(int level) {
    level = level.clamp(0, 2).toInt();
    const channels = ['pulse_l0_v1', 'pulse_l1_v1', 'pulse_l2_v1'];
    const names = ['تذكير مهم', 'تذكير ضروري', 'تذكير ضروري جداً'];
    final urgent = level == 2;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channels[level],
        names[level],
        channelDescription: 'تنبيهات بطاقات نبض',
        importance: level == 0 ? Importance.defaultImportance : Importance.max,
        priority: level == 0 ? Priority.defaultPriority : Priority.max,
        playSound: true,
        enableVibration: level > 0,
        vibrationPattern: level == 0
            ? null
            : (urgent
                ? Int64List.fromList([0, 800, 400, 800, 400, 800])
                : Int64List.fromList([0, 400, 200, 400])),
        fullScreenIntent: urgent,
        category:
            urgent ? AndroidNotificationCategory.alarm : AndroidNotificationCategory.reminder,
        audioAttributesUsage:
            urgent ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
        additionalFlags: urgent ? Int32List.fromList(<int>[4]) : null, // FLAG_INSISTENT
        ongoing: urgent,
        autoCancel: !urgent,
        visibility: NotificationVisibility.public,
        color: levelColors[level],
      ),
    );
  }

  static String _title(TaskCard c) =>
      c.locked ? '🔒 لديك تذكير' : '${_dots[c.level]} ${c.title}';

  static String _body(TaskCard c) {
    if (c.locked) return 'افتح نبض لرؤية التفاصيل';
    return c.details.isNotEmpty ? c.details : levelNames[c.level];
  }

  static Future<void> _zoned(TaskCard c, int slot, tz.TZDateTime t) async {
    Future<void> go(AndroidScheduleMode m) => plugin.zonedSchedule(
          c.id * 10 + slot,
          _title(c),
          _body(c),
          t,
          _details(c.level),
          androidScheduleMode: m,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: '${c.id}',
        );
    try {
      await go(AndroidScheduleMode.exactAllowWhileIdle);
    } catch (_) {
      try {
        await go(AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (_) {}
    }
  }

  /// يجدول التذكير حسب المستوى (مع تكرار للمستويات الأعلى).
  static Future<void> schedule(TaskCard c) async {
    await cancel(c.id);
    if (c.level < 0 || c.level > 2) c.level = c.level.clamp(0, 2).toInt();
    if (c.done) return;
    final base = tz.TZDateTime.from(c.dueAt, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    final offsets = c.level == 2
        ? [0, 2, 4, 6, 8]
        : c.level == 1
            ? [0, 5, 10]
            : [0];
    for (var i = 0; i < offsets.length; i++) {
      final t = base.add(Duration(minutes: offsets[i]));
      if (t.isBefore(now)) continue;
      await _zoned(c, i, t);
    }
  }

  static Future<void> snooze(TaskCard c, int minutes) async {
    await cancel(c.id);
    final t = tz.TZDateTime.now(tz.local).add(Duration(minutes: minutes));
    await _zoned(c, 9, t);
  }

  static Future<void> cancel(int id) async {
    for (var i = 0; i < 10; i++) {
      await plugin.cancel(id * 10 + i);
    }
  }

  /// بطاقة تجريبية تصلك بعد 10 ثوانٍ.
  static Future<void> test(int level) async {
    level = level.clamp(0, 2).toInt();
    final c = TaskCard(
      id: Store.newId(),
      title: 'تجربة تنبيه',
      details: 'هذه بطاقة تجريبية - يمكنك حذفها',
      dueAt: DateTime.now().add(const Duration(seconds: 10)),
      level: level,
    );
    await Store.save(c);
    await schedule(c);
  }
}
