import 'dart:io';

import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    required this.radius,
    this.photoPath,
  });

  final String name;
  final double radius;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final path = photoPath?.trim();
    if (path == null || path.isEmpty) {
      return _buildInitials(context);
    }

    final image = path.startsWith('http')
        ? Image.network(
            path,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildInitials(context),
          )
        : Image.file(
            File(path),
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildInitials(context),
          );

    return ClipOval(child: image);
  }

  Widget _buildInitials(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primary,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
