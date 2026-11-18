import 'package:flutter/material.dart';\nimport 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'services/settings_service.dart';

final notifications = FlutterLocalNotificationsPlugin();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();\n  await initializeDateFormatting('ar');
  tzdata.initializeTimeZones();
  try { final zone = await FlutterTimezone.getLocalTimezone(); tz.setLocalLocation(tz.getLocation(zone.identifier)); } catch (_) { tz.setLocalLocation(tz.getLocation('UTC')); }
  await notifications.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
  final android = notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await android?.requestNotificationsPermission();
  await android?.requestExactAlarmsPermission();
  for (final c in [
    const AndroidNotificationChannel('normal','ضروري',description:'تذكير عادي',importance:Importance.defaultImportance),
    const AndroidNotificationChannel('important','مهم',description:'تذكير مهم',importance:Importance.high),
    const AndroidNotificationChannel('critical','ضروري جداً',description:'تذكير ذو أولوية قصوى',importance:Importance.max),
  ]) { await android?.createNotificationChannel(c); }
  await SettingsService.init();
  runApp(const ChronoxApp());
}
class ChronoxApp extends StatelessWidget {
  const ChronoxApp({super.key});
  @override Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner:false,title:'CHRONOX',
    theme:ThemeData(brightness:Brightness.dark,scaffoldBackgroundColor:const Color(0xFF070B18),colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF65E8FF),brightness:Brightness.dark),useMaterial3:true),
    home:SettingsService.pinEnabled?const LockScreen():const HomeScreen());
}