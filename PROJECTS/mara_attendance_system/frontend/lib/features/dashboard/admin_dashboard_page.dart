import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/firestore/firestore_models.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/providers/replacement_session_provider.dart';
import '../admin/manage_users_page.dart';
import '../admin/widgets/pending_approval_card.dart';
import '../discipline/discipline_page.dart';
import '../lecturer/replacement_class_list_page.dart';
import 'admin_timetable_page.dart';
import '../notifications/widgets/notification_bell.dart';
import 'widgets/app_drawer.dart';
import 'widgets/dashboard_recent_issues_section.dart';
import 'widgets/dashboard_section_header.dart';
import 'widgets/summary_stat_card.dart';
import '../../core/widgets/app_ui.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final summaryAsync = ref.watch(adminDashboardSummaryProvider);
    final issuesAsync = ref.watch(adminRecentIssuesProvider);
    final pendingApprovalsAsync = ref.watch(pendingReplacementSessionsProvider);
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final rooms = ref.watch(roomsProvider).value ?? [];
    final timeSlots = ref.watch(timeSlotsProvider).value ?? [];
    final lecturers = ref.watch(lecturersProvider).value ?? [];
    final classGroups = ref.watch(classGroupsProvider).value ?? [];

    return AppShell(
      title: 'Dashboard',
      drawer: const AppDrawer(currentPage: 'dashboard'),
      actions: const [NotificationBell()],
      body: summaryAsync.when(
        loading: () => const AppLoadingState(label: 'Loading dashboard'),
        error: (e, _) => Center(child: Text('Unable to load dashboard: $e')),
        data: (summary) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminDashboardSummaryProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                DashboardWelcomeHeader(
                  displayName: user.displayName,
                  subtitle: 'System-wide attendance overview and alerts.',
                ),
                const SizedBox(height: 24),
                SummaryStatGrid(
                  items: [
                    SummaryStatItem(
                      title: "Today's Sessions",
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
                      title: 'Open Issues',
                      value: summary.openIssuesCount.toString(),
                      color: Colors.redAccent,
                      icon: Icons.warning_amber_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Pending replacement approvals section
                pendingApprovalsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => const SizedBox.shrink(),
                  data: (pending) {
                    if (pending.isEmpty) return const SizedBox.shrink();
                    return _PendingApprovalsSection(
                      pending: pending,
                      subjects: subjects,
                      lecturers: lecturers,
                      rooms: rooms,
                      timeSlots: timeSlots,
                      classGroups: classGroups,
                      reviewerUid: user.uid,
                    );
                  },
                ),
                const SizedBox(height: 28),
                issuesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, _) => Text('Error loading issues: $e'),
                  data: (issues) {
                    return DashboardRecentIssuesSection(
                      issues: issues,
                      onViewAll: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const DisciplineIssuesPage(),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 28),
                _QuickActionCard(
                  icon: Icons.table_chart_outlined,
                  title: 'Manage Timetable',
                  description:
                      'View, create, edit, or import timetable sessions.',
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const AdminTimetablePage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _QuickActionCard(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Manage Users',
                  description:
                      'View users and change their roles (e.g. promote a lecturer).',
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const ManageUsersPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pending Approvals Section (dashboard preview — at most 3 cards)
// ---------------------------------------------------------------------------

class _PendingApprovalsSection extends ConsumerWidget {
  static const int _previewLimit = 3;

  final List<ReplacementSessionModel> pending;
  final List<SubjectModel> subjects;
  final List<LecturerModel> lecturers;
  final List<RoomModel> rooms;
  final List<TimeSlotModel> timeSlots;
  final List<ClassGroupModel> classGroups;
  final String reviewerUid;

  const _PendingApprovalsSection({
    required this.pending,
    required this.subjects,
    required this.lecturers,
    required this.rooms,
    required this.timeSlots,
    required this.classGroups,
    required this.reviewerUid,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = pending.length;
    final visible = total > _previewLimit
        ? pending.sublist(0, _previewLimit)
        : pending;
    final hasOverflow = total > _previewLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header: title + count badge + (optional) View all link
        Row(
          children: [
            const Text(
              'Replacement Approvals',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$total pending',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            const Spacer(),
            if (hasOverflow)
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ReplacementClassListPage(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0B3A8D),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ...visible.map(
          (session) => PendingApprovalCard(
            session: session,
            subjects: subjects,
            lecturers: lecturers,
            rooms: rooms,
            timeSlots: timeSlots,
            classGroups: classGroups,
            reviewerUid: reviewerUid,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
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
      ),
    );
  }
}
