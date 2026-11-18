import 'package:flutter/material.dart';

class C {
  static const bg0 = Color(0xFF05060F);
  static const bg1 = Color(0xFF0B1030);
  static const cyan = Color(0xFF00E5FF);
  static const violet = Color(0xFF8A5CFF);
  static const pink = Color(0xFFFF2D6F);
  static const orange = Color(0xFFFFA726);
  static const blue = Color(0xFF3D8BFF);
}

const levelColors = <Color>[C.blue, C.orange, C.pink];
const levelNames = <String>['مهم', 'ضروري', 'ضروري جداً'];
const levelIcons = <IconData>[
  Icons.notifications_active_outlined,
  Icons.priority_high_rounded,
  Icons.warning_amber_rounded,
];

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg0,
    colorScheme: const ColorScheme.dark(
      primary: C.cyan,
      secondary: C.violet,
      surface: C.bg1,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
  );
}
