import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/firestore/firestore_schema.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/discipline_provider.dart';
import '../../core/widgets/app_ui.dart';
import 'widgets/app_drawer.dart';
import 'widgets/dashboard_case_review_preview.dart';
import 'widgets/warning_case_list_table.dart';
import '../notifications/widgets/notification_bell.dart';

class StaffCaseReviewPage extends ConsumerWidget {
  const StaffCaseReviewPage({super.key});

  String _warningTier(UserRole role) {
    return warningTierForRole(role) ?? 'First Warning';
  }

  String _subtitle(UserRole role) {
    return switch (role) {
      UserRole.hod =>
        'Review and acknowledge first-warning cases at your tier.',
      UserRole.headOfProgram =>
        'Review and acknowledge second-warning cases at your tier.',
      UserRole.deputyAcademicDean =>
        'Review and acknowledge third-warning cases at your tier.',
      _ => 'Review warning cases routed to your tier.',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final role = user.role;
    final roleLabel = roleDisplayLabel(role);
    final warningTier = _warningTier(role);
    final allReportsAsync = ref.watch(disciplineReportsProvider);

    final initials = user.displayName.isNotEmpty
        ? user.displayName
              .split(' ')
              .map((n) => n[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'U';

    return AppShell(
      title: roleLabel,
      drawer: const AppDrawer(currentPage: 'case_review'),
      actions: [
        const NotificationBell(),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172033),
                    ),
                  ),
                  Text(
                    roleLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE2E8F0),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      body: allReportsAsync.when(
        loading: () => const AppLoadingState(label: 'Loading cases'),
        error: (e, _) => Center(child: Text('Error loading cases: $e')),
        data: (allReports) {
          final tierReports = tierReportsForRole(allReports, warningTier);
          final pendingCount = tierReports
              .where((r) => r.status == 'reported')
              .length;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AppPageHeader(title: 'Case Review', subtitle: _subtitle(role)),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF475569),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cases to review ($warningTier)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  if (pendingCount > 0)
                    AppBadge(
                      label: '$pendingCount pending',
                      color: AppColors.warning,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (tierReports.isEmpty)
                _buildEmptyState()
              else
                WarningCaseListTable(reports: tierReports),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.check_circle_outline_outlined,
      title: 'All clear',
      message: 'No warning reports are currently pending action at your tier.',
    );
  }
}
