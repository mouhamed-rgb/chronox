import 'package:flutter/material.dart';

import '../models/task_card.dart';
import '../services/notification_service.dart';
import '../services/store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'pin_screen.dart';

class AddCardScreen extends StatefulWidget {
  final TaskCard? card;
  const AddCardScreen({super.key, this.card});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  late final TextEditingController _title =
      TextEditingController(text: widget.card?.title ?? '');
  late final TextEditingController _details =
      TextEditingController(text: widget.card?.details ?? '');
  late DateTime _when = widget.card?.dueAt ?? _defaultWhen();
  late bool _locked = widget.card?.locked ?? false;

  static DateTime _defaultWhen() {
    final n = DateTime.now().add(const Duration(hours: 1));
    return DateTime(n.year, n.month, n.day, n.hour, 0);
  }

  @override
  void dispose() {
    _title.dispose();
    _details.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m), behavior: SnackBarBehavior.floating));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _when,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() => _when = DateTime(d.year, d.month, d.day, _when.hour, _when.minute));
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _when.hour, minute: _when.minute),
    );
    if (t != null) {
      setState(() => _when = DateTime(_when.year, _when.month, _when.day, t.hour, t.minute));
    }
  }

  Future<void> _save() async {
    final t = _title.text.trim();
    if (t.isEmpty) {
      _snack('اكتب عنوان البطاقة أولاً');
      return;
    }
    if (_when.isBefore(DateTime.now())) {
      _snack('اختر وقتاً في المستقبل');
      return;
    }
    if (_locked && !Store.hasPin) {
      final ok = await pinFlow(context, PinMode.create);
      if (!ok) {
        setState(() => _locked = false);
        return;
      }
    }
    if (!mounted) return;
    final level = await showLevelSheet(context, initial: widget.card?.level);
    if (level == null) return;

    final card = TaskCard(
      id: widget.card?.id ?? Store.newId(),
      title: t,
      details: _details.text.trim(),
      dueAt: _when,
      level: level,
      locked: _locked,
    );
    await Store.save(card);
    await NotificationService.schedule(card);
    if (mounted) Navigator.of(context).pop();
  }

  Widget _field(TextEditingController c, String hint, {int lines = 1}) => GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextField(
          controller: c,
          maxLines: lines,
          minLines: lines,
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white38),
          ),
        ),
      );

  Widget _pickerTile(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: GlassCard(
          onTap: onTap,
          glow: C.violet,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: C.cyan, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return NeonBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.card == null ? 'بطاقة جديدة' : 'تعديل البطاقة'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _field(_title, 'ماذا يجب أن تفعل؟'),
            const SizedBox(height: 14),
            _field(_details, 'تفاصيل (اختياري)', lines: 4),
            const SizedBox(height: 14),
            Row(
              children: [
                _pickerTile(Icons.calendar_month_rounded, fmtDate(_when), _pickDate),
                const SizedBox(width: 12),
                _pickerTile(Icons.access_time_rounded, fmtTime(_when), _pickTime),
              ],
            ),
            const SizedBox(height: 14),
            GlassCard(
              glow: C.violet,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: SwitchListTile(
                value: _locked,
                onChanged: (v) => setState(() => _locked = v),
                title: const Text('قفل البطاقة'),
                subtitle: const Text('تُخفى تفاصيلها خلف الرمز',
                    style: TextStyle(color: Colors.white54)),
                secondary: const Icon(Icons.lock_outline_rounded, color: C.cyan),
              ),
            ),
            const SizedBox(height: 26),
            NeonButton(label: 'حفظ', icon: Icons.check_rounded, onTap: _save),
          ],
        ),
      ),
    );
  }
}

/// بعد الانتهاء من البطاقة: اختيار مستوى الأهمية.
Future<int?> showLevelSheet(BuildContext context, {int? initial}) {
  const desc = [
    'إشعار هادئ في موعده',
    'إشعار بصوت واهتزاز يتكرر كل 5 دقائق',
    'شاشة تنبيه كاملة ورنين متواصل كأنه اتصال',
  ];

  Widget tile(BuildContext ctx, int i) {
    final col = levelColors[i];
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.of(ctx).pop(i),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: col.withOpacity(initial == i ? 0.25 : 0.10),
          border: Border.all(color: col.withOpacity(0.8)),
          boxShadow: [BoxShadow(color: col.withOpacity(0.25), blurRadius: 14)],
        ),
        child: Row(
          children: [
            Icon(levelIcons[i], color: col, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(levelNames[i],
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800, color: col)),
                  const SizedBox(height: 2),
                  Text(desc[i],
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(14),
      child: GlassCard(
        glow: C.violet,
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ما مدى أهمية هذه البطاقة؟',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            for (var i = 0; i < 3; i++)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: tile(ctx, i)),
          ],
        ),
      ),
    ),
  );
}
