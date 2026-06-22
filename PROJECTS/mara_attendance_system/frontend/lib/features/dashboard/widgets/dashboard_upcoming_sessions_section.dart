import 'package:flutter/material.dart';

import '../../../core/firestore/firestore_models.dart';
import '../../../core/firestore/firestore_schema.dart';
import '../../../core/logic/attendance_window_logic.dart';
import '../../../core/providers/dashboard_provider.dart';
import 'dashboard_section_header.dart';

/// Accent for regular timetable sessions on the dashboard.
const dashboardRegularClassAccent = Color(0xFF2563EB);

/// Accent for replacement sessions on the dashboard.
const dashboardReplacementClassAccent = Color(0xFFF59E0B);

enum _TodayClassKind { regular, replacement }

class _TodayClassItem {
  final _TodayClassKind kind;
  final String startSlotId;
  final String endSlotId;
  final TimetableSessionModel? timetableSession;
  final ReplacementSessionModel? replacementSession;

  const _TodayClassItem._({
    required this.kind,
    required this.startSlotId,
    required this.endSlotId,
    this.timetableSession,
    this.replacementSession,
  });

  factory _TodayClassItem.regular(TimetableSessionModel session) {
    return _TodayClassItem._(
      kind: _TodayClassKind.regular,
      startSlotId: session.startSlotId,
      endSlotId: session.endSlotId,
      timetableSession: session,
    );
  }

  factory _TodayClassItem.replacement(ReplacementSessionModel session) {
    return _TodayClassItem._(
      kind: _TodayClassKind.replacement,
      startSlotId: session.startSlotId,
      endSlotId: session.endSlotId,
      replacementSession: session,
    );
  }
}

class DashboardUpcomingSessionsSection extends StatelessWidget {
  final List<TimetableSessionModel> todaySessions;
  final List<ReplacementSessionModel> replacements;
  final List<SubjectModel> subjects;
  final List<RoomModel> rooms;
  final List<TimeSlotModel> timeSlots;
  final List<AttendanceRecordModel> attendanceRecords;
  final VoidCallback? onViewReplacements;
  final void Function(TimetableSessionModel session)? onTimetableTap;
  final void Function(ReplacementSessionModel session)? onReplacementTap;
  final String sectionTitle;

  const DashboardUpcomingSessionsSection({
    super.key,
    required this.todaySessions,
    required this.replacements,
    required this.subjects,
    required this.rooms,
    required this.timeSlots,
    required this.attendanceRecords,
    this.onViewReplacements,
    this.onTimetableTap,
    this.onReplacementTap,
    this.sectionTitle = "Today's Schedule",
  });

  SubjectModel _subject(String id) {
    return subjects.firstWhere(
      (s) => s.subjectId == id,
      orElse: () => SubjectModel(
        subjectId: id,
        code: id,
        name: 'Unknown Subject',
        moduleType: '',
        status: 'active',
      ),
    );
  }

  RoomModel _room(String id) {
    return rooms.firstWhere(
      (r) => r.roomId == id,
      orElse: () =>
          RoomModel(roomId: id, name: id, location: '', status: 'active'),
    );
  }

  String _timeRange(String startSlotId, String endSlotId) {
    final start = timeSlots.firstWhere(
      (t) => t.timeSlotId == startSlotId,
      orElse: () => TimeSlotModel(
        timeSlotId: startSlotId,
        slotNo: 0,
        startTime: '--:--',
        endTime: '--:--',
        durationMinutes: 0,
        status: 'active',
      ),
    );
    final end = timeSlots.firstWhere(
      (t) => t.timeSlotId == endSlotId,
      orElse: () => TimeSlotModel(
        timeSlotId: endSlotId,
        slotNo: 0,
        startTime: '--:--',
        endTime: '--:--',
        durationMinutes: 0,
        status: 'active',
      ),
    );
    return '${start.startTime} – ${end.endTime}';
  }

  bool _isTimetableSubmitted(TimetableSessionModel session) {
    final today = dashboardTodayDateString();
    final docId = FirestoreDocumentIds.attendanceRecord(
      timetableSessionId: session.timetableSessionId,
      attendanceDate: today,
    );
    final match = attendanceRecords.where((r) => r.attendanceRecordId == docId);
    return match.isNotEmpty && match.first.status == 'submitted';
  }

  bool _isReplacementSubmitted(ReplacementSessionModel session) {
    final docId = FirestoreDocumentIds.attendanceRecord(
      timetableSessionId: session.replacementSessionId,
      attendanceDate: session.replacementDate,
    );
    final match = attendanceRecords.where((r) => r.attendanceRecordId == docId);
    return match.isNotEmpty && match.first.status == 'submitted';
  }

  bool _isSessionUpcoming(String startSlotId, String dateStr) {
    final startSlot = timeSlots.firstWhere(
      (t) => t.timeSlotId == startSlotId,
      orElse: () => TimeSlotModel(
        timeSlotId: '',
        slotNo: 0,
        startTime: '00:00',
        endTime: '00:00',
        durationMinutes: 0,
        status: 'active',
      ),
    );

    final slotStart = parseAttendanceSlotTime(
      attendanceDate: dateStr,
      timeString: startSlot.startTime,
    );
    if (slotStart == null) return false;

    return DateTime.now().isBefore(slotStart);
  }

  int _startSortKey(String startSlotId) {
    final slot = timeSlots.firstWhere(
      (t) => t.timeSlotId == startSlotId,
      orElse: () => TimeSlotModel(
        timeSlotId: startSlotId,
        slotNo: 999,
        startTime: '99:99',
        endTime: '99:99',
        durationMinutes: 0,
        status: 'active',
      ),
    );
    return slot.slotNo;
  }

  List<_TodayClassItem> _mergedTodayClasses() {
    final items = <_TodayClassItem>[
      ...todaySessions.map(_TodayClassItem.regular),
      ...replacements.map(_TodayClassItem.replacement),
    ];
    items.sort(
      (a, b) =>
          _startSortKey(a.startSlotId).compareTo(_startSortKey(b.startSlotId)),
    );
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final todayClasses = _mergedTodayClasses();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardSectionHeader(
          icon: Icons.event_outlined,
          title: sectionTitle,
          actionLabel: onViewReplacements != null ? 'Replacements' : null,
          onAction: onViewReplacements,
        ),
        const SizedBox(height: 12),
        if (todayClasses.isEmpty)
          _buildEmptyState()
        else ...[
          const _SubsectionLabel(label: "Today's Classes"),
          const SizedBox(height: 8),
          ...todayClasses.map((item) {
            if (item.kind == _TodayClassKind.regular) {
              final session = item.timetableSession!;
              final subject = _subject(session.subjectId);
              final room = _room(session.roomId);
              final submitted = _isTimetableSubmitted(session);
              final upcoming = _isSessionUpcoming(
                session.startSlotId,
                dashboardTodayDateString(),
              );

              String statusLabel = 'Pending';
              Color statusColor = const Color(0xFF92400E);
              Color statusBg = const Color(0xFFFEF3C7);

              if (submitted) {
                statusLabel = 'Submitted';
                statusColor = const Color(0xFF065F46);
                statusBg = const Color(0xFFD1FAE5);
              } else if (upcoming) {
                statusLabel = 'Upcoming';
                statusColor = const Color(0xFF1E40AF); // Blue-800
                statusBg = const Color(0xFFDBEAFE); // Blue-100
              }

              return _SessionTile(
                accentColor: dashboardRegularClassAccent,
                title: '${subject.code} · ${session.classGroupId}',
                subtitle: subject.name,
                time: _timeRange(session.startSlotId, session.endSlotId),
                location: room.name,
                statusLabel: statusLabel,
                statusColor: statusColor,
                statusBg: statusBg,
                onTap: onTimetableTap != null
                    ? () => onTimetableTap!(session)
                    : null,
              );
            }

            final session = item.replacementSession!;
            final subject = _subject(session.subjectId);
            final room = _room(session.roomId);
            final submitted = _isReplacementSubmitted(session);
            final upcoming = _isSessionUpcoming(
              session.startSlotId,
              session.replacementDate,
            );

            String statusLabel = 'Replacement';
            Color statusColor = const Color(0xFF92400E);
            Color statusBg = const Color(0xFFFEF3C7);

            if (submitted) {
              statusLabel = 'Submitted';
              statusColor = const Color(0xFF065F46);
              statusBg = const Color(0xFFD1FAE5);
            } else if (upcoming) {
              statusLabel = 'Upcoming';
              statusColor = const Color(0xFF1E40AF);
              statusBg = const Color(0xFFDBEAFE);
            }

            return _SessionTile(
              accentColor: dashboardReplacementClassAccent,
              title: '${subject.code} · ${session.classGroupId}',
              subtitle: subject.name,
              time: _timeRange(session.startSlotId, session.endSlotId),
              location: room.name,
              statusLabel: statusLabel,
              statusColor: statusColor,
              statusBg: statusBg,
              onTap: onReplacementTap != null
                  ? () => onReplacementTap!(session)
                  : null,
            );
          }),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF94A3B8),
              size: 28,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No classes scheduled for today.',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubsectionLabel extends StatelessWidget {
  final String label;

  const _SubsectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: Color(0xFF64748B),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Color accentColor;
  final String title;
  final String subtitle;
  final String time;
  final String location;
  final String statusLabel;
  final Color statusColor;
  final Color statusBg;
  final VoidCallback? onTap;

  const _SessionTile({
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.location,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 48,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.room_outlined,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
