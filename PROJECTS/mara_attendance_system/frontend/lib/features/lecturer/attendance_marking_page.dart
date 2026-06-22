import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_models.dart';
import '../../core/firestore/firestore_schema.dart';
import '../../core/logic/attendance_window_logic.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/widgets/app_ui.dart';
import '../notifications/widgets/notification_bell.dart';

class AttendanceMarkingPage extends ConsumerStatefulWidget {
  final TimetableSessionModel session;
  final SubjectModel subject;
  final RoomModel room;
  final String attendanceDate;
  final String startTime;
  final String endTime;

  const AttendanceMarkingPage({
    super.key,
    required this.session,
    required this.subject,
    required this.room,
    required this.attendanceDate,
    required this.startTime,
    required this.endTime,
  });

  @override
  ConsumerState<AttendanceMarkingPage> createState() =>
      _AttendanceMarkingPageState();
}

class _AttendanceMarkingPageState extends ConsumerState<AttendanceMarkingPage> {
  // Local state map mapping studentId to its attendance status and remarks
  final Map<String, AttendanceStatus> _statuses = {};
  final Map<String, TextEditingController> _remarksControllers = {};

  bool _isInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final controller in _remarksControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Initialize the statuses map either from existing database record or as default Present
  void _initializeState(
    List<StudentModel> classStudents,
    AttendanceRecordModel? existingRecord,
  ) {
    if (_isInitialized) return;

    if (existingRecord != null) {
      // Map existing markings from firestore
      for (final student in existingRecord.students) {
        _statuses[student.studentId] = student.status;
        _remarksControllers[student.studentId] = TextEditingController(
          text: student.remarks,
        );
      }
      // In case new students were added to the class after the record was initially created
      for (final student in classStudents) {
        if (!_statuses.containsKey(student.studentId)) {
          _statuses[student.studentId] = AttendanceStatus.present;
          _remarksControllers[student.studentId] = TextEditingController();
        }
      }
    } else {
      // Initialize everyone to Present by default
      for (final student in classStudents) {
        _statuses[student.studentId] = AttendanceStatus.present;
        _remarksControllers[student.studentId] = TextEditingController();
      }
    }

    _isInitialized = true;
  }

  // Real-time calculation of active statistics for top summary card
  Map<String, dynamic> _calculateLiveSummary(List<StudentModel> classStudents) {
    int total = classStudents.length;
    int present = 0;
    int absent = 0;
    int mc = 0;
    int ck = 0;
    int late = 0;

    for (final student in classStudents) {
      final status = _statuses[student.studentId] ?? AttendanceStatus.present;
      switch (status) {
        case AttendanceStatus.present:
          present++;
          break;
        case AttendanceStatus.late:
          late++;
          break;
        case AttendanceStatus.absent:
          absent++;
          break;
        case AttendanceStatus.mc:
          mc++;
          break;
        case AttendanceStatus.ck:
          ck++;
          break;
      }
    }

    // Late counts as present in percentage calculations
    final computedPresent = present + late;
    final activeCount = total - mc - ck;
    final double percentage = activeCount > 0
        ? (computedPresent / activeCount) * 100
        : 100.0;

    return {
      'total': total,
      'present': present,
      'late': late,
      'absent': absent,
      'mc': mc,
      'ck': ck,
      'percentage': percentage,
    };
  }

  // Handle draft saving or final submission to Firestore
  Future<void> _handleSave({required String saveStatus}) async {
    final authUser = ref.read(authProvider);
    if (authUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No active session or user logged in.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Client-side Validation: Ensure remarks are provided for non-present statuses
    for (final entry in _statuses.entries) {
      final studentId = entry.key;
      final status = entry.value;
      if (status != AttendanceStatus.present) {
        final remarks = _remarksControllers[studentId]?.text.trim() ?? '';
        if (remarks.isEmpty) {
          setState(() {
            _isSaving = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please provide remarks for students who are not Present.',
              ),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }
    }

    try {
      final List<AttendanceStudentModel> studentMarkings = [];
      _statuses.forEach((studentId, status) {
        final remarks = _remarksControllers[studentId]?.text.trim() ?? '';
        studentMarkings.add(
          AttendanceStudentModel(
            studentId: studentId,
            status: status,
            remarks: remarks,
          ),
        );
      });

      await ref
          .read(attendanceServiceProvider)
          .saveRecord(
            timetableSessionId: widget.session.timetableSessionId,
            attendanceDate: widget.attendanceDate,
            classGroupId: widget.session.classGroupId,
            subjectId: widget.session.subjectId,
            lecturerId: widget.session.lecturerId,
            currentUser: authUser,
            status: saveStatus,
            studentMarkings: studentMarkings,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  saveStatus == 'submitted'
                      ? Icons.check_circle
                      : Icons.save_as,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  saveStatus == 'submitted'
                      ? 'Attendance successfully submitted!'
                      : 'Attendance draft saved successfully!',
                ),
              ],
            ),
            backgroundColor: saveStatus == 'submitted'
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving attendance: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  bool get _isWindowClosed => isAttendanceMarkingWindowClosed(
    attendanceDate: widget.attendanceDate,
    endTime: widget.endTime,
  );

  bool get _isWindowOpen => isAttendanceMarkingWindowOpen(
    attendanceDate: widget.attendanceDate,
    startTime: widget.startTime,
  );

  @override
  Widget build(BuildContext context) {
    final studentsState = ref.watch(studentsProvider);
    final readOnly = _isWindowClosed || !_isWindowOpen;

    final recordKey =
        '${widget.session.timetableSessionId}|${widget.attendanceDate}';
    final recordState = ref.watch(attendanceRecordProvider(recordKey));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mark Attendance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF172033),
              ),
            ),
            Text(
              'Date: ${widget.attendanceDate}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
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
      body: studentsState.when(
        data: (students) {
          final classStudents = students
              .where((s) => s.classGroupId == widget.session.classGroupId)
              .toList();

          // Sort alphabetically
          classStudents.sort(
            (a, b) =>
                a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
          );

          // Fetch the existing record to see if we should initialize from it
          return recordState.when(
            data: (existingRecord) {
              // Perform lazy state initialization
              _initializeState(classStudents, existingRecord);

              if (classStudents.isEmpty) {
                return _buildEmptyState();
              }

              final summary = _calculateLiveSummary(classStudents);

              return Column(
                children: [
                  if (_isWindowClosed) _buildClosedBanner(),
                  if (!_isWindowClosed && !_isWindowOpen) _buildNotOpenBanner(),
                  // Real-time Summary Card Banner
                  _buildSummaryBanner(context, summary),

                  // Color Legend
                  _buildLegend(),

                  // Enrolled Student List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      itemCount: classStudents.length,
                      itemBuilder: (context, index) {
                        final student = classStudents[index];
                        return _buildStudentMarkingCard(
                          context,
                          student,
                          index + 1,
                          readOnly: readOnly,
                        );
                      },
                    ),
                  ),

                  // Footer Save Action Buttons
                  if (!readOnly)
                    _buildFooterActions(saveStatus: existingRecord?.status),
                ],
              );
            },
            loading: () => const AppLoadingState(label: 'Loading attendance'),
            error: (err, s) =>
                Center(child: Text('Error loading record state: $err')),
          );
        },
        loading: () => const AppLoadingState(label: 'Loading students'),
        error: (err, s) =>
            Center(child: Text('Error loading student enrollment: $err')),
      ),
    );
  }

  Widget _buildClosedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFFFFF7ED),
      child: Row(
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            size: 18,
            color: Color(0xFFEA580C),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              attendanceWindowClosedMessage(widget.endTime),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF9A3412),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotOpenBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: const Color(0xFFEFF6FF), // blue-50
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: Color(0xFF2563EB), // blue-600
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              attendanceWindowNotYetOpenMessage(widget.startTime),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E3A8A), // blue-900
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBanner(
    BuildContext context,
    Map<String, dynamic> summary,
  ) {
    final percentage = summary['percentage'] as double;
    final warningThreshold = AttendanceRules.warningThresholdPercentage;
    final isBelowThreshold = percentage < warningThreshold;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isBelowThreshold
                  ? [
                      const Color(0xFFEF4444),
                      const Color(0xFFF87171),
                    ] // Red alert
                  : [
                      const Color(0xFF2563EB),
                      const Color(0xFF3B82F6),
                    ], // Premium blue
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Class Group: ${widget.session.classGroupId} | Room: ${widget.room.name}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${summary['total']} Students',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Circular visual display of percentage
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          value: percentage / 100,
                          strokeWidth: 6,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Count breakdown list
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance Rate',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${summary['present'] + summary['late']} Present | ${summary['absent']} Absent',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildCountLabel('P', summary['present']),
                            _buildCountLabel('L', summary['late']),
                            _buildCountLabel('A', summary['absent']),
                            _buildCountLabel('MC', summary['mc']),
                            _buildCountLabel('CK', summary['ck']),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountLabel(String label, int val) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Text(
        '$label:$val',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        children: [
          _buildLegendItem('P', 'Present', const Color(0xFF10B981)),
          _buildLegendItem('L', 'Late', const Color(0xFF14B8A6)),
          _buildLegendItem('A', 'Absent', const Color(0xFFEF4444)),
          _buildLegendItem('MC', 'Medical Cert.', const Color(0xFFF59E0B)),
          _buildLegendItem('CK', 'Cuti Khas', const Color(0xFF6366F1)),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String code, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$code - $label',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentMarkingCard(
    BuildContext context,
    StudentModel student,
    int index, {
    required bool readOnly,
  }) {
    final status = _statuses[student.studentId] ?? AttendanceStatus.present;
    final isRemarksVisible = status != AttendanceStatus.present;
    final controller = _remarksControllers[student.studentId];

    return AppCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info Row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: Text(
                    index.toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        student.matricNo,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Custom Status Selector Bar (P, A, MC, CK, L)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusButton(
                  student.studentId,
                  AttendanceStatus.present,
                  'P',
                  'Present',
                  const Color(0xFF10B981),
                  readOnly: readOnly,
                ),
                _buildStatusButton(
                  student.studentId,
                  AttendanceStatus.late,
                  'L',
                  'Late',
                  const Color(0xFF14B8A6),
                  readOnly: readOnly,
                ),
                _buildStatusButton(
                  student.studentId,
                  AttendanceStatus.absent,
                  'A',
                  'Absent',
                  const Color(0xFFEF4444),
                  readOnly: readOnly,
                ),
                _buildStatusButton(
                  student.studentId,
                  AttendanceStatus.mc,
                  'MC',
                  'MC',
                  const Color(0xFFF59E0B),
                  readOnly: readOnly,
                ),
                _buildStatusButton(
                  student.studentId,
                  AttendanceStatus.ck,
                  'CK',
                  'CK',
                  const Color(0xFF6366F1),
                  readOnly: readOnly,
                ),
              ],
            ),

            // Expanding Remarks Input Area
            if (isRemarksVisible && controller != null) ...[
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: TextField(
                  controller: controller,
                  readOnly: readOnly,
                  decoration: InputDecoration(
                    hintText: _getHintTextForStatus(status),
                    hintStyle: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF94A3B8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _getStatusColor(status)),
                    ),
                    prefixIcon: Icon(
                      Icons.rate_review_outlined,
                      size: 16,
                      color: _getStatusColor(status),
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF334155),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Return a friendly status color
  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return const Color(0xFF10B981);
      case AttendanceStatus.late:
        return const Color(0xFF14B8A6);
      case AttendanceStatus.absent:
        return const Color(0xFFEF4444);
      case AttendanceStatus.mc:
        return const Color(0xFFF59E0B);
      case AttendanceStatus.ck:
        return const Color(0xFF6366F1);
    }
  }

  // Pre-fill helper hint based on selected status
  String _getHintTextForStatus(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.late:
        return 'Reason for lateness (e.g. Traffic, Bus delay)';
      case AttendanceStatus.absent:
        return 'Reason for absence (e.g. Unexcused, No response)';
      case AttendanceStatus.mc:
        return 'Medical Certificate info (e.g. Clinic name, MC reference)';
      case AttendanceStatus.ck:
        return 'Cuti Khas details (e.g. Family emergency, Representing college)';
      default:
        return 'Optional remarks...';
    }
  }

  Widget _buildStatusButton(
    String studentId,
    AttendanceStatus btnStatus,
    String shortLabel,
    String tooltipLabel,
    Color activeColor, {
    required bool readOnly,
  }) {
    final isSelected = _statuses[studentId] == btnStatus;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Tooltip(
          message: tooltipLabel,
          child: InkWell(
            onTap: readOnly
                ? null
                : () {
                    setState(() {
                      _statuses[studentId] = btnStatus;
                    });
                  },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? activeColor : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                shortLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterActions({required String? saveStatus}) {
    // If the record has been fully submitted before, it can still be modified, but we focus on updating it.
    final isSubmitted = saveStatus == 'submitted';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Outlined "Save Draft" Button (only relevant if not submitted or is in draft mode)
            if (!isSubmitted) ...[
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(
                        color: Color(0xFFF59E0B),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSaving
                        ? null
                        : () => _handleSave(saveStatus: 'draft'),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFF59E0B),
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: const Text(
                      'Save Draft',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],

            // Primary "Submit Attendance" or "Update Attendance" Button
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSubmitted
                        ? const Color(0xFF10B981)
                        : const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () => _handleSave(saveStatus: 'submitted'),
                  icon: _isSaving && isSubmitted
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isSubmitted ? Icons.check_circle : Icons.send,
                          size: 18,
                        ),
                  label: Text(
                    isSubmitted ? 'Update Attendance' : 'Submit Attendance',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: EmptyState(
        icon: Icons.people_outline,
        title: 'No students enrolled',
        message: 'Cannot mark attendance for a class with zero students.',
        action: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}
