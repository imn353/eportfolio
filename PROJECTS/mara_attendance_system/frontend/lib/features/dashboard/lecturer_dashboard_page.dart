import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/lecturer_warnings_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/providers/report_provider.dart';
import '../discipline/discipline_page.dart';
import 'lecturer_schedule_page.dart';
import 'widgets/app_drawer.dart';
import 'widgets/dashboard_attendance_warnings_section.dart';
import 'widgets/dashboard_section_header.dart';
import 'widgets/dashboard_today_schedule_section.dart';
import 'widgets/summary_stat_card.dart';
import '../notifications/widgets/notification_bell.dart';
import '../../core/providers/notification_provider.dart';

class LecturerDashboardPage extends ConsumerWidget {
  const LecturerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final summaryAsync = ref.watch(lecturerDashboardSummaryProvider);
    final warningsAsync = ref.watch(lecturerWarningsProvider);
    final todaySessionsAsync = ref.watch(lecturerTodaySessionsProvider);
    final recordsAsync = ref.watch(lecturerReportsProvider);
    final subjects = ref.watch(subjectsProvider).value ?? [];

    // Trigger attendance reminders generation when data is available
    if (todaySessionsAsync is AsyncData && recordsAsync is AsyncData) {
      final todaySessions = todaySessionsAsync.value ?? [];
      final records = recordsAsync.value ?? [];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(notificationServiceProvider)
            .generateAttendanceReminders(
              userUid: user.uid,
              todaySessions: todaySessions,
              records: records,
              subjects: subjects,
            );
      });
    }

    void openDisciplinePage() {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DisciplineIssuesPage()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF172033)),
        actions: const [NotificationBell()],
      ),
      drawer: const AppDrawer(currentPage: 'dashboard'),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Unable to load dashboard: $e')),
        data: (summary) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              DashboardWelcomeHeader(
                displayName: user.displayName,
                subtitle:
                    'Your classes today, attendance progress, and warnings to file.',
              ),
              const SizedBox(height: 24),
              SummaryStatGrid(
                items: [
                  SummaryStatItem(
                    title: "Today's Classes",
                    value: summary.sessionsToday.toString(),
                    color: const Color(0xFF0B3A8D),
                    icon: Icons.calendar_today_outlined,
                  ),
                  SummaryStatItem(
                    title: 'Submitted Today',
                    value: summary.submittedToday.toString(),
                    color: Colors.green,
                    icon: Icons.check_circle_outline,
                  ),
                  SummaryStatItem(
                    title: 'Pending Attendance',
                    value: summary.pendingToday.toString(),
                    color: Colors.orange,
                    icon: Icons.pending_actions_outlined,
                  ),
                  SummaryStatItem(
                    title: 'Avg Attendance',
                    value:
                        '${summary.averageAttendancePercent.toStringAsFixed(1)}%',
                    color: const Color(0xFF2563EB),
                    icon: Icons.analytics_outlined,
                  ),
                  SummaryStatItem(
                    title: 'Students to Report',
                    value: summary.openIssuesCount.toString(),
                    color: Colors.redAccent,
                    icon: Icons.warning_amber_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const DashboardTodayScheduleSection(),
              const SizedBox(height: 28),
              warningsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error loading warnings: $e'),
                data: (warnings) {
                  return DashboardAttendanceWarningsSection(
                    data: warnings,
                    onViewAll: openDisciplinePage,
                  );
                },
              ),
              const SizedBox(height: 28),
              _QuickActionCard(
                icon: Icons.calendar_month_outlined,
                title: 'View Weekly Schedule',
                description:
                    'See your full timetable grouped by day of the week.',
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LecturerSchedulePage(),
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
