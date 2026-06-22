import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/report_provider.dart';
import '../notifications/widgets/notification_bell.dart';
import 'admin_report_page.dart';

class AdminAuditLogPage extends ConsumerWidget {
  const AdminAuditLogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(filteredAdminRecordsWithFiltersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Full Audit Log',
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
      body: SafeArea(
        child: reportState.when(
          data: (records) {
            if (records.isEmpty) {
              return const Center(
                child: Text(
                  'No attendance records yet.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AdminAuditLogCard(
                    subject: record.subjectId,
                    date: record.attendanceDate,
                    totalStudents: record.summary.totalStudents,
                    present: record.summary.presentCount,
                    lateCount: record.summary.lateCount,
                    absent: record.summary.absentCount,
                    mc: record.summary.mcCount,
                    ck: record.summary.ckCount,
                    percentage: record.summary.attendancePercentage,
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => const Center(
            child: Text(
              'Error loading logs.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }
}
