import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_ui.dart';
import '../../../core/firestore/firestore_schema.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/timetable_provider.dart';
import '../../../core/providers/user_management_provider.dart';
import '../../admin/admin_report_page.dart';
import '../../admin/manage_classes_page.dart';
import '../../admin/manage_users_page.dart';
import '../../hod/hod_report_page.dart';
import '../../lecturer/lecturer_report_page.dart';
import '../../lecturer/replacement_class_list_page.dart';
import '../../../core/utils/sign_out_dialog.dart';
import '../../discipline/discipline_page.dart';
import '../admin_timetable_page.dart';
import '../dashboard_page.dart';
import '../lecturer_schedule_page.dart';
import '../staff_case_review_page.dart';
import 'dashboard_case_review_preview.dart';

class AppDrawer extends ConsumerWidget {
  final String currentPage;

  const AppDrawer({super.key, required this.currentPage});

  Widget _getReportPage(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return const AdminReportPage();
      case UserRole.lecturer:
        return const LecturerReportPage();
      case UserRole.hod:
      case UserRole.headOfProgram:
      case UserRole.deputyAcademicDean:
        return const HodReportPage();
    }
  }

  void _navigateTo(BuildContext context, Widget page, String pageKey) {
    if (currentPage == pageKey) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => page),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Drawer(child: Center(child: CircularProgressIndicator()));
    }

    final roleLabel = switch (user.role) {
      UserRole.admin => 'Admin',
      UserRole.lecturer => 'Lecturer',
      UserRole.hod => 'HOD',
      UserRole.headOfProgram => 'Head of Program',
      UserRole.deputyAcademicDean => 'Deputy Academic Dean',
    };

    final isStaffRestricted =
        user.role == UserRole.headOfProgram ||
        user.role == UserRole.deputyAcademicDean;

    final showMySchedule = ref.watch(currentUserHasMyScheduleProvider);
    final pendingCount = user.role == UserRole.admin
        ? ref
              .watch(pendingUsersCountProvider)
              .when(data: (n) => n, loading: () => 0, error: (_, _) => 0)
        : 0;

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/Mara Logo.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'MARA Attendance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppBadge(label: roleLabel, color: AppColors.primary),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    title: 'Dashboard',
                    isActive: currentPage == 'dashboard',
                    onTap: () => _navigateTo(
                      context,
                      const DashboardPage(),
                      'dashboard',
                    ),
                  ),

                  if (user.role == UserRole.admin)
                    _DrawerItem(
                      icon: Icons.table_chart_outlined,
                      activeIcon: Icons.table_chart,
                      title: 'Timetable',
                      isActive: currentPage == 'timetable',
                      onTap: () => _navigateTo(
                        context,
                        const AdminTimetablePage(),
                        'timetable',
                      ),
                    ),
                  if (user.role == UserRole.admin)
                    _DrawerItem(
                      icon: Icons.school_outlined,
                      activeIcon: Icons.school,
                      title: 'Manage Classes',
                      isActive: currentPage == 'manage_classes',
                      onTap: () => _navigateTo(
                        context,
                        const ManageClassesPage(),
                        'manage_classes',
                      ),
                    ),
                  if (user.role == UserRole.admin)
                    _DrawerItem(
                      icon: Icons.manage_accounts_outlined,
                      activeIcon: Icons.manage_accounts,
                      title: 'Manage Users',
                      isActive: currentPage == 'manage_users',
                      badgeCount: pendingCount,
                      onTap: () => _navigateTo(
                        context,
                        const ManageUsersPage(),
                        'manage_users',
                      ),
                    ),
                  if (showMySchedule)
                    _DrawerItem(
                      icon: Icons.calendar_month_outlined,
                      activeIcon: Icons.calendar_month,
                      title: 'My Schedule',
                      isActive: currentPage == 'schedule',
                      onTap: () => _navigateTo(
                        context,
                        const LecturerSchedulePage(),
                        'schedule',
                      ),
                    ),
                  if (isStaffCaseReviewer(user.role))
                    _DrawerItem(
                      icon: Icons.assignment_outlined,
                      activeIcon: Icons.assignment,
                      title: 'Case Review',
                      isActive: currentPage == 'case_review',
                      onTap: () => _navigateTo(
                        context,
                        const StaffCaseReviewPage(),
                        'case_review',
                      ),
                    ),
                  if (!isStaffRestricted) ...[
                    _DrawerItem(
                      icon: Icons.bar_chart_outlined,
                      activeIcon: Icons.bar_chart,
                      title: 'Attendance Reports',
                      isActive: currentPage == 'reports',
                      onTap: () => _navigateTo(
                        context,
                        _getReportPage(user.role),
                        'reports',
                      ),
                    ),
                    _DrawerItem(
                      icon: Icons.warning_amber_outlined,
                      activeIcon: Icons.warning_amber,
                      title: 'Discipline Issues',
                      isActive: currentPage == 'discipline',
                      onTap: () => _navigateTo(
                        context,
                        const DisciplineIssuesPage(),
                        'discipline',
                      ),
                    ),
                    _DrawerItem(
                      icon: Icons.swap_horiz_outlined,
                      activeIcon: Icons.swap_horiz,
                      title: 'Replacement Classes',
                      isActive: currentPage == 'replacement',
                      onTap: () => _navigateTo(
                        context,
                        const ReplacementClassListPage(),
                        'replacement',
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _DrawerItem(
                icon: Icons.logout_rounded,
                activeIcon: Icons.logout_rounded,
                title: 'Sign Out',
                isActive: false,
                onTap: () => showSignOutDialog(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String title;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.activeIcon,
    required this.title,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.primary;
    const inactiveColor = AppColors.textMuted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: activeColor.withValues(alpha: 0.05),
        highlightColor: activeColor.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(
            color: isActive
                ? activeColor.withValues(alpha: 0.11)
                : Colors.white.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                      color: isActive ? activeColor : AppColors.text,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
