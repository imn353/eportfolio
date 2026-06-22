import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_models.dart';
import '../../core/firestore/firestore_schema.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/providers/replacement_session_provider.dart';
import '../../core/providers/timetable_provider.dart';
import '../lecturer/replacement_session_detail_page.dart';
import '../lecturer/session_detail_page.dart';
import 'widgets/app_drawer.dart';
import '../notifications/widgets/notification_bell.dart';

class LecturerSchedulePage extends ConsumerWidget {
  const LecturerSchedulePage({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final sessionState = ref.watch(timetableSessionsProvider);
    final lecturersState = ref.watch(lecturersProvider);
    final subjectsState = ref.watch(subjectsProvider);
    final roomsState = ref.watch(roomsProvider);
    final timeSlotsState = ref.watch(timeSlotsProvider);
    final replacementsState = ref.watch(replacementSessionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Schedule',
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
      drawer: const AppDrawer(currentPage: 'schedule'),
      body: lecturersState.when(
        data: (lecturers) {
          final currentLecturer = lecturers.firstWhere(
            (l) => l.userUid == user.uid,
            orElse: () => LecturerModel(
              lecturerId: '',
              userUid: '',
              fullName: user.displayName,
              email: user.email,
              status: 'Active',
            ),
          );

          if (currentLecturer.lecturerId.isEmpty) {
            return _buildNoLecturerMappingState(user.displayName);
          }

          return sessionState.when(
            data: (sessions) {
              final subjects = subjectsState.value ?? [];
              final rooms = roomsState.value ?? [];
              final timeSlots = timeSlotsState.value ?? [];

              final mySessions = sessions
                  .where((s) => s.lecturerId == currentLecturer.lecturerId)
                  .toList();

              mySessions.sort((a, b) {
                final dayComp = a.dayOfWeek.compareTo(b.dayOfWeek);
                if (dayComp != 0) return dayComp;
                return a.startSlotId.compareTo(b.startSlotId);
              });

              // Approved replacement sessions for this lecturer
              final today = _todayDateString();
              final allReplacements = replacementsState.value ?? [];
              final myReplacements =
                  allReplacements
                      .where(
                        (r) =>
                            r.lecturerId == currentLecturer.lecturerId &&
                            r.status ==
                                ReplacementSessionStatus.approved.value &&
                            r.replacementDate.compareTo(today) >= 0,
                      )
                      .toList()
                    ..sort(
                      (a, b) => a.replacementDate.compareTo(b.replacementDate),
                    );

              return ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                children: [
                  // Approved replacement classes section (hidden when empty)
                  if (myReplacements.isNotEmpty) ...[
                    _sectionHeader(context, 'Approved Replacement Classes'),
                    const SizedBox(height: 12),
                    ...myReplacements.map(
                      (r) => _buildReplacementCard(
                        context,
                        r,
                        subjects,
                        rooms,
                        timeSlots,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Weekly timetable
                  if (mySessions.isNotEmpty) ...[
                    if (myReplacements.isNotEmpty)
                      _sectionHeader(context, 'Weekly Timetable'),
                    ..._buildDayGroups(
                      context,
                      mySessions,
                      subjects,
                      rooms,
                      timeSlots,
                    ),
                  ] else if (myReplacements.isEmpty) ...[
                    _buildEmptyState(),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading sessions: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) =>
            Center(child: Text('Error loading lecturer context: $e')),
      ),
    );
  }

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _formatReplacementDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
      return '${days[date.weekday - 1]}, ${parts[2]} ${months[date.month - 1]} ${parts[0]}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  List<Widget> _buildDayGroups(
    BuildContext context,
    List<TimetableSessionModel> sessions,
    List<SubjectModel> subjects,
    List<RoomModel> rooms,
    List<TimeSlotModel> timeSlots,
  ) {
    final Map<int, List<TimetableSessionModel>> grouped = {};
    for (final session in sessions) {
      grouped.putIfAbsent(session.dayOfWeek, () => []).add(session);
    }
    final sortedDays = grouped.keys.toList()..sort();

    return sortedDays.expand((dayNum) {
      final daySessions = grouped[dayNum]!;
      final dayName = _daysOfWeek[dayNum] ?? 'Other';
      return [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4),
          child: Text(
            dayName.toUpperCase(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...daySessions.map(
          (s) =>
              _buildLecturerSessionCard(context, s, subjects, rooms, timeSlots),
        ),
      ];
    }).toList();
  }

  Widget _buildReplacementCard(
    BuildContext context,
    ReplacementSessionModel session,
    List<SubjectModel> subjects,
    List<RoomModel> rooms,
    List<TimeSlotModel> timeSlots,
  ) {
    final subject = subjects.firstWhere(
      (s) => s.subjectId == session.subjectId,
      orElse: () => SubjectModel(
        subjectId: session.subjectId,
        code: session.subjectId,
        name: 'Unknown Subject',
        moduleType: '',
        status: 'active',
      ),
    );
    final room = rooms.firstWhere(
      (r) => r.roomId == session.roomId,
      orElse: () => RoomModel(
        roomId: session.roomId,
        name: session.roomId,
        location: '',
        status: 'active',
      ),
    );
    final startSlot = timeSlots.firstWhere(
      (t) => t.timeSlotId == session.startSlotId,
      orElse: () => TimeSlotModel(
        timeSlotId: session.startSlotId,
        slotNo: 0,
        startTime: '--:--',
        endTime: '--:--',
        durationMinutes: 0,
        status: 'active',
      ),
    );
    final endSlot = timeSlots.firstWhere(
      (t) => t.timeSlotId == session.endSlotId,
      orElse: () => TimeSlotModel(
        timeSlotId: session.endSlotId,
        slotNo: 0,
        startTime: '--:--',
        endTime: '--:--',
        durationMinutes: 0,
        status: 'active',
      ),
    );

    return Card(
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
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
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amber stripe for replacement
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
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
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF172033),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatReplacementDate(session.replacementDate),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${startSlot.startTime} - ${endSlot.endTime}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.room_outlined,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              room.name,
                              style: const TextStyle(
                                fontSize: 13,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoLecturerMappingState(String name) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 16),
            Text(
              'Hello $name',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No active lecturer relationship was found for this user in the database.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Schedule is Clear',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No timetable sessions are currently assigned to you.',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLecturerSessionCard(
    BuildContext context,
    TimetableSessionModel session,
    List<SubjectModel> subjects,
    List<RoomModel> rooms,
    List<TimeSlotModel> timeSlots,
  ) {
    final theme = Theme.of(context);

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
    final startSlot = timeSlots.firstWhere(
      (t) => t.timeSlotId == session.startSlotId,
      orElse: () => TimeSlotModel(
        timeSlotId: session.startSlotId,
        slotNo: 0,
        startTime: '??:??',
        endTime: '??:??',
        durationMinutes: 0,
        status: 'Active',
      ),
    );
    final endSlot = timeSlots.firstWhere(
      (t) => t.timeSlotId == session.endSlotId,
      orElse: () => TimeSlotModel(
        timeSlotId: session.endSlotId,
        slotNo: 0,
        startTime: '??:??',
        endTime: '??:??',
        durationMinutes: 0,
        status: 'Active',
      ),
    );

    final timeString = '${startSlot.startTime} - ${endSlot.endTime}';

    return Card(
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
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
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            subject.code,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              session.classGroupId,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subject.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF172033),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeString,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.room_outlined,
                            size: 16,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              room.name,
                              style: const TextStyle(
                                fontSize: 14,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
