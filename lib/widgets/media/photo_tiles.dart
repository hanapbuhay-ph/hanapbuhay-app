import 'dart:io';

import 'package:flutter/material.dart';

class PhotoUploadTile extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData icon;
  final double borderRadius;

  const PhotoUploadTile({
    super.key,
    required this.onTap,
    required this.label,
    this.icon = Icons.add_a_photo_outlined,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoPreviewTile extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;
  final double borderRadius;
  final double removeIconSize;

  const PhotoPreviewTile({
    super.key,
    required this.path,
    required this.onRemove,
    this.borderRadius = 16,
    this.removeIconSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = path.startsWith('http')
        ? Image.network(path, fit: BoxFit.cover)
        : Image.file(File(path), fit: BoxFit.cover);

    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: image,
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.shadow.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                size: removeIconSize,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
