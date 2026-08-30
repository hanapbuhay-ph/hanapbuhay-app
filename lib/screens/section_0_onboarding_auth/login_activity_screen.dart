import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/navigation/app_header.dart';

class LoginActivityScreen extends StatelessWidget {
  const LoginActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final mockSessions = [
      _LoginSession(
        device: 'iPhone 13 Pro',
        location: 'Trinidad, Bohol',
        timestamp: 'Current Session',
        isCurrent: true,
      ),
      _LoginSession(
        device: 'Chrome on MacOS',
        location: 'Tagbilaran City, Bohol',
        timestamp: '2 hours ago',
      ),
      _LoginSession(
        device: 'Samsung Galaxy S22',
        location: 'Cebu City, Cebu',
        timestamp: 'Yesterday',
      ),
      _LoginSession(
        device: 'iPad Air',
        location: 'Manila, Metro Manila',
        timestamp: '3 days ago',
      ),
    ];

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          const AppHeader(title: 'Login Activity'),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: mockSessions.length,
              separatorBuilder: (context, index) => Divider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                height: 32,
              ),
              itemBuilder: (context, index) {
                final session = mockSessions[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: session.isCurrent 
                            ? colorScheme.primary.withValues(alpha: 0.1) 
                            : colorScheme.surfaceVariant.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        session.device.contains('Chrome') 
                            ? Icons.laptop 
                            : Icons.smartphone,
                        color: session.isCurrent ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.device,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${session.location} • ${session.timestamp}',
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (session.isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: AppTypography.labelSmall.copyWith(
                            color: colorScheme.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginSession {
  final String device;
  final String location;
  final String timestamp;
  final bool isCurrent;

  _LoginSession({
    required this.device,
    required this.location,
    required this.timestamp,
    this.isCurrent = false,
  });
}
