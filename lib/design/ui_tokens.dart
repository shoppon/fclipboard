import 'package:flutter/material.dart';

class UiTokens {
  static const Color primary = Color(0xFF3B82F6);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color card = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderSubtle = Color(0xFFEFF2F7);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color subtle = Color(0xFFEFF4FF);
  static const Color codeBackground = Color(0xFFF3F6FB);
  static const Color codeBorder = Color(0xFFD8E2F2);

  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius chipRadius = BorderRadius.all(Radius.circular(10));

  static const List<BoxShadow> softShadow = [
    BoxShadow(
      color: Color(0x140F172A),
      blurRadius: 18,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: Color(0x1A0F172A),
      blurRadius: 26,
      offset: Offset(0, 14),
    ),
  ];

  static const List<BoxShadow> focusShadow = [
    BoxShadow(
      color: Color(0x1A3B82F6),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];
}
