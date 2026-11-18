import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/task_card.dart';
import '../services/notification_service.dart';
import '../services/store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'pin_screen.dart';

/// شاشة التنبيه الكاملة (تشبه مكالمة واردة).
class AlarmScreen extends StatefulWidget {
  final int cardId;
  const AlarmScreen({super.key, required this.cardId});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  late final TaskCard? _card = Store.byId(widget.cardId);

  Future<bool> _authorize() async {
    final c = _card;
    if (c == null || !c.locked || !Store.hasPin) return true;
    return pinFlow(context, PinMode.verify);
  }

  Future<void> _done() async {
    if (!await _authorize() || !mounted) return;
    final c = _card;
    if (c != null) {
      c.done = true;
      await Store.save(c);
      await NotificationService.cancel(c.id);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze() async {
    if (!await _authorize() || !mounted) return;
    final c = _card;
    if (c != null) await NotificationService.snooze(c, Store.snoozeMinutes);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = _card;
    if (c == null) {
      return NeonBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: NeonButton(
              label: 'البطاقة محذوفة - إغلاق',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      );
    }

    final col = levelColors[c.level];
    return NeonBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: col.withOpacity(0.18),
                    border: Border.all(color: col, width: 2),
                    boxShadow: [BoxShadow(color: col.withOpacity(0.7), blurRadius: 40)],
                  ),
                  child: Icon(levelIcons[c.level], size: 56, color: col),
                )
                    .animate(onPlay: (a) => a.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.15, 1.15),
                      duration: 700.ms,
                    ),
                const SizedBox(height: 28),
                Text('تذكير ${levelNames[c.level]}',
                    style: TextStyle(color: col, fontSize: 16, letterSpacing: 1)),
                const SizedBox(height: 10),
                Text(
                  c.locked ? 'بطاقة مقفلة' : c.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
                ),
                if (!c.locked && c.details.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(c.details,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 16)),
                ],
                const SizedBox(height: 10),
                Text(fmtFull(c.dueAt), style: const TextStyle(color: Colors.white54)),
                const Spacer(),
                NeonButton(
                  label: 'تم',
                  icon: Icons.check_rounded,
                  onTap: _done,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _snooze,
                    icon: const Icon(Icons.snooze_rounded),
                    label: Text('تأجيل ${Store.snoozeMinutes} دقائق'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: col.withOpacity(0.8)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
