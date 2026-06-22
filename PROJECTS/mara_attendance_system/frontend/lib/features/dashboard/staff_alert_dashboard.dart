import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_schema.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/discipline_provider.dart';
import '../../core/providers/timetable_provider.dart';
import '../hod/hod_report_page.dart';
import 'staff_case_review_page.dart';
import 'widgets/app_drawer.dart';
import 'widgets/dashboard_case_review_preview.dart';
import 'widgets/dashboard_section_header.dart';
import 'widgets/dashboard_today_schedule_section.dart';
import 'widgets/summary_stat_card.dart';
import '../notifications/widgets/notification_bell.dart';

class StaffAlertDashboard extends ConsumerWidget {
  const StaffAlertDashboard({super.key});

  String _dashboardTitle(UserRole role) {
    return switch (role) {
      UserRole.hod => 'HOD Dashboard',
      UserRole.headOfProgram => 'Head of Program Dashboard',
      UserRole.deputyAcademicDean => 'Deputy Academic Dean Dashboard',
      _ => 'Staff Dashboard',
    };
  }

  String _warningTier(UserRole role) {
    return warningTierForRole(role) ?? 'First Warning';
  }

  String _subtitle(UserRole role) {
    return switch (role) {
      UserRole.hod =>
        'Review department attendance and acknowledge first-warning cases.',
      UserRole.headOfProgram =>
        'Acknowledge second-warning cases routed to your tier.',
      UserRole.deputyAcademicDean =>
        'Acknowledge third-warning cases routed to your tier.',
      _ => 'Manage warning alerts routed to your tier.',
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
    final dashboardTitle = _dashboardTitle(role);

    final isHod = role == UserRole.hod;
    final hasAssignedTimetable = ref.watch(currentUserHasMyScheduleProvider);

    final deptSummaryAsync = ref.watch(staffDepartmentSummaryProvider);
    final alertSummaryAsync = ref.watch(staffAlertSummaryProvider);
    final allReportsAsync = ref.watch(disciplineReportsProvider);

    final initials = user.displayName.isNotEmpty
        ? user.displayName
              .split(' ')
              .map((n) => n[0])
              .take(2)
              .join()
              .toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          roleLabel,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF172033)),
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
      ),
      drawer: const AppDrawer(currentPage: 'dashboard'),
      body: allReportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading warnings: $e')),
        data: (allReports) {
          if (isHod && deptSummaryAsync is AsyncLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (isHod && deptSummaryAsync is AsyncError) {
            return Center(
              child: Text(
                'Unable to load dashboard: ${deptSummaryAsync.error}',
              ),
            );
          }

          final deptSummary = isHod ? deptSummaryAsync.value : null;
          final tierReports = tierReportsForRole(allReports, warningTier);

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                dashboardTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _subtitle(role),
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              const DashboardTodayScheduleSection(
                requireAssignedTimetable: true,
              ),
              if (hasAssignedTimetable) const SizedBox(height: 28),

              if (isHod && deptSummary != null) ...[
                const DashboardSectionHeader(
                  icon: Icons.analytics_outlined,
                  title: 'Department Attendance Summary',
                ),
                const SizedBox(height: 12),
                SummaryStatGrid(
                  items: [
                    SummaryStatItem(
                      title: 'Dept Average',
                      value:
                          '${deptSummary.departmentAveragePercent.toStringAsFixed(1)}%',
                      color:
                          deptSummary.departmentAveragePercent >=
                              AttendanceRules.warningThresholdPercentage
                          ? const Color(0xFF0B3A8D)
                          : Colors.redAccent,
                      icon: Icons.analytics_outlined,
                    ),
                    SummaryStatItem(
                      title: 'At-Risk Classes',
                      value: deptSummary.atRiskCohortsCount.toString(),
                      color: Colors.orange,
                      icon: Icons.warning_amber_outlined,
                    ),
                    SummaryStatItem(
                      title: 'Total Absences',
                      value: deptSummary.totalAbsences.toString(),
                      color: Colors.redAccent,
                      icon: Icons.person_off_outlined,
                    ),
                    SummaryStatItem(
                      title: 'Class Groups',
                      value: deptSummary.classGroupsCount.toString(),
                      color: const Color(0xFF2563EB),
                      icon: Icons.groups_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              alertSummaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
                data: (alertSummary) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DashboardSectionHeader(
                        icon: Icons.notifications_active_outlined,
                        title: 'Warning Alerts at Your Tier',
                      ),
                      const SizedBox(height: 12),
                      SummaryStatGrid(
                        items: [
                          SummaryStatItem(
                            title: 'Total Alerts',
                            value: alertSummary.totalAlerts.toString(),
                            color: const Color(0xFF0B3A8D),
                            icon: Icons.notifications_active_outlined,
                          ),
                          SummaryStatItem(
                            title: 'Pending Action',
                            value: alertSummary.pendingAction.toString(),
                            color: Colors.orange,
                            icon: Icons.pending_actions_outlined,
                          ),
                          SummaryStatItem(
                            title: 'Acknowledged',
                            value: alertSummary.acknowledged.toString(),
                            color: Colors.green,
                            icon: Icons.assignment_turned_in_outlined,
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              if (isHod) ...[
                _QuickActionCard(
                  icon: Icons.bar_chart_outlined,
                  title: 'View Department Reports',
                  description:
                      'Detailed attendance rates and trends by class group.',
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const HodReportPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
              ],

              DashboardCaseReviewPreview(
                warningTier: warningTier,
                tierReports: tierReports,
                onViewAll: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const StaffCaseReviewPage(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0B3A8D), Color(0xFF082A68)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFDBEAFE),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
