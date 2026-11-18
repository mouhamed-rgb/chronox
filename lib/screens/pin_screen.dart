import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/store.dart';
import '../theme.dart';
import '../widgets.dart';

enum PinMode { verify, create }

/// يفتح شاشة الرمز ويرجع true عند النجاح.
Future<bool> pinFlow(BuildContext context, PinMode mode) async {
  final r = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (c) => PinScreen(
        mode: mode,
        canCancel: true,
        onDone: (ok) => Navigator.of(c).pop(ok),
      ),
    ),
  );
  return r ?? false;
}

class PinScreen extends StatefulWidget {
  final PinMode mode;
  final bool canCancel;
  final void Function(bool ok) onDone;

  const PinScreen({
    super.key,
    required this.mode,
    required this.onDone,
    this.canCancel = false,
  });

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String? _first;
  String _msg = '';
  bool _busy = false;

  String get _title => widget.mode == PinMode.verify
      ? 'أدخل الرمز'
      : (_first == null ? 'أنشئ رمزاً من 4 أرقام' : 'أعد إدخال الرمز');

  void _press(String d) {
    if (_busy || _pin.length >= 4 || Store.pinWait > Duration.zero) return;
    setState(() => _pin += d);
    if (_pin.length == 4) Future.delayed(const Duration(milliseconds: 150), _submit);
  }

  void _back() {
    if (!_busy && _pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  void _submit() {
    if (!mounted || _busy) return;
    if (widget.mode == PinMode.verify) {
      setState(() => _busy = true);
      Store.verifyPin(_pin).then((ok) {
        if (!mounted) return;
        if (ok) {
          widget.onDone(true);
        } else {
          HapticFeedback.heavyImpact();
          final wait = Store.pinWait.inSeconds;
          setState(() {
            _pin = '';
            _busy = false;
            _msg = wait > 0 ? 'محاولات كثيرة؛ انتظر $wait ثانية' : 'الرمز غير صحيح';
          });
        }
      });
    } else {
      if (_first == null) {
        setState(() {
          _first = _pin;
          _pin = '';
          _msg = '';
        });
      } else if (_first == _pin) {
        setState(() => _busy = true);
        Store.setPin(_pin).then((_) { if (mounted) widget.onDone(true); });
      } else {
        setState(() {
          _first = null;
          _pin = '';
          _msg = 'الرمزان غير متطابقين، حاول من جديد';
        });
      }
    }
  }

  Widget _key(String label, {VoidCallback? onTap, IconData? icon}) {
    if (label.isEmpty && icon == null) return const SizedBox(width: 80, height: 80);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 68,
        height: 68,
        child: Material(
          color: Colors.white.withOpacity(0.06),
          shape: CircleBorder(side: BorderSide(color: C.cyan.withOpacity(0.35))),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: icon != null
                  ? Icon(icon, color: Colors.white70)
                  : Text(label,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];
    return NeonBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: widget.canCancel
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => widget.onDone(false),
                ),
              )
            : null,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_rounded, size: 46, color: C.cyan),
                const SizedBox(height: 14),
                Text(_title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 4; i++)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _pin.length ? C.cyan : Colors.transparent,
                          border: Border.all(color: C.cyan, width: 1.5),
                          boxShadow: i < _pin.length
                              ? [BoxShadow(color: C.cyan.withOpacity(0.7), blurRadius: 10)]
                              : null,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 22,
                  child: Text(_msg.isEmpty && Store.pinWait > Duration.zero ? 'انتظر ${Store.pinWait.inSeconds} ثانية قبل المحاولة' : _msg, style: const TextStyle(color: C.pink)),
                ),
                const SizedBox(height: 10),
                for (final r in rows)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [for (final d in r) _key(d, onTap: () => _press(d))],
                  ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _key(''),
                    _key('0', onTap: () => _press('0')),
                    _key('', icon: Icons.backspace_outlined, onTap: _back),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
