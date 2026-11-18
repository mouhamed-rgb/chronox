import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/store.dart';
import 'home_screen.dart';
import 'pin_screen.dart';

/// Central app-lock gate. Notification navigation is released only after unlock.
class Gate extends StatefulWidget {
  const Gate({super.key});

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> with WidgetsBindingObserver {
  late bool _locked = Store.lockEnabled && Store.hasPin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.appUnlocked = !_locked;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.requestPermissions();
      _drainPendingNotification();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.appUnlocked = false;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      if (Store.lockEnabled && Store.hasPin && mounted) {
        setState(() => _locked = true);
        NotificationService.appUnlocked = false;
      }
    } else if (state == AppLifecycleState.resumed && !_locked) {
      NotificationService.appUnlocked = true;
    }
  }

  void _unlocked(bool ok) {
    if (!ok || !mounted) return;
    setState(() => _locked = false);
    NotificationService.appUnlocked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _drainPendingNotification());
  }

  void _drainPendingNotification() {
    if (!mounted || _locked || !NotificationService.appUnlocked) return;
    final payload = NotificationService.launchPayload;
    if (payload == null) return;
    NotificationService.launchPayload = null;
    NotificationService.openFor(payload);
  }

  @override
  Widget build(BuildContext context) {
    if (_locked) {
      return PinScreen(mode: PinMode.verify, onDone: _unlocked);
    }
    return const HomeScreen();
  }
}
