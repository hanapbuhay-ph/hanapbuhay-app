import 'package:flutter/material.dart';

class ServiceCategoryIcons {
  static IconData fromKey(String? iconKey) {
    final normalized = (iconKey ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s_-]+'), '_');

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
    'laundry': Icons.local_laundry_service,
    'laundry_service': Icons.local_laundry_service,
    'washing': Icons.local_laundry_service,
    'gardening': Icons.yard,
    'yard': Icons.yard,
    'landscaping': Icons.yard,
    'carpentry': Icons.carpenter,
    'woodworks': Icons.carpenter,
    'woodworking': Icons.carpenter,
    'general_repairs': Icons.build,
    'repair': Icons.build,
    'repairs': Icons.build,
    'painting': Icons.format_paint,
    'paint': Icons.format_paint,
    'computer': Icons.computer,
    'tech': Icons.computer,
    'technology': Icons.computer,
  };
}
