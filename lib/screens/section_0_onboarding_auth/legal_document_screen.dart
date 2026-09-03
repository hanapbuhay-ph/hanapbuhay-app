import 'package:flutter/material.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/navigation/app_header.dart';

class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType type;

  const LegalDocumentScreen({
    super.key,
    required this.type,
  });

  bool get _isTerms => type == LegalDocumentType.terms;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sections = _isTerms ? _termsSections : _privacySections;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Column(
        children: [
          AppHeader(title: _isTerms ? 'Terms of Service' : 'Privacy Policy'),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isTerms ? 'HanapBuhay Terms of Service' : 'HanapBuhay Privacy Policy',
                    style: AppTypography.headlineLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Effective date: September 3, 2026',
                    style: AppTypography.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      _isTerms
                          ? 'Please read these Terms before using HanapBuhay. By creating an account, you confirm that you understand and agree to these Terms.'
                          : 'This Privacy Policy explains how HanapBuhay collects, uses, stores, and protects information when you use the app.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...sections.map((section) => _buildSection(context, section)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, LegalSection section) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: AppTypography.headlineMedium.copyWith(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            section.body,
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  static const _termsSections = <LegalSection>[
    LegalSection('1. About HanapBuhay', 'HanapBuhay is a community marketplace that helps clients discover local service workers, request services, communicate about bookings, and manage service-related reports. Workers may publish service posts and respond to client booking requests.'),
    LegalSection('2. Eligibility and Accounts', 'You must provide truthful, current, and complete information when creating an account. You are responsible for maintaining the confidentiality of your account and for activity performed through it. You must be legally able to enter into these Terms. One person may not create accounts to impersonate another person or to evade a restriction.'),
    LegalSection('3. Client Responsibilities', 'Clients must provide accurate booking details, meet workers at the agreed location or communicate changes through the app, treat workers respectfully, and pay or otherwise honor the agreed service arrangement. Clients must not submit fraudulent requests, abusive content, or false reports.'),
    LegalSection('4. Worker Responsibilities', 'Workers must accurately describe their services, rates, availability, and skills. Workers must communicate professionally, honor accepted bookings, and provide only lawful and safe services. Verification documents and profile information must belong to the worker submitting them.'),
    LegalSection('5. Bookings and Cancellations', 'A booking request is subject to worker acceptance and the availability shown in the app. Users should communicate cancellations, rescheduling, delays, and service changes promptly. HanapBuhay may show booking history and status information, but the parties remain responsible for the service agreement between them.'),
    LegalSection('6. Communications and Content', 'You may submit profile information, service posts, messages, reviews, reports, photos, and other content. You grant HanapBuhay permission to host, display, process, and moderate that content as needed to operate, secure, and improve the service. Do not submit content that is unlawful, threatening, discriminatory, invasive of privacy, misleading, or infringing.'),
    LegalSection('7. Verification, Reviews, and Reports', 'Verification is an account-safety feature and is not a guarantee of skill, identity beyond the verification scope, service quality, or personal safety. Reviews and reports should be honest and based on genuine interactions. HanapBuhay may review, limit, remove, or investigate content and accounts that violate these Terms.'),
    LegalSection('8. Safety and Location Features', 'Use reasonable care when arranging or receiving services. Location and map features may use approximate or device-provided information and may be unavailable or inaccurate. Do not rely on the app as an emergency service. Contact local emergency services when immediate help is required.'),
    LegalSection('9. Prohibited Use', 'You may not misuse the app, interfere with its operation, access another account, collect information about users without permission, upload malicious code, manipulate reviews or bookings, conduct fraud, harass users, or use the service for unlawful activity.'),
    LegalSection('10. Suspension and Termination', 'We may suspend, restrict, or terminate access when reasonably necessary to protect users, investigate suspected abuse, comply with law, or enforce these Terms. You may stop using the app and request account closure through the available account-support process.'),
    LegalSection('11. Disclaimers and Liability', 'HanapBuhay provides a connection and communication platform. To the extent permitted by law, the service is provided without a promise that it will always be uninterrupted, error-free, or suitable for every purpose. HanapBuhay is not a party to the private service agreement between a client and worker and is not responsible for their conduct, work, payment, or property.'),
    LegalSection('12. Changes and Contact', 'We may update these Terms when the service, law, or safety practices change. We will provide notice through the app or other reasonable means for material changes. Questions or concerns can be raised through the in-app Help Center or Contact Support feature.'),
  ];

  static const _privacySections = <LegalSection>[
    LegalSection('1. Information We Collect', 'Depending on the features you use, HanapBuhay may collect your name, email address, mobile number, account role, barangay, profile photo, service categories, bio, rates, booking details, messages, reviews, reports, verification documents, device information, notification-token information, and technical logs. We collect information you provide, information created by your activity, and information returned by connected services.'),
    LegalSection('2. How We Use Information', 'We use information to create and secure accounts, verify email addresses and worker documents, display profiles and service posts, process bookings, support chat and notifications, provide maps and tracking features, handle reports and reviews, respond to support requests, prevent abuse, maintain records, improve the app, and comply with legal obligations.'),
    LegalSection('3. How Users See Information', 'Some profile and service information is visible to other users so clients can find workers and workers can understand booking requests. Booking participants may see information needed to arrange a service. Messages, reports, verification documents, and internal safety records are restricted to the people and administrators who need them for the relevant purpose, subject to law and operational requirements.'),
    LegalSection('4. Location Information', 'When a tracking feature is used and the required permission is granted, the app may process location information to show approximate or live movement to the relevant booking participants. You can control device location permissions. Location features may continue only as described by the active booking flow and may be stopped when tracking ends.'),
    LegalSection('5. Verification Documents', 'Workers may be asked to submit government identification, barangay certificates, selfies, or skill certificates. These documents are used for verification and safety review, access is limited, and they should not be shared with other users as public profile content. Do not submit documents that belong to another person.'),
    LegalSection('6. Sharing and Service Providers', 'We may share information with the other users involved in a relevant interaction, service providers that help operate hosting, authentication, storage, messaging, notifications, maps, analytics, or support, and authorities when required by law or needed to protect rights and safety. We do not sell personal information as a core part of the service.'),
    LegalSection('7. Retention and Security', 'We retain information for as long as needed for the purposes described here, including account operation, bookings, safety investigations, dispute handling, legal compliance, and legitimate business records. We use reasonable administrative, technical, and organizational safeguards, but no online service can guarantee absolute security.'),
    LegalSection('8. Your Choices and Rights', 'You may review or update available profile information through the app, control device permissions and notifications, and request account or data support through the Help Center. Subject to applicable law, you may ask about access, correction, deletion, or restriction of your personal information. Some records may need to be retained for safety, fraud prevention, dispute resolution, or legal obligations.'),
    LegalSection('9. Children', 'HanapBuhay is not intended for children who are not legally able to enter into service arrangements. Do not create an account or provide personal information if you do not meet the applicable age and legal requirements.'),
    LegalSection('10. Cookies and Technical Data', 'The app and connected services may process device identifiers, diagnostics, session information, and similar technical data to keep the service secure and functional. Platform settings and connected service policies may also apply.'),
    LegalSection('11. Philippine Privacy Law', 'HanapBuhay is designed with the Philippine Data Privacy Act of 2012 (Republic Act No. 10173) in mind. The specific rights, lawful bases, retention periods, responsible parties, and contact channels may be supplemented by operational privacy notices as the production backend and legal entity are finalized.'),
    LegalSection('12. Changes and Contact', 'We may update this Privacy Policy when our data practices, features, or legal obligations change. We will provide notice through the app or other reasonable means for material changes. For privacy questions or requests, use the in-app Help Center or Contact Support feature.'),
  ];
}

enum LegalDocumentType { terms, privacy }

class LegalSection {
  final String title;
  final String body;

  const LegalSection(this.title, this.body);
}
