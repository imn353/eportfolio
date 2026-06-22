import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_models.dart';
import '../../core/logic/attendance_window_logic.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../notifications/widgets/notification_bell.dart';
import 'attendance_marking_page.dart';

class SessionDetailPage extends ConsumerStatefulWidget {
  final TimetableSessionModel session;
  final SubjectModel subject;
  final RoomModel room;
  final String startTime;
  final String endTime;

  const SessionDetailPage({
    super.key,
    required this.session,
    required this.subject,
    required this.room,
    required this.startTime,
    required this.endTime,
  });

  @override
  ConsumerState<SessionDetailPage> createState() => _SessionDetailPageState();
}

class _SessionDetailPageState extends ConsumerState<SessionDetailPage> {
  late DateTime _selectedDate;

  static const _daysOfWeek = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = _getDefaultDate(widget.session.dayOfWeek);
  }

  DateTime _getDefaultDate(int targetWeekday) {
    final now = DateTime.now();
    int difference = now.weekday - targetWeekday;
    if (difference < 0) {
      difference += 7;
    }
    return DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: difference));
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      selectableDayPredicate: (date) {
        // Only allow days that match the timetable session's day of week
        return date.weekday == widget.session.dayOfWeek;
      },
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF172033),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final studentsState = ref.watch(studentsProvider);

    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    final recordKey = '${widget.session.timetableSessionId}|$dateStr';
    final recordAsync = ref.watch(attendanceRecordProvider(recordKey));

    final dayName = _daysOfWeek[widget.session.dayOfWeek] ?? 'Other';
    final timeString = '${widget.startTime} - ${widget.endTime}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Session Details',
          style: TextStyle(
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
            // Session Info Card
            _buildSessionInfoCard(context, theme, dayName, timeString, dateStr),
            const SizedBox(height: 28),

            // Students Section Title & Count Badge
            studentsState.when(
              data: (students) {
                final classStudents = students
                    .where((s) => s.classGroupId == widget.session.classGroupId)
                    .toList();

                // Sort alphabetically by full name
                classStudents.sort(
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
                            itemBuilder: (context, index) {
                              final student = classStudents[index];
                              return _buildStudentCard(
                                context,
                                theme,
                                student,
                                index + 1,
                              );
                            },
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
              error: (err, s) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error loading students: $err',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    ],
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
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: recordAsync.when(
            data: (record) {
              final buttonColor = record == null
                  ? theme.colorScheme.primary
                  : record.status == 'draft'
                  ? const Color(0xFFF59E0B) // Amber
                  : const Color(0xFF10B981); // Emerald

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
                attendanceDate: dateStr,
                endTime: widget.endTime,
              );
              final windowOpen = isAttendanceMarkingWindowOpen(
                attendanceDate: dateStr,
                startTime: widget.startTime,
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
                      attendanceWindowClosedMessage(widget.endTime),
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
                      attendanceWindowNotYetOpenMessage(widget.startTime),
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
                                    session: widget.session,
                                    subject: widget.subject,
                                    room: widget.room,
                                    attendanceDate: dateStr,
                                    startTime: widget.startTime,
                                    endTime: widget.endTime,
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
                          letterSpacing: 0.2,
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
            error: (err, s) => Text(
              'Error getting attendance state: $err',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard(
    BuildContext context,
    ThemeData theme,
    String dayName,
    String timeString,
    String dateStr,
  ) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
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
                  widget.subject.code,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
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
                    widget.session.classGroupId,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.subject.name,
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
                  dayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 24),
                const Icon(Icons.schedule, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  timeString,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                    widget.room.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
            const SizedBox(height: 20),
            // Premium Date Selector row
            Row(
              children: [
                const Icon(Icons.event, size: 18, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Text(
                  'Date: $dateStr',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.edit_calendar, size: 16),
                  label: const Text('Change Date'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    foregroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
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
            // Avatar Circle
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
            // Student Info
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
            // Status Badge
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E), // green for active status
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
