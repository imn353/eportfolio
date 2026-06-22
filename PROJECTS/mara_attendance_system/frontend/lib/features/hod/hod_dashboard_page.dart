import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../dashboard/widgets/app_drawer.dart';
import 'hod_report_page.dart';
import '../notifications/widgets/notification_bell.dart';

class HodDashboardPage extends ConsumerWidget {
  const HodDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final classGroupsAsync = ref.watch(classGroupsProvider);
    final lecturersAsync = ref.watch(lecturersProvider);
    final studentsAsync = ref.watch(studentsProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final classesCount = classGroupsAsync.when(
      data: (list) => list.length.toString(),
      loading: () => '...',
      error: (error, stackTrace) => '0',
    );

    final lecturersCount = lecturersAsync.when(
      data: (list) => list.length.toString(),
      loading: () => '...',
      error: (error, stackTrace) => '0',
    );

    final studentsCount = studentsAsync.when(
      data: (list) => list.length.toString(),
      loading: () => '...',
      error: (error, stackTrace) => '0',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'HOD Dashboard',
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Welcome Section
            Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: 16,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.displayName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Stats Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Department Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatColumn(
                        'Classes',
                        classesCount,
                        const Color(0xFF0B3A8D),
                      ),
                      _buildStatDivider(),
                      _buildStatColumn(
                        'Lecturers',
                        lecturersCount,
                        const Color(0xFF0B3A8D),
                      ),
                      _buildStatDivider(),
                      _buildStatColumn(
                        'Students',
                        studentsCount,
                        const Color(0xFF0B3A8D),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Navigation / Action Card
            InkWell(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HodReportPage(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B3A8D), Color(0xFF082A68)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B3A8D).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
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
                      child: const Icon(
                        Icons.analytics,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'View Attendance Reports',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Check attendance rates and metrics by class group or sessions.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFDBEAFE),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(height: 36, width: 1, color: const Color(0xFFE2E8F0));
  }
}
