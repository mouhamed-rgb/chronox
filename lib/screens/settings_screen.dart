import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'pin_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
        child: Text(t, style: const TextStyle(color: C.cyan, fontWeight: FontWeight.w700)),
      );

  Future<void> _toggleLock(bool v) async {
    if (v) {
      if (!Store.hasPin) {
        final ok = await pinFlow(context, PinMode.create);
        if (!ok) return;
      }
      Store.lockEnabled = true;
    } else {
      Store.lockEnabled = false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _changePin() async {
    final ok = await pinFlow(context, PinMode.verify);
    if (!ok || !mounted) return;
    await pinFlow(context, PinMode.create);
    if (mounted) setState(() {});
  }

  Future<void> _removePin() async {
    final ok = await pinFlow(context, PinMode.verify);
    if (!ok) return;
    await Store.clearPin();
    if (mounted) {
      setState(() {});
      _snack('تمت إزالة الرمز وفتح كل البطاقات');
    }
  }

  Future<void> _test(int level) async {
    await NotificationService.test(level);
    _snack('سيصلك التنبيه بعد 10 ثوانٍ - اقفل الشاشة أو اخرج من التطبيق');
  }

  Future<void> _clearDone() async {
    for (final c in Store.all().where((c) => c.done)) {
      await NotificationService.cancel(c.id);
      await Store.delete(c.id);
    }
    _snack('تم حذف البطاقات المنجزة');
  }

  @override
  Widget build(BuildContext context) {
    return NeonBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('الإعدادات')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            _section('الأمان'),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  SwitchListTile(
                    value: Store.lockEnabled && Store.hasPin,
                    onChanged: _toggleLock,
                    title: const Text('قفل التطبيق بالرمز'),
                    secondary: const Icon(Icons.lock_rounded, color: C.cyan),
                  ),
                  if (Store.hasPin) ...[
                    ListTile(
                      leading: const Icon(Icons.password_rounded, color: C.cyan),
                      title: const Text('تغيير الرمز'),
                      onTap: _changePin,
                    ),
                    ListTile(
                      leading: const Icon(Icons.no_encryption_gmailerrorred_rounded,
                          color: C.pink),
                      title: const Text('إزالة الرمز'),
                      onTap: _removePin,
                    ),
                  ],
                ],
              ),
            ),
            _section('التأجيل'),
            GlassCard(
              glow: C.violet,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مدة التأجيل (دقائق)'),
                  const SizedBox(height: 12),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 5, label: Text('5')),
                      ButtonSegment(value: 10, label: Text('10')),
                      ButtonSegment(value: 15, label: Text('15')),
                      ButtonSegment(value: 30, label: Text('30')),
                    ],
                    selected: {Store.snoozeMinutes},
                    onSelectionChanged: (s) =>
                        setState(() => Store.snoozeMinutes = s.first),
                  ),
                ],
              ),
            ),
            _section('جرّب التنبيهات'),
            GlassCard(
              glow: C.pink,
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < 3; i++)
                    OutlinedButton(
                      onPressed: () => _test(i),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: levelColors[i],
                        side: BorderSide(color: levelColors[i]),
                      ),
                      child: Text(levelNames[i]),
                    ),
                ],
              ),
            ),
            _section('البيانات'),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.delete_sweep_rounded, color: C.pink),
                title: const Text('حذف البطاقات المنجزة'),
                onTap: _clearDone,
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text('نبض • الإصدار 1.1',
                  style: TextStyle(color: Colors.white38)),
            ),
          ],
        ),
      ),
    );
  }
}
