import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/task_card.dart';
import '../services/notification_service.dart';
import '../services/store.dart';
import '../theme.dart';
import '../utils.dart';
import '../widgets.dart';
import 'add_card_screen.dart';
import 'pin_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showDone = false;

  Future<void> _open(TaskCard c) async {
    if (c.locked && Store.hasPin) {
      final ok = await pinFlow(context, PinMode.verify);
      if (!ok || !mounted) return;
    }
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AddCardScreen(card: c)));
  }

  Future<void> _toggle(TaskCard c) async {
    if (c.locked && Store.hasPin) {
      final ok = await pinFlow(context, PinMode.verify);
      if (!ok || !mounted) return;
    }
    c.done = !c.done;
    await Store.save(c);
    if (c.done) {
      await NotificationService.cancel(c.id);
    } else if (c.dueAt.isAfter(DateTime.now())) {
      await NotificationService.schedule(c);
    }
  }

  Widget _dismissBg(Alignment a) => Container(
        alignment: a,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: C.pink.withOpacity(0.25),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: C.pink, size: 30),
      );

  Widget _tile(TaskCard c, int i) {
    final col = levelColors[c.level];
    final overdue = !c.done && c.dueAt.isBefore(DateTime.now());
    final title = c.locked ? 'بطاقة مقفلة' : c.title;

    return Dismissible(
      key: ValueKey(c.id),
      direction: DismissDirection.horizontal,
      background: _dismissBg(Alignment.centerRight),
      secondaryBackground: _dismissBg(Alignment.centerLeft),
      confirmDismiss: (_) async {
        if (c.locked && Store.hasPin) return pinFlow(context, PinMode.verify);
        return true;
      },
      onDismissed: (_) async {
        await NotificationService.cancel(c.id);
        await Store.delete(c.id);
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          glow: col,
          onTap: () => _open(c),
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: col.withOpacity(0.15),
                  border: Border.all(color: col),
                  boxShadow: [BoxShadow(color: col.withOpacity(0.45), blurRadius: 14)],
                ),
                child: Icon(levelIcons[c.level], color: col),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.done ? Colors.white54 : Colors.white,
                        decoration: c.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule_rounded,
                                size: 14, color: overdue ? C.pink : Colors.white54),
                            const SizedBox(width: 4),
                            Text(
                              fmtFull(c.dueAt),
                              style: TextStyle(
                                fontSize: 12.5,
                                color: overdue ? C.pink : Colors.white60,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: col.withOpacity(0.18),
                          ),
                          child: Text(levelNames[c.level],
                              style: TextStyle(fontSize: 11.5, color: col)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (c.locked)
                const Icon(Icons.lock_rounded, size: 18, color: Colors.white54),
              IconButton(
                onPressed: () => _toggle(c),
                icon: Icon(
                  c.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                  color: c.done ? C.cyan : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(delay: (40 * i).ms).slideY(begin: 0.12, end: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NeonBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: C.cyan.withOpacity(0.5), blurRadius: 24)],
          ),
          child: FloatingActionButton.extended(
            elevation: 0,
            backgroundColor: C.cyan,
            foregroundColor: Colors.black,
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AddCardScreen())),
            icon: const Icon(Icons.add_rounded),
            label: const Text('بطاقة جديدة',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
        body: SafeArea(
          child: ValueListenableBuilder(
            valueListenable: Store.cards.listenable(),
            builder: (context, _, __) {
              final all = Store.all();
              final pending = all.where((c) => !c.done).length;
              final list = all.where((c) => c.done == _showDone).toList()
                ..sort((a, b) => a.dueAt.compareTo(b.dueAt));

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 12, 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ShaderMask(
                                    shaderCallback: (r) => const LinearGradient(
                                      colors: [C.cyan, C.violet],
                                    ).createShader(r),
                                    child: const Text(
                                      'نبض',
                                      style: TextStyle(
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.bolt_rounded, color: C.cyan)
                                      .animate(onPlay: (c) => c.repeat(reverse: true))
                                      .scale(
                                        begin: const Offset(1, 1),
                                        end: const Offset(1.25, 1.25),
                                        duration: 900.ms,
                                      ),
                                ],
                              ),
                              Text('$pending بطاقة بانتظارك',
                                  style: const TextStyle(color: Colors.white60)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SettingsScreen())),
                          icon: const Icon(Icons.tune_rounded),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('القادمة'),
                          selected: !_showDone,
                          onSelected: (_) => setState(() => _showDone = false),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('المنجزة'),
                          selected: _showDone,
                          onSelected: (_) => setState(() => _showDone = true),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: list.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome_rounded,
                                    size: 54, color: Colors.white24),
                                SizedBox(height: 12),
                                Text(
                                  'لا توجد بطاقات هنا\nاضغط «بطاقة جديدة» لتبدأ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white54, height: 1.6),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: list.length,
                            itemBuilder: (_, i) => _tile(list[i], i),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
