import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_typography.dart';
import '../../core/routing/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/navigation/app_header.dart';

class LoginActivityScreen extends StatefulWidget {
  const LoginActivityScreen({super.key});

  @override
  State<LoginActivityScreen> createState() => _LoginActivityScreenState();
}

class _LoginActivityScreenState extends State<LoginActivityScreen> {
  final List<_LoginSession> _sessions = [
    _LoginSession(
      id: 's1',
      device: 'iPhone 13 Pro',
      location: 'Trinidad, Bohol',
      timestamp: 'Current Session',
      isCurrent: true,
    ),
    _LoginSession(
      id: 's2',
      device: 'Chrome on MacOS',
      location: 'Tagbilaran City, Bohol',
      timestamp: '2 hours ago',
    ),
    _LoginSession(
      id: 's3',
      device: 'Samsung Galaxy S22',
      location: 'Cebu City, Cebu',
      timestamp: 'Yesterday',
    ),
    _LoginSession(
      id: 's4',
      device: 'iPad Air',
      location: 'Manila, Metro Manila',
      timestamp: '3 days ago',
    ),
  ];

  Future<void> _handleLogoutSession(_LoginSession session) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(session.isCurrent ? 'Log out this device?' : 'Terminate Session?'),
        content: Text(
          session.isCurrent 
            ? 'You will be signed out of your account on this device. You will need to log in again to continue.'
            : 'This will log you out of your account on ${session.device}.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Log Out', 
              style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (session.isCurrent) {
        await context.read<AuthProvider>().logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (route) => false);
        }
      } else {
        setState(() {
          _sessions.removeWhere((s) => s.id == session.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logged out from ${session.device}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          const AppHeader(title: 'Login Activity'),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              itemCount: _sessions.length,
              separatorBuilder: (context, index) => Divider(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                height: 32,
              ),
              itemBuilder: (context, index) {
                final session = _sessions[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: session.isCurrent 
                            ? colorScheme.primary.withValues(alpha: 0.1) 
                            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
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
                          Row(
                            children: [
                              Text(
                                session.device,
                                style: AppTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (session.isCurrent) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${session.location} • ${session.timestamp}',
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _handleLogoutSession(session),
                            child: Text(
                              'Log out this device',
                              style: AppTypography.labelSmall.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colorScheme.outlineVariant, size: 20),
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
  final String id;
  final String device;
  final String location;
  final String timestamp;
  final bool isCurrent;

  _LoginSession({
    required this.id,
    required this.device,
    required this.location,
    required this.timestamp,
    this.isCurrent = false,
  });
}
