import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';
import '../models/task.dart';

class Reminders {
  static Future<void> schedule(Task task) async {
    if (task.id == null || task.completed || !task.dueAt.isAfter(DateTime.now())) return;
    final channel = switch (task.priority) {
      Priority.necessary => 'normal',
      Priority.important => 'important',
      Priority.critical => 'critical',
    };
    final importance = task.priority == Priority.critical
        ? fln.Importance.max
        : task.priority == Priority.important
            ? fln.Importance.high
            : fln.Importance.defaultImportance;
    final notificationPriority = task.priority == Priority.critical
        ? fln.Priority.max
        : fln.Priority.high;
    await notifications.zonedSchedule(
      task.id!,
      'CHRONOX • ${task.title}',
      task.description.isEmpty ? 'حان موعد مهمتك' : task.description,
      tz.TZDateTime.from(task.dueAt, tz.local),
      fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          channel,
          'CHRONOX REMINDERS',
          importance: importance,
          priority: notificationPriority,
          enableVibration: true,
          playSound: true,
        ),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancel(int id) => notifications.cancel(id);
}
