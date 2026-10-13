import 'package:flutter/material.dart';

class ServiceCategoryIcons {
  static IconData fromKey(String? iconKey) {
    final snakeCaseKey = (iconKey ?? '').trim().replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (match) => '${match.group(1)}_${match.group(2)}',
    );
    var normalized = snakeCaseKey.trim().toLowerCase().replaceAll(
      RegExp(r'[\s_-]+'),
      '_',
    );

    if (normalized.startsWith('lucide_')) {
      normalized = normalized.substring('lucide_'.length);
    }

    return _iconMap[normalized] ?? Icons.work_outline;
  }

  static const Map<String, IconData> _iconMap = {
    'electrical': Icons.electrical_services,
    'electrical_works': Icons.electrical_services,
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
    'gardening_landscaping': Icons.yard,
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
    'computer_repair_it': Icons.computer,
    'it': Icons.computer,
    'it_support': Icons.support_agent,
    'aircon': Icons.ac_unit,
    'air_conditioning': Icons.ac_unit,
    'aircon_repair': Icons.ac_unit,
    'aircon_repair_cleaning': Icons.ac_unit,
    'hvac': Icons.ac_unit,
    'auto': Icons.car_repair,
    'auto_repair': Icons.car_repair,
    'auto_repair_mechanic': Icons.car_repair,
    'mechanic': Icons.car_repair,
    'automotive': Icons.car_repair,
    'caregiving': Icons.volunteer_activism,
    'caregiver': Icons.volunteer_activism,
    'elderly_care': Icons.volunteer_activism,
    'massage': Icons.spa,
    'beauty': Icons.face_retouching_natural,
    'barber': Icons.content_cut,
    'food': Icons.restaurant,
    'cooking': Icons.restaurant,
    'delivery': Icons.delivery_dining,
    'moving': Icons.local_shipping,
    'pest_control': Icons.pest_control,
    'security': Icons.security,
    'photography': Icons.camera_alt,
    'event': Icons.celebration,
    'tailoring': Icons.checkroom,
    'welding': Icons.hardware,
    'truck_electric': Icons.electrical_services,
    'book_open': Icons.school,
    'hammer': Icons.carpenter,
    'leaf': Icons.yard,
    'cooking_pot': Icons.restaurant,
    'cooking_catering': Icons.restaurant,
    'heart_handshake': Icons.volunteer_activism,
    'bubbles': Icons.local_laundry_service,
    'wand_sparkles': Icons.auto_awesome,
  };
}
