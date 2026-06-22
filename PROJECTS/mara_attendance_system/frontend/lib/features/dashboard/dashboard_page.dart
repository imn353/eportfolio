import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/utils/sign_out_dialog.dart';

import '../../core/firestore/firestore_schema.dart';
import 'admin_dashboard_page.dart';
import 'lecturer_dashboard_page.dart';
import 'staff_alert_dashboard.dart';
import '../notifications/widgets/notification_bell.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      // Fallback if accessed without a user
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user.role == UserRole.admin) {
      return const AdminDashboardPage();
    }

    if (user.role == UserRole.lecturer) {
      return const LecturerDashboardPage();
    }

    if (user.role == UserRole.hod ||
        user.role == UserRole.headOfProgram ||
        user.role == UserRole.deputyAcademicDean) {
      return const StaffAlertDashboard();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showSignOutDialog(context, ref),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome,',
              style: TextStyle(fontSize: 20, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.role.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
