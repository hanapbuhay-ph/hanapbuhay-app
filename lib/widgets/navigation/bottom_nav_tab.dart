import 'package:flutter/material.dart';

class BottomNavTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool showBadge;
  final Stream<int>? badgeStream;

  BottomNavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.showBadge = false,
    this.badgeStream,
  });
}
