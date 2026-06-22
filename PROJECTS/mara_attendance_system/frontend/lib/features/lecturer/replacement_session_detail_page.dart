import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_models.dart';
import '../../core/logic/attendance_window_logic.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../notifications/widgets/notification_bell.dart';
import 'attendance_marking_page.dart';

/// Detail page for an approved replacement session.
///
/// Attendance is marked using a synthetic [TimetableSessionModel] constructed
/// from the replacement session's fields — this allows [AttendanceMarkingPage]
/// to work without modification. The attendance record key is:
///   `{replacementSessionId}_{replacementDate}`
class ReplacementSessionDetailPage extends ConsumerWidget {
  final ReplacementSessionModel session;
  final SubjectModel subject;
  final RoomModel room;
  final String startTime;
  final String endTime;

  const ReplacementSessionDetailPage({
    super.key,
    required this.session,
    required this.subject,
    required this.room,
    required this.startTime,
    required this.endTime,
  });

  String _formatDisplayDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    try {
      final date = DateTime.parse(dateStr);
      final m = date.month;
      return '${days[date.weekday - 1]}, ${parts[2]} ${m >= 1 && m <= 12 ? months[m - 1] : parts[1]} ${parts[0]}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final studentsState = ref.watch(studentsProvider);

    // Use replacementSessionId + replacementDate as the attendance record key
    // (consistent with FirestoreDocumentIds.attendanceRecord)
    final recordKey =
        '${session.replacementSessionId}|${session.replacementDate}';
    final recordAsync = ref.watch(attendanceRecordProvider(recordKey));

    // Synthetic TimetableSessionModel so AttendanceMarkingPage works unchanged
    final syntheticSession = TimetableSessionModel(
      timetableSessionId: session.replacementSessionId,
      dayOfWeek: DateTime.parse(session.replacementDate).weekday,
      classGroupId: session.classGroupId,
      subjectId: session.subjectId,
      lecturerId: session.lecturerId,
      roomId: session.roomId,
      startSlotId: session.startSlotId,
      endSlotId: session.endSlotId,
      status: 'active',
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '${subject.code} — Replacement Class',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF172033),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF172033)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [NotificationBell()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey.withValues(alpha: 0.1),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session info card
            _buildInfoCard(context, theme),
            const SizedBox(height: 28),

            // Students list
            studentsState.when(
              data: (students) {
                final classStudents =
                    students
                        .where((s) => s.classGroupId == session.classGroupId)
                        .toList()
                      ..sort(
                        (a, b) => a.fullName.toLowerCase().compareTo(
                          b.fullName.toLowerCase(),
                        ),
                      );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ENROLLED STUDENTS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${classStudents.length} Students',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    classStudents.isEmpty
                        ? _buildEmptyStudentsState()
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: classStudents.length,
                            itemBuilder: (context, index) => _buildStudentCard(
                              context,
                              theme,
                              classStudents[index],
                              index + 1,
                            ),
                          ),
                  ],
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Error loading students: $err',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
        ),
        child: SafeArea(
          child: recordAsync.when(
            data: (record) {
              final buttonColor = record == null
                  ? theme.colorScheme.primary
                  : record.status == 'draft'
                  ? const Color(0xFFF59E0B)
                  : const Color(0xFF10B981);
              final buttonIcon = record == null
                  ? Icons.edit_calendar
                  : record.status == 'draft'
                  ? Icons.play_arrow_rounded
                  : Icons.check_circle_outline;
              final buttonText = record == null
                  ? 'Mark Attendance'
                  : record.status == 'draft'
                  ? 'Resume Draft Attendance'
                  : 'View Attendance (Submitted)';

              final isSubmitted = record?.status == 'submitted';
              final windowClosed = isAttendanceMarkingWindowClosed(
                attendanceDate: session.replacementDate,
                endTime: endTime,
              );
              final windowOpen = isAttendanceMarkingWindowOpen(
                attendanceDate: session.replacementDate,
                startTime: startTime,
              );
              final canOpenAttendance = isSubmitted || (!windowClosed && windowOpen);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (record != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              record.status == 'draft'
                                  ? Icons.pending_actions
                                  : Icons.verified_user,
                              size: 16,
                              color: record.status == 'draft'
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF059669),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              record.status == 'draft'
                                  ? 'Attendance Draft in Progress'
                                  : 'Attendance Submitted',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: record.status == 'draft'
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${record.summary.presentCount + record.summary.lateCount}/${record.summary.totalStudents} Present (${record.summary.attendancePercentage.toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: record.status == 'draft'
                                ? const Color(0xFFD97706)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (windowClosed && !isSubmitted) ...[
                    Text(
                      attendanceWindowClosedMessage(endTime),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (!windowClosed && !windowOpen && !isSubmitted) ...[
                    Text(
                      attendanceWindowNotYetOpenMessage(startTime),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: buttonColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFCBD5E1),
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: canOpenAttendance
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => AttendanceMarkingPage(
                                    session: syntheticSession,
                                    subject: subject,
                                    room: room,
                                    attendanceDate: session.replacementDate,
                                    startTime: startTime,
                                    endTime: endTime,
                                  ),
                                ),
                              );
                            }
                          : null,
                      icon: Icon(buttonIcon, size: 20),
                      label: Text(
                        buttonText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 52,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Text(
              'Error: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ThemeData theme) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subject.code,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Replacement',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        session.classGroupId,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              subject.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDisplayDate(session.replacementDate),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  '$startTime — $endTime',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.room_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    room.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            if (session.reason.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
              const SizedBox(height: 16),
              Text(
                '"${session.reason}"',
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    ThemeData theme,
    StudentModel student,
    int index,
  ) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFF1F5F9),
              child: Text(
                index.toString(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    student.matricNo,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStudentsState() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No Students Enrolled',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF475569),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'No active student profiles are mapped to this class group.',
                style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
