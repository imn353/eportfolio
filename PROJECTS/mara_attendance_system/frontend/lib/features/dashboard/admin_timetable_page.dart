import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/firestore/firestore_models.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/providers/timetable_provider.dart';
import '../../core/widgets/app_ui.dart';
import '../admin/timetable_session_form_page.dart';
import '../admin/timetable_import_page.dart';
import 'widgets/app_drawer.dart';
import '../notifications/widgets/notification_bell.dart';

class AdminTimetablePage extends ConsumerStatefulWidget {
  const AdminTimetablePage({super.key});

  @override
  ConsumerState<AdminTimetablePage> createState() => _AdminTimetablePageState();
}

class _AdminTimetablePageState extends ConsumerState<AdminTimetablePage> {
  String? _selectedClassFilter;
  int? _selectedDayFilter;
  String _searchQuery = '';

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
  Widget build(BuildContext context) {
    final sessionState = ref.watch(timetableSessionsProvider);
    final classGroupsState = ref.watch(classGroupsProvider);
    final subjectsState = ref.watch(subjectsProvider);
    final lecturersState = ref.watch(lecturersProvider);
    final roomsState = ref.watch(roomsProvider);
    final timeSlotsState = ref.watch(timeSlotsProvider);

    return AppShell(
      title: 'Timetable',
      drawer: const AppDrawer(currentPage: 'timetable'),
      actions: [
        const NotificationBell(),
        IconButton(
          icon: const Icon(Icons.file_upload_outlined),
          tooltip: 'Import Schedule',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const TimetableImportPage(),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
      ],
      body: sessionState.when(
        data: (sessions) {
          final classGroups = classGroupsState.value ?? [];
          final subjects = subjectsState.value ?? [];
          final lecturers = lecturersState.value ?? [];
          final rooms = roomsState.value ?? [];
          final timeSlots = timeSlotsState.value ?? [];

          var filteredSessions = sessions;
          if (_selectedClassFilter != null) {
            filteredSessions = filteredSessions
                .where((s) => s.classGroupId == _selectedClassFilter)
                .toList();
          }
          if (_selectedDayFilter != null) {
            filteredSessions = filteredSessions
                .where((s) => s.dayOfWeek == _selectedDayFilter)
                .toList();
          }
          if (_searchQuery.trim().isNotEmpty) {
            final q = _searchQuery.trim().toLowerCase();
            filteredSessions = filteredSessions.where((s) {
              SubjectModel? subject;
              LecturerModel? lecturer;
              RoomModel? room;
              for (final x in subjects) {
                if (x.subjectId == s.subjectId) subject = x;
              }
              for (final x in lecturers) {
                if (x.lecturerId == s.lecturerId) lecturer = x;
              }
              for (final x in rooms) {
                if (x.roomId == s.roomId) room = x;
              }
              return s.classGroupId.toLowerCase().contains(q) ||
                  (subject?.code.toLowerCase().contains(q) ?? false) ||
                  (subject?.name.toLowerCase().contains(q) ?? false) ||
                  (lecturer?.fullName.toLowerCase().contains(q) ?? false) ||
                  (room?.name.toLowerCase().contains(q) ?? false);
            }).toList();
          }

          filteredSessions.sort((a, b) {
            final dayComp = a.dayOfWeek.compareTo(b.dayOfWeek);
            if (dayComp != 0) return dayComp;
            return a.startSlotId.compareTo(b.startSlotId);
          });

          return Column(
            children: [
              _buildFiltersBar(classGroups),
              Expanded(
                child: filteredSessions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        itemCount: filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = filteredSessions[index];
                          return _buildSessionCard(
                            session: session,
                            subjects: subjects,
                            lecturers: lecturers,
                            rooms: rooms,
                            timeSlots: timeSlots,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const AppLoadingState(label: 'Loading timetable'),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Error loading sessions: $err'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const TimetableSessionFormPage(),
            ),
          );
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Session',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFiltersBar(List<ClassGroupModel> classGroups) {
    return FilterBar(
      children: [
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Search',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              SearchInput(
                hintText: 'Subject, lecturer, room',
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ],
          ),
        ),
        AppFilterDropdown<String>(
          label: 'Class',
          width: 180,
          value: _selectedClassFilter,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('All Classes'),
            ),
            ...classGroups.map(
              (group) => DropdownMenuItem(
                value: group.classGroupId,
                child: Text(group.name, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (val) => setState(() => _selectedClassFilter = val),
        ),
        AppFilterDropdown<int>(
          label: 'Day',
          width: 160,
          value: _selectedDayFilter,
          items: [
            const DropdownMenuItem<int>(value: null, child: Text('All Days')),
            ..._daysOfWeek.entries.map(
              (entry) =>
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            ),
          ],
          onChanged: (val) => setState(() => _selectedDayFilter = val),
        ),
        if (_selectedClassFilter != null || _selectedDayFilter != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedClassFilter = null;
                  _selectedDayFilter = null;
                });
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Reset'),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: EmptyState(
        icon: Icons.calendar_today_rounded,
        title: 'No timetable sessions found',
        message: 'Try adjusting your filters or add a new session.',
      ),
    );
  }

  Widget _buildSessionCard({
    required TimetableSessionModel session,
    required List<SubjectModel> subjects,
    required List<LecturerModel> lecturers,
    required List<RoomModel> rooms,
    required List<TimeSlotModel> timeSlots,
  }) {
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

    final lecturer = lecturers.firstWhere(
      (l) => l.lecturerId == session.lecturerId,
      orElse: () => LecturerModel(
        lecturerId: session.lecturerId,
        userUid: '',
        fullName: 'Unknown Lecturer',
        email: '',
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

    final dayName = _daysOfWeek[session.dayOfWeek] ?? 'Unknown Day';
    final timeRange = '${startSlot.startTime} - ${endSlot.endTime}';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.code,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    session.classGroupId,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(
                  Icons.access_time_filled,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  '$dayName, $timeRange',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.room_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  room.name,
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 8),
                Text(
                  lecturer.fullName,
                  style: const TextStyle(color: Color(0xFF475569)),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            TimetableSessionFormPage(session: session),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _confirmDelete(session.timetableSessionId),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Session?'),
        content: const Text(
          'Are you sure you want to permanently delete this timetable session?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(dialogContext).pop();
              try {
                await ref.read(timetableServiceProvider).deleteSession(id);
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Session deleted successfully.'),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(content: Text('Error deleting session: $e')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
