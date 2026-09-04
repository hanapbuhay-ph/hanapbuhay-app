import 'package:flutter/material.dart';

enum TrustTier {
  verified,
  trusted,
  flagged,
  revoked,
}

class TrustTierInfo {
  final IconData icon;
  final Color color;
  final String label;

  const TrustTierInfo({
    required this.icon,
    required this.color,
    required this.label,
  });
}

extension TrustTierExtension on TrustTier? {
  TrustTierInfo get info {
    switch (this) {
      case TrustTier.trusted:
        return const TrustTierInfo(
          icon: Icons.stars_rounded,
          color: Colors.blue,
          label: 'Trusted',
        );
      case TrustTier.verified:
        return const TrustTierInfo(
          icon: Icons.verified_user_rounded,
          color: Colors.green,
          label: 'Barangay Verified',
        );
      case TrustTier.flagged:
        return const TrustTierInfo(
          icon: Icons.report_problem_rounded,
          color: Colors.orange,
          label: 'Flagged',
        );
      case TrustTier.revoked:
        return const TrustTierInfo(
          icon: Icons.block_rounded,
          color: Colors.red,
          label: 'Revoked',
        );
      case null:
        return const TrustTierInfo(
          icon: Icons.warning_amber_rounded,
          color: Colors.amber,
          label: 'Unverified',
        );
    }
  }

  int get sortPriority {
    switch (this) {
      case TrustTier.trusted:
        return 3;
      case TrustTier.verified:
        return 2;
      case null:
        return 1;
      case TrustTier.flagged:
      case TrustTier.revoked:
        return 0;
    }
  }
}
