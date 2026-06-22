import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/logic/attendance_warning_logic.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/providers/timetable_provider.dart';
import '../../core/providers/discipline_provider.dart';
import '../../core/widgets/app_ui.dart';
import '../dashboard/widgets/app_drawer.dart';
import '../notifications/widgets/notification_bell.dart';

Color _warningTierColor(int severity) {
  return switch (severity) {
    1 => Colors.orange,
    2 => const Color(0xFFB45309),
    3 => Colors.red,
    _ => const Color(0xFF0B3A8D),
  };
}

// Represents a unique subject+classGroup combo for the dropdown
typedef _ClassSelection = LecturerClassContext;

class DisciplineIssuesPage extends ConsumerStatefulWidget {
  const DisciplineIssuesPage({super.key});

  @override
  ConsumerState<DisciplineIssuesPage> createState() =>
      _DisciplineIssuesPageState();
}

class _DisciplineIssuesPageState extends ConsumerState<DisciplineIssuesPage> {
  String? _selectedClassKey;
  final _remarksControllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final controller in _remarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    final classGroupsAsync = ref.watch(classGroupsProvider);
    final studentsAsync = ref.watch(studentsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final attendanceRecordsAsync = ref.watch(allAttendanceRecordsProvider);
    final reportsAsync = ref.watch(disciplineReportsProvider);
    final lecturersAsync = ref.watch(lecturersProvider);
    final sessionsAsync = ref.watch(timetableSessionsProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
        title: const Text(
          'Discipline Issue',
          style: TextStyle(
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
                      user.role.name[0].toUpperCase() +
                          user.role.name.substring(1),
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
      drawer: const AppDrawer(currentPage: 'discipline'),
      body: classGroupsAsync.when(
        data: (classGroups) => studentsAsync.when(
          data: (students) => subjectsAsync.when(
            data: (subjects) => attendanceRecordsAsync.when(
              data: (allRecords) => reportsAsync.when(
                data: (disciplineReports) => lecturersAsync.when(
                  data: (lecturers) => sessionsAsync.when(
                    data: (sessions) {
                      // Find current lecturer
                      final currentLecturer = lecturers.firstWhere(
                        (l) => l.userUid == user.uid,
                        orElse: () => LecturerModel(
                          lecturerId: '',
                          userUid: '',
                          fullName: '',
                          email: '',
                          status: '',
                        ),
                      );

                      final mySessions = currentLecturer.lecturerId.isNotEmpty
                          ? sessions
                                .where(
                                  (s) =>
                                      s.lecturerId ==
                                      currentLecturer.lecturerId,
                                )
                                .toList()
                          : sessions;

                      final classSelections = buildLecturerClassContexts(
                        sessions: mySessions,
                        subjects: subjects,
                        classGroups: classGroups,
                      );

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 950;
                          final mainContent = _buildLecturerWarningPanel(
                            classSelections: classSelections,
                            students: students,
                            allRecords: allRecords,
                            reportedWarnings: disciplineReports,
                          );
                          final timelineSidebar = _buildTimelineSidebar(
                            disciplineReports,
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: SingleChildScrollView(
                                    child: mainContent,
                                  ),
                                ),
                                const VerticalDivider(
                                  width: 1,
                                  color: Color(0xFFE2E8F0),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: SingleChildScrollView(
                                    child: timelineSidebar,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  mainContent,
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Divider(
                                      height: 1,
                                      color: Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  timelineSidebar,
                                ],
                              ),
                            );
                          }
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) =>
                        Center(child: Text('Error loading sessions: $e')),
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) =>
                      Center(child: Text('Error loading lecturers: $e')),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    Center(child: Text('Error loading reports: $e')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Center(child: Text('Error loading attendance: $e')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading subjects: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading students: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading classes: $e')),
      ),
    );
  }

  Widget _buildLecturerWarningPanel({
    required List<_ClassSelection> classSelections,
    required List<StudentModel> students,
    required List<AttendanceRecordModel> allRecords,
    required List<DisciplineReportModel> reportedWarnings,
  }) {
    // Auto-select first if nothing selected yet
    if (_selectedClassKey == null && classSelections.isNotEmpty) {
      _selectedClassKey = classSelections.first.key;
    }

    final selected = classSelections.firstWhere(
      (c) => c.key == _selectedClassKey,
      orElse: () => classSelections.isNotEmpty
          ? classSelections.first
          : const _ClassSelection(
              classGroupId: '',
              subjectId: '',
              subjectCode: '',
              subjectName: '',
              classGroupName: '',
            ),
    );

    // Filter students by classGroupId
    final filteredStudents = students
        .where((s) => s.classGroupId == selected.classGroupId)
        .toList();

    // Filter records by BOTH classGroupId AND subjectId
    final classRecords = allRecords
        .where(
          (r) =>
              r.classGroupId == selected.classGroupId &&
              r.subjectId == selected.subjectId,
        )
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Warnings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Monitor student attendance rates and file warning reports to administration.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),

          // Class Selection Dropdown
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.class_outlined, color: Color(0xFF64748B)),
                  const SizedBox(width: 12),
                  const Text(
                    'Class:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedClassKey,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        items: classSelections.map((c) {
                          return DropdownMenuItem<String>(
                            value: c.key,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      c.subjectCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF172033),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        c.classGroupName,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0B3A8D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (c.subjectName.isNotEmpty)
                                  Text(
                                    c.subjectName.length > 45
                                        ? '${c.subjectName.substring(0, 45)}...'
                                        : c.subjectName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedClassKey = val;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_selectedClassKey == null)
            const Center(child: Text('Select a class to load students.'))
          else if (filteredStudents.isEmpty)
            const Center(
              child: Text('No students registered in this class group.'),
            )
          else
            _buildWarningTable(
              students: filteredStudents,
              classRecords: classRecords,
              reportedWarnings: reportedWarnings,
              subjectId: selected.subjectId,
              subjectCode: selected.subjectCode,
              subjectName: selected.subjectName,
            ),
        ],
      ),
    );
  }

  Widget _buildWarningTable({
    required List<StudentModel> students,
    required List<AttendanceRecordModel> classRecords,
    required List<DisciplineReportModel> reportedWarnings,
    required String subjectId,
    required String subjectCode,
    required String subjectName,
  }) {

    return AppCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rows = students.map((student) {
            final attendanceRate = calculateStudentAttendanceRate(
              studentId: student.studentId,
              classRecords: classRecords,
            );

            final warning = calculateWarningTier(attendanceRate);
            final String? buttonText = reportButtonLabel(warning);
            final level = warning.level;
            final target = warning.targetRole;
            final color = _warningTierColor(warning.severity);

            // Option C: skip student if this exact tier was dismissed
            final isCurrentTierDismissed = reportedWarnings.any((r) =>
                r.studentId == student.studentId &&
                r.subjectId == subjectId &&
                r.status == 'dismissed' &&
                r.warningLevel == level);
            if (isCurrentTierDismissed) return null;

            final isReported = reportedWarnings.any((r) =>
                r.studentId == student.studentId &&
                r.subjectId == subjectId &&
                r.warningLevel == level &&
                r.status != 'dismissed');

            if (constraints.maxWidth < 720) {
              return _buildWarningMobileCard(
                student: student,
                attendanceRate: attendanceRate,
                level: level,
                target: target,
                color: color,
                buttonText: buttonText,
                isReported: isReported,
                subjectId: subjectId,
                subjectCode: subjectCode,
                subjectName: subjectName,
              );
            }

            return TableRow(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              children: [
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF172033),
                          ),
                        ),
                        Text(
                          student.matricNo,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Text(
                      '${attendanceRate.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: attendanceRate >= 95.0
                            ? const Color(0xFF0B3A8D)
                            : (attendanceRate >= 90.0
                                  ? Colors.orange
                                  : Colors.red),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          level,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: buttonText == null
                        ? const SizedBox.shrink()
                        : (isReported
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: Color(0xFF0B3A8D),
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Reported',
                                        style: TextStyle(
                                          color: Color(0xFF0B3A8D),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () =>
                                          _confirmAndReportWarning(
                                            student: student,
                                            warningLevel: level,
                                            targetRole: target,
                                            rate: attendanceRate,
                                            subjectId: subjectId,
                                            subjectCode: subjectCode,
                                            subjectName: subjectName,
                                          ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: color,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: const Text(
                                        'Accept',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    OutlinedButton(
                                      onPressed: () => _showDeclineDialog(
                                        student: student,
                                        warningLevel: level,
                                        targetRole: target,
                                        rate: attendanceRate,
                                        subjectId: subjectId,
                                        subjectCode: subjectCode,
                                        subjectName: subjectName,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF64748B,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFCBD5E1),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                      ),
                                      child: const Text(
                                        'Decline',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                )),
                  ),
                ),
              ],
            );
          }).whereType<Object>().toList();

          if (constraints.maxWidth < 720) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    rows[i] as Widget,
                  ],
                ],
              ),
            );
          }

          return Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                children: [
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Text(
                        'Student',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Text(
                        'Attendance Rate',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Text(
                        'Warning Remark',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Text(
                        'Action',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              ...rows.cast<TableRow>(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWarningMobileCard({
    required StudentModel student,
    required double attendanceRate,
    required String level,
    required String target,
    required Color color,
    required String? buttonText,
    required bool isReported,
    required String subjectId,
    required String subjectCode,
    required String subjectName,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student.fullName,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            student.matricNo,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppBadge(
                label: '${attendanceRate.toStringAsFixed(1)}%',
                color: attendanceRate >= 95.0
                    ? AppColors.success
                    : (attendanceRate >= 90.0
                          ? AppColors.warning
                          : AppColors.danger),
              ),
              AppBadge(label: level, color: color),
            ],
          ),
          if (buttonText != null) ...[
            const SizedBox(height: 14),
            if (isReported)
              const AppBadge(label: 'Reported', color: AppColors.primary)
            else
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      onPressed: () => _confirmAndReportWarning(
                        student: student,
                        warningLevel: level,
                        targetRole: target,
                        rate: attendanceRate,
                        subjectId: subjectId,
                        subjectCode: subjectCode,
                        subjectName: subjectName,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showDeclineDialog(
                        student: student,
                        warningLevel: level,
                        targetRole: target,
                        rate: attendanceRate,
                        subjectId: subjectId,
                        subjectCode: subjectCode,
                        subjectName: subjectName,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  void _showDeclineDialog({
    required StudentModel student,
    required String warningLevel,
    required String targetRole,
    required double rate,
    required String subjectId,
    required String subjectCode,
    required String subjectName,
  }) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.cancel_outlined, color: Color(0xFF64748B), size: 28),
                  SizedBox(width: 12),
                  Text('Decline Warning'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Declining $warningLevel for ${student.fullName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The student will be hidden from the warning list unless their rate drops further.',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reason (optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'e.g. Student has medical documentation...',
                      contentPadding: const EdgeInsets.all(12),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF475569)),
                  ),
                ),
                ElevatedButton(
                   onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          // Capture dialog context before the async gap.
                          final dialogContext = context;
                          final messenger = ScaffoldMessenger.of(dialogContext);
                          final nav = Navigator.of(dialogContext);
                          try {
                            final user = ref.read(authProvider);
                            await ref
                                .read(disciplineServiceProvider)
                                .dismissReport(
                                  studentId: student.studentId,
                                  studentName: student.fullName,
                                  studentMatric: student.matricNo,
                                  classGroupId: student.classGroupId,
                                  subjectId: subjectId,
                                  subjectCode: subjectCode,
                                  subjectName: subjectName,
                                  warningLevel: warningLevel,
                                  targetRole: targetRole,
                                  attendanceRate: rate,
                                  reportedByUid: user?.uid ?? 'unknown',
                                  reportedByName:
                                      user?.displayName ?? 'Lecturer',
                                  dismissReason: reasonController.text.trim(),
                                );
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Warning declined for ${student.fullName}',
                                ),
                              ),
                            );
                            nav.pop();
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64748B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Confirm Decline'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmAndReportWarning({
    required StudentModel student,
    required String warningLevel,
    required String targetRole,
    required double rate,
    required String subjectId,
    required String subjectCode,
    required String subjectName,
  }) {
    final controller = _remarksControllers.putIfAbsent(
      '${student.studentId}_$warningLevel',
      () => TextEditingController(
        text:
            'Student ${student.fullName} (${student.matricNo}) has an attendance rate of ${rate.toStringAsFixed(1)}%.',
      ),
    );

    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text('File Warning Report'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Are you sure you want to submit a $warningLevel report for ${student.fullName}?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subject: $subjectCode',
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'This warning will be routed to the $targetRole.',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Remarks',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(12),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                OutlinedButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF475569)),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          setDialogState(() => isSubmitting = true);
                          try {
                            final user = ref.read(authProvider);
                            await ref
                                .read(disciplineServiceProvider)
                                .createReport(
                                  studentId: student.studentId,
                                  studentName: student.fullName,
                                  studentMatric: student.matricNo,
                                  classGroupId: student.classGroupId,
                                  subjectId: subjectId,
                                  subjectCode: subjectCode,
                                  subjectName: subjectName,
                                  warningLevel: warningLevel,
                                  targetRole: targetRole,
                                  attendanceRate: rate,
                                  remarks: controller.text.trim(),
                                  reportedByUid: user?.uid ?? 'unknown',
                                  reportedByName:
                                      user?.displayName ?? 'Lecturer',
                                );
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Filed $warningLevel for ${student.fullName}',
                                ),
                              ),
                            );
                            navigator.pop();
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (!mounted) return;
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit report'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTimelineSidebar(List<DisciplineReportModel> reports) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Case timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 24),
          if (reports.isEmpty)
            const Text(
              'No warning reports filed yet.',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[index];
                final isLast = index == reports.length - 1;
                return _buildTimelineItem(report, isLast);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(DisciplineReportModel report, bool isLast) {
    Color dotColor = Colors.grey;
    if (report.warningLevel.toLowerCase().contains('first')) {
      dotColor = Colors.orange;
    } else if (report.warningLevel.toLowerCase().contains('second')) {
      dotColor = Colors.amber[700]!;
    } else if (report.warningLevel.toLowerCase().contains('third')) {
      dotColor = Colors.red;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: isLast
                    ? const SizedBox(height: 16)
                    : Container(
                        width: 1.5,
                        color: const Color(0xFFE2E8F0),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                      ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        report.incidentDate,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: report.status == 'acknowledged'
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          report.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: report.status == 'acknowledged'
                                ? const Color(0xFF065F46)
                                : const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${report.warningLevel} · ${report.studentName}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172033),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (report.subjectCode.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Subject: ${report.subjectCode}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    'Routed to: ${report.targetRole} (${report.attendanceRate.toStringAsFixed(1)}%)',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.remarks,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
