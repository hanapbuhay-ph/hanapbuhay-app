import 'package:flutter/services.dart';

final List<TextInputFormatter> philippineMobileNumberFormatters = [
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(11),
];

String? validatePhilippineMobileNumber(String? value) {
  final number = value?.replaceAll(RegExp(r'[\s()-]'), '') ?? '';
  if (number.isEmpty) return 'Mobile number is required.';
  if (!RegExp(r'^09\d{9}$').hasMatch(number)) {
    return 'Enter 11 digits starting with 09 (e.g. 09171234567).';
  }
  return null;
}

String normalizePhilippineMobileNumber(String value) {
  final cleaned = value.replaceAll(RegExp(r'[\s()-]'), '');
  if (RegExp(r'^\+639\d{9}$').hasMatch(cleaned)) {
    return '0${cleaned.substring(3)}';
  }
  return cleaned;
}
