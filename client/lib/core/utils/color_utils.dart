import 'package:flutter/material.dart';

final List<Color> _avatarColors = [
  const Color(0xFF1E3A5F),
  const Color(0xFF0EA5E9),
  const Color(0xFF059669),
  const Color(0xFFD97706),
  const Color(0xFF6366F1),
  const Color(0xFFEC4899),
  const Color(0xFF14B8A6),
  const Color(0xFFF59E0B),
];

Color colorFromName(String name) {
  if (name.isEmpty) return _avatarColors[0];
  int hash = 0;
  for (int i = 0; i < name.length; i++) {
    hash = name.codeUnitAt(i) + ((hash << 5) - hash);
  }
  return _avatarColors[hash.abs() % _avatarColors.length];
}

Color statusBorderColor(String status) {
  final s = status.toLowerCase();
  if (s == 'active' || s == 'delivered' || s == 'completed') {
    return const Color(0xFF059669);
  }
  if (s == 'pending' || s == 'in_transit' || s == 'to_process') {
    return const Color(0xFFD97706);
  }
  if (s == 'expired' || s == 'cancelled' || s == 'overdue' || s == 'failed') {
    return const Color(0xFFDC2626);
  }
  return const Color(0xFF94A3B8);
}
