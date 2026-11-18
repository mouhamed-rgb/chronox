import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task_card.dart';

class Store {
  static Box get cards => Hive.box('cards');
  static Box get settings => Hive.box('settings');

  static List<TaskCard> all() => cards.values
      .map((e) => TaskCard.fromMap(Map<String, dynamic>.from(e as Map)))
      .toList()
    ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

  static TaskCard? byId(int id) {
    final v = cards.get(id.toString());
    if (v == null) return null;
    return TaskCard.fromMap(Map<String, dynamic>.from(v as Map));
  }

  static Future<void> save(TaskCard c) => cards.put(c.id.toString(), c.toMap());
  static Future<void> delete(int id) => cards.delete(id.toString());

  /// Notification IDs are signed 32-bit integers. Check existing keys to avoid collisions.
  static int newId() {
    final used = cards.keys.map((e) => int.tryParse('$e')).whereType<int>().toSet();
    var candidate = DateTime.now().microsecondsSinceEpoch % 200000000;
    while (used.contains(candidate) || candidate <= 0) {
      candidate = candidate >= 200000000 ? 1 : candidate + 1;
    }
    return candidate;
  }

  // ---- Preferences ----
  static int get snoozeMinutes => (settings.get('snooze', defaultValue: 10) as num).toInt();
  static set snoozeMinutes(int v) => settings.put('snooze', v.clamp(1, 120).toInt());

  static bool get lockEnabled => settings.get('lockEnabled', defaultValue: false) == true;
  static set lockEnabled(bool v) => settings.put('lockEnabled', v);

  static String? get pinHash => settings.get('pinHash') as String? ?? settings.get('pin') as String?;
  static bool get hasPin => pinHash != null;

  static int get failedPinAttempts => (settings.get('pinFailures', defaultValue: 0) as num).toInt();
  static DateTime? get pinLockedUntil {
    final raw = settings.get('pinLockedUntil');
    if (raw is int && raw > 0) return DateTime.fromMillisecondsSinceEpoch(raw);
    return null;
  }

  static Duration get pinWait {
    final until = pinLockedUntil;
    if (until == null) return Duration.zero;
    final remaining = until.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  static String _derive(String pin, String salt) {
    var bytes = utf8.encode('$salt:$pin');
    // Iterated SHA-256 raises the cost of offline guessing while remaining plugin-free.
    for (var i = 0; i < 60000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64Url.encode(bytes);
  }

  static String _legacyHash(String pin) {
    var h = 0x811c9dc5;
    for (final u in 'pulse|$pin|nabd'.codeUnits) {
      h ^= u;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16);
  }

  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static Future<void> setPin(String pin) async {
    final random = Random.secure();
    final salt = base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
    await settings.put('pinSalt', salt);
    await settings.put('pinHash', _derive(pin, salt));
    await settings.delete('pin'); // remove the legacy unsalted hash after migration
    await _clearPinFailures();
  }

  static Future<bool> verifyPin(String pin) async {
    if (pinWait > Duration.zero) return false;
    final stored = settings.get('pinHash') as String?;
    final salt = settings.get('pinSalt') as String?;
    if (stored != null && salt != null) {
      final ok = _constantTimeEquals(_derive(pin, salt), stored);
      if (ok) {
        await _clearPinFailures();
        return true;
      }
      await _recordPinFailure();
      return false;
    }

    // One-time migration for PINs created by earlier PULSE builds.
    final legacy = settings.get('pin') as String?;
    if (legacy != null && _constantTimeEquals(_legacyHash(pin), legacy)) {
      await setPin(pin);
      return true;
    }
    await _recordPinFailure();
    return false;
  }

  static Future<void> _recordPinFailure() async {
    final attempts = failedPinAttempts + 1;
    await settings.put('pinFailures', attempts);
    if (attempts >= 5) {
      final level = ((attempts - 5) ~/ 5).clamp(0, 5).toInt();
      final seconds = min(900, 30 * (1 << level)).toInt();
      await settings.put('pinLockedUntil', DateTime.now().add(Duration(seconds: seconds)).millisecondsSinceEpoch);
    }
  }

  static Future<void> _clearPinFailures() async {
    await settings.put('pinFailures', 0);
    await settings.delete('pinLockedUntil');
  }

  static Future<void> clearPin() async {
    await settings.delete('pin');
    await settings.delete('pinHash');
    await settings.delete('pinSalt');
    await _clearPinFailures();
    await settings.put('lockEnabled', false);
    for (final c in all()) {
      if (c.locked) {
        c.locked = false;
        await save(c);
      }
    }
  }
}
