import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  final base = ThemeData.light();
  return base.copyWith(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      isDense: true,
    ),
  );
}
