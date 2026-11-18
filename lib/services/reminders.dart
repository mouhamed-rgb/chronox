import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../main.dart';
import '../models/task.dart' as model;

class Reminders {
  static Future<void> schedule(model.Task task) async {
    if (task.id == null || task.completed || !task.dueAt.isAfter(DateTime.now())) return;
    final channel = switch (task.priority) {
      model.Priority.necessary => 'normal',
      model.Priority.important => 'important',
      model.Priority.critical => 'critical',
    };
    final importance = task.priority == model.Priority.critical
        ? Importance.max
        : task.priority == model.Priority.important
            ? Importance.high
            : Importance.defaultImportance;
    final priority = task.priority == model.Priority.critical
        ? Priority.max
        : task.priority == model.Priority.important
            ? Priority.high
            : Priority.defaultPriority;
    await notifications.zonedSchedule(
      task.id!,
      'CHRONOX • ${task.title}',
      task.description.isEmpty ? 'حان موعد مهمتك' : task.description,
      tz.TZDateTime.from(task.dueAt, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel, 'CHRONOX REMINDERS',
          importance: importance, priority: priority,
          enableVibration: true, playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancel(int id) => notifications.cancel(id);
}
