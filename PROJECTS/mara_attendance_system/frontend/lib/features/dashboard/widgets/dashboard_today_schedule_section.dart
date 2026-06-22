import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_models.dart';
import '../../../core/providers/dashboard_provider.dart';
import '../../../core/providers/metadata_provider.dart';
import '../../../core/providers/report_provider.dart';
import '../../../core/providers/timetable_provider.dart';
import '../../lecturer/replacement_class_list_page.dart';
import '../../lecturer/replacement_session_detail_page.dart';
import '../../lecturer/session_detail_page.dart';
import 'dashboard_upcoming_sessions_section.dart';

/// Today's merged class list for dashboards.
///
/// When [requireAssignedTimetable] is true (HOD / HoP / dean), the section is
/// hidden unless the user has at least one active timetable session assigned.
class DashboardTodayScheduleSection extends ConsumerWidget {
  final bool requireAssignedTimetable;

  const DashboardTodayScheduleSection({
    super.key,
    this.requireAssignedTimetable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (requireAssignedTimetable &&
        !ref.watch(currentUserHasMyScheduleProvider)) {
      return const SizedBox.shrink();
    }

    final todaySessionsAsync = ref.watch(lecturerTodaySessionsProvider);
    final replacementsAsync = ref.watch(lecturerTodayReplacementsProvider);
    final recordsAsync = ref.watch(lecturerReportsProvider);
    final subjects = ref.watch(subjectsProvider).value ?? [];
    final rooms = ref.watch(roomsProvider).value ?? [];
    final timeSlots = ref.watch(timeSlotsProvider).value ?? [];

    return todaySessionsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error loading today\'s classes: $e'),
      data: (todaySessions) {
        return replacementsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error loading replacements: $e'),
          data: (replacements) {
            return DashboardUpcomingSessionsSection(
              todaySessions: todaySessions,
              replacements: replacements,
              subjects: subjects,
              rooms: rooms,
              timeSlots: timeSlots,
              attendanceRecords: recordsAsync.value ?? [],
              onViewReplacements: requireAssignedTimetable
                  ? null
                  : () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              const ReplacementClassListPage(),
                        ),
                      );
                    },
              onTimetableTap: (session) => openDashboardSessionDetail(
                context,
                session: session,
                subjects: subjects,
                rooms: rooms,
                timeSlots: timeSlots,
              ),
              onReplacementTap: (session) => openDashboardReplacementDetail(
                context,
                session: session,
                subjects: subjects,
                rooms: rooms,
                timeSlots: timeSlots,
              ),
            );
          },
        );
      },
    );
  }
}

void openDashboardSessionDetail(
  BuildContext context, {
  required TimetableSessionModel session,
  required List<SubjectModel> subjects,
  required List<RoomModel> rooms,
  required List<TimeSlotModel> timeSlots,
}) {
  final subject = subjects.firstWhere(
    (s) => s.subjectId == session.subjectId,
    orElse: () => SubjectModel(
      subjectId: session.subjectId,
      code: session.subjectId,
      name: 'Unknown Subject',
      moduleType: '',
      status: 'Active',
    ),
  );
  final room = rooms.firstWhere(
    (r) => r.roomId == session.roomId,
    orElse: () => RoomModel(
      roomId: session.roomId,
      name: session.roomId,
      location: '',
      status: 'Active',
    ),
  );
  final startSlot = _slot(timeSlots, session.startSlotId);
  final endSlot = _slot(timeSlots, session.endSlotId);

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => SessionDetailPage(
        session: session,
        subject: subject,
        room: room,
        startTime: startSlot.startTime,
        endTime: endSlot.endTime,
      ),
    ),
  );
}

void openDashboardReplacementDetail(
  BuildContext context, {
  required ReplacementSessionModel session,
  required List<SubjectModel> subjects,
  required List<RoomModel> rooms,
  required List<TimeSlotModel> timeSlots,
}) {
  final subject = subjects.firstWhere(
    (s) => s.subjectId == session.subjectId,
    orElse: () => SubjectModel(
      subjectId: session.subjectId,
      code: session.subjectId,
      name: 'Unknown Subject',
      moduleType: '',
      status: 'Active',
    ),
  );
  final room = rooms.firstWhere(
    (r) => r.roomId == session.roomId,
    orElse: () => RoomModel(
      roomId: session.roomId,
      name: session.roomId,
      location: '',
      status: 'Active',
    ),
  );
  final startSlot = _slot(timeSlots, session.startSlotId);
  final endSlot = _slot(timeSlots, session.endSlotId);

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ReplacementSessionDetailPage(
        session: session,
        subject: subject,
        room: room,
        startTime: startSlot.startTime,
        endTime: endSlot.endTime,
      ),
    ),
  );
}

TimeSlotModel _slot(List<TimeSlotModel> timeSlots, String id) {
  return timeSlots.firstWhere(
    (t) => t.timeSlotId == id,
    orElse: () => TimeSlotModel(
      timeSlotId: id,
      slotNo: 0,
      startTime: '??:??',
      endTime: '??:??',
      durationMinutes: 0,
      status: 'Active',
    ),
  );
}
