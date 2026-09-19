import 'package:flutter/material.dart';

class ServiceCategoryIcons {
  static IconData fromKey(String? iconKey) {
    final snakeCaseKey = (iconKey ?? '')
        .trim()
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        );
    var normalized = snakeCaseKey
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_-]+'), '_');

    if (normalized.startsWith('lucide_')) {
      normalized = normalized.substring('lucide_'.length);
    }

    return _iconMap[normalized] ?? Icons.work_outline;
  }

  static const Map<String, IconData> _iconMap = {
    'electrical': Icons.electrical_services,
    'plumbing': Icons.plumbing,
    'tutoring': Icons.school,
    'education': Icons.school,
    'school': Icons.school,
    'cleaning': Icons.cleaning_services,
    'cleaning_services': Icons.cleaning_services,
    'house_cleaning': Icons.cleaning_services,
    'laundry': Icons.local_laundry_service,
    'laundry_service': Icons.local_laundry_service,
    'washing': Icons.local_laundry_service,
    'gardening': Icons.yard,
    'yard': Icons.yard,
    'landscaping': Icons.yard,
    'carpentry': Icons.carpenter,
    'woodworks': Icons.carpenter,
    'woodworking': Icons.carpenter,
    'masonry': Icons.foundation,
    'general_repairs': Icons.build,
    'repair': Icons.build,
    'repairs': Icons.build,
    'toolbox': Icons.build,
    'wrench': Icons.build,
    'painting': Icons.format_paint,
    'paint': Icons.format_paint,
    'paintbrush': Icons.format_paint,
    'computer': Icons.computer,
    'tech': Icons.computer,
    'technology': Icons.computer,
    'computer_repair': Icons.computer,
    'truck_electric': Icons.electrical_services,
    'book_open': Icons.school,
    'hammer': Icons.carpenter,
    'leaf': Icons.yard,
    'cooking_pot': Icons.restaurant,
    'heart_handshake': Icons.volunteer_activism,
    'bubbles': Icons.local_laundry_service,
    'wand_sparkles': Icons.auto_awesome,
  };
}
