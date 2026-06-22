import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_models.dart';
import '../../core/firestore/firestore_schema.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/providers/replacement_session_provider.dart';
import '../../core/providers/timetable_provider.dart';
import '../notifications/widgets/notification_bell.dart';

class ReplacementClassBookingPage extends ConsumerStatefulWidget {
  const ReplacementClassBookingPage({super.key});

  @override
  ConsumerState<ReplacementClassBookingPage> createState() =>
      _ReplacementClassBookingPageState();
}

class _ReplacementClassBookingPageState
    extends ConsumerState<ReplacementClassBookingPage> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  String? _selectedSubjectId;
  String? _selectedClassGroupId;
  String? _selectedRoomId;
  DateTime? _selectedDate;
  String? _selectedStartSlotId;
  String? _selectedEndSlotId;

  bool _isSaving = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
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
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _toDateString(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        // Availability depends on the date — clear any prior slot selection.
        _selectedStartSlotId = null;
        _selectedEndSlotId = null;
      });
    }
  }

  // ── Slot helpers ──────────────────────────────────────────────────────────

  int _slotNoOf(String id, List<TimeSlotModel> slots) => slots
      .firstWhere(
        (s) => s.timeSlotId == id,
        orElse: () => TimeSlotModel(
          timeSlotId: id,
          slotNo: -1,
          startTime: '',
          endTime: '',
          durationMinutes: 0,
          status: '',
        ),
      )
      .slotNo;

  String? _slotIdOfNo(int no, List<TimeSlotModel> slots) {
    for (final s in slots) {
      if (s.slotNo == no) return s.timeSlotId;
    }
    return null;
  }

  /// Determines whether a single time slot is free for the chosen room/date/
  /// lecturer, and if not, a short human reason. A slot is busy when an active
  /// weekly timetable session (same weekday) or a live replacement session
  /// (same date) occupies the same ROOM or belongs to the current LECTURER.
  ({bool busy, String? reason}) _slotAvailability(
    TimeSlotModel slot, {
    required List<TimetableSessionModel> timetable,
    required List<ReplacementSessionModel> replacements,
    required List<TimeSlotModel> allSlots,
    required String lecturerId,
    required String roomId,
    required DateTime date,
  }) {
    final weekday = date.weekday; // 1 = Mon … 7 = Sun
    final dateStr = _toDateString(date);
    final n = slot.slotNo;

    bool covers(String startId, String endId) {
      final s = _slotNoOf(startId, allSlots);
      final e = _slotNoOf(endId, allSlots);
      return s <= n && n <= e;
    }

    // Weekly recurring sessions on this weekday
    for (final ts in timetable) {
      if (ts.status.toLowerCase() != 'active') continue;
      if (ts.dayOfWeek != weekday) continue;
      if (!covers(ts.startSlotId, ts.endSlotId)) continue;
      if (ts.roomId == roomId) return (busy: true, reason: 'Room in use');
      if (lecturerId.isNotEmpty && ts.lecturerId == lecturerId) {
        return (busy: true, reason: 'You have a class');
      }
    }

    // Other replacement sessions on the same calendar date
    for (final rs in replacements) {
      if (rs.replacementDate != dateStr) continue;
      if (rs.status == ReplacementSessionStatus.rejected.value) continue;
      if (rs.status == ReplacementSessionStatus.cancelled.value) continue;
      if (!covers(rs.startSlotId, rs.endSlotId)) continue;
      if (rs.roomId == roomId) return (busy: true, reason: 'Room booked');
      if (lecturerId.isNotEmpty && rs.lecturerId == lecturerId) {
        return (busy: true, reason: 'You are booked');
      }
    }

    return (busy: false, reason: null);
  }

  bool _isSlotSelected(TimeSlotModel slot, List<TimeSlotModel> allSlots) {
    if (_selectedStartSlotId == null) return false;
    final startNo = _slotNoOf(_selectedStartSlotId!, allSlots);
    final endNo = _selectedEndSlotId == null
        ? startNo
        : _slotNoOf(_selectedEndSlotId!, allSlots);
    final low = startNo < endNo ? startNo : endNo;
    final high = startNo < endNo ? endNo : startNo;
    return slot.slotNo >= low && slot.slotNo <= high;
  }

  void _onSlotTap(
    TimeSlotModel slot,
    List<TimeSlotModel> allSlots,
    bool Function(TimeSlotModel) isBusy,
  ) {
    if (isBusy(slot)) return; // busy slots aren't selectable

    // No start yet → this becomes the start.
    if (_selectedStartSlotId == null) {
      setState(() {
        _selectedStartSlotId = slot.timeSlotId;
        _selectedEndSlotId = null;
      });
      return;
    }

    // Start set, no end yet → either deselect or form a range.
    if (_selectedEndSlotId == null) {
      if (slot.timeSlotId == _selectedStartSlotId) {
        setState(() {
          _selectedStartSlotId = null;
          _selectedEndSlotId = null;
        });
        return;
      }
      final startNo = _slotNoOf(_selectedStartSlotId!, allSlots);
      final tapNo = slot.slotNo;
      final low = startNo < tapNo ? startNo : tapNo;
      final high = startNo < tapNo ? tapNo : startNo;

      // Every slot between the two ends must be free.
      final blocked = allSlots.any(
        (s) => s.slotNo >= low && s.slotNo <= high && isBusy(s),
      );
      if (blocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'That range crosses a busy slot — selection restarted.',
            ),
            backgroundColor: Colors.orangeAccent,
          ),
        );
        setState(() {
          _selectedStartSlotId = slot.timeSlotId;
          _selectedEndSlotId = null;
        });
      } else {
        setState(() {
          _selectedStartSlotId = _slotIdOfNo(low, allSlots);
          _selectedEndSlotId = _slotIdOfNo(high, allSlots);
        });
      }
      return;
    }

    // Both already set → start a fresh selection.
    setState(() {
      _selectedStartSlotId = slot.timeSlotId;
      _selectedEndSlotId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // All ref.watch() at top level — required by Riverpod
    final subjectsState = ref.watch(subjectsProvider);
    final classGroupsState = ref.watch(classGroupsProvider);
    final roomsState = ref.watch(roomsProvider);
    final timeSlotsState = ref.watch(timeSlotsProvider);
    final timetableSessions = ref.watch(timetableSessionsProvider).value ?? [];
    final replacementSessions =
        ref.watch(replacementSessionsProvider).value ?? [];

    // Resolve the signed-in lecturer so we can flag their own clashes.
    final lecturers = ref.watch(lecturersProvider).value ?? [];
    final user = ref.watch(authProvider);
    final currentLecturerId = lecturers
        .firstWhere(
          (l) => l.userUid == user?.uid,
          orElse: () => LecturerModel(
            lecturerId: '',
            userUid: '',
            fullName: '',
            email: '',
            status: '',
          ),
        )
        .lecturerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Book Replacement Class',
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
      body: subjectsState.when(
        data: (subjects) => classGroupsState.when(
          data: (classGroups) => roomsState.when(
            data: (rooms) => timeSlotsState.when(
              data: (timeSlots) => _buildForm(
                subjects: subjects,
                classGroups: classGroups,
                rooms: rooms,
                timeSlots: timeSlots,
                timetableSessions: timetableSessions,
                replacementSessions: replacementSessions,
                currentLecturerId: currentLecturerId,
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Center(child: Text('Error loading time slots: $e')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading rooms: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) =>
              Center(child: Text('Error loading class groups: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading subjects: $e')),
      ),
    );
  }

  Widget _buildForm({
    required List<SubjectModel> subjects,
    required List<ClassGroupModel> classGroups,
    required List<RoomModel> rooms,
    required List<TimeSlotModel> timeSlots,
    required List<TimetableSessionModel> timetableSessions,
    required List<ReplacementSessionModel> replacementSessions,
    required String currentLecturerId,
  }) {
    final theme = Theme.of(context);

    final inputDecorationTheme = InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Theme(
          data: Theme.of(
            context,
          ).copyWith(inputDecorationTheme: inputDecorationTheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subject
              DropdownButtonFormField<String>(
                initialValue: _selectedSubjectId,
                decoration: const InputDecoration(labelText: 'Subject'),
                items: subjects
                    .map(
                      (x) => DropdownMenuItem(
                        value: x.subjectId,
                        child: Text('${x.code} — ${x.name}'),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedSubjectId = val),
                validator: (val) =>
                    val == null ? 'Please select a subject' : null,
              ),
              const SizedBox(height: 20),

              // Class Group
              DropdownButtonFormField<String>(
                initialValue: _selectedClassGroupId,
                decoration: const InputDecoration(labelText: 'Class Group'),
                items: classGroups
                    .map(
                      (x) => DropdownMenuItem(
                        value: x.classGroupId,
                        child: Text(x.name),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedClassGroupId = val),
                validator: (val) =>
                    val == null ? 'Please select a class group' : null,
              ),
              const SizedBox(height: 20),

              // Room
              DropdownButtonFormField<String>(
                initialValue: _selectedRoomId,
                decoration: const InputDecoration(labelText: 'Room (Venue)'),
                items: rooms
                    .map(
                      (x) => DropdownMenuItem(
                        value: x.roomId,
                        child: Text(x.name),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() {
                  _selectedRoomId = val;
                  // Availability depends on the room — reset slot selection.
                  _selectedStartSlotId = null;
                  _selectedEndSlotId = null;
                }),
                validator: (val) => val == null ? 'Please select a room' : null,
              ),
              const SizedBox(height: 20),

              // Date Picker
              FormField<DateTime>(
                initialValue: _selectedDate,
                validator: (_) =>
                    _selectedDate == null ? 'Please select a date' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: field.hasError
                                ? Colors.redAccent
                                : Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: _selectedDate != null
                                  ? const Color(0xFF172033)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDate != null
                                  ? _formatDate(_selectedDate!)
                                  : 'Select Replacement Date',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDate != null
                                    ? const Color(0xFF172033)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 12),
                        child: Text(
                          field.errorText!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Availability-aware time slot picker
              _buildSlotPicker(
                timeSlots: timeSlots,
                timetableSessions: timetableSessions,
                replacementSessions: replacementSessions,
                currentLecturerId: currentLecturerId,
              ),
              const SizedBox(height: 24),

              // Reason
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Replacement',
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Please enter a reason'
                    : null,
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSaving ? null : () => _submit(timeSlots),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit for Approval',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Slot picker UI ──────────────────────────────────────────────────────

  Widget _buildSlotPicker({
    required List<TimeSlotModel> timeSlots,
    required List<TimetableSessionModel> timetableSessions,
    required List<ReplacementSessionModel> replacementSessions,
    required String currentLecturerId,
  }) {
    final theme = Theme.of(context);

    // Gate the picker until both determinants of availability are chosen.
    if (_selectedRoomId == null || _selectedDate == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, size: 18, color: Color(0xFF64748B)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Select a room and date to see which time slots are available.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      );
    }

    final sorted = [...timeSlots]..sort((a, b) => a.slotNo.compareTo(b.slotNo));

    ({bool busy, String? reason}) availOf(TimeSlotModel s) => _slotAvailability(
      s,
      timetable: timetableSessions,
      replacements: replacementSessions,
      allSlots: timeSlots,
      lecturerId: currentLecturerId,
      roomId: _selectedRoomId!,
      date: _selectedDate!,
    );
    bool isBusy(TimeSlotModel s) => availOf(s).busy;

    final freeCount = sorted.where((s) => !isBusy(s)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Available Time Slots',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
            Text(
              '$freeCount free',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap a free slot to set the start, then tap another to set the end of the range.',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 10),

        // Legend
        Row(
          children: [
            _legendDot(Colors.white, const Color(0xFFCBD5E1), 'Available'),
            const SizedBox(width: 16),
            _legendDot(theme.colorScheme.primary, theme.colorScheme.primary,
                'Selected'),
            const SizedBox(width: 16),
            _legendDot(
                const Color(0xFFF1F5F9), const Color(0xFFE2E8F0), 'Busy'),
          ],
        ),
        const SizedBox(height: 12),

        if (freeCount == 0)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Row(
              children: [
                Icon(Icons.event_busy_outlined,
                    size: 18, color: Color(0xFFB91C1C)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No free slots for this room on this date. Try another room or date.',
                    style: TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
                  ),
                ),
              ],
            ),
          ),

        ...sorted.map((slot) {
          final avail = availOf(slot);
          final selected = _isSlotSelected(slot, timeSlots);
          return _slotTile(
            slot: slot,
            busy: avail.busy,
            reason: avail.reason,
            selected: selected,
            onTap: () => _onSlotTap(slot, timeSlots, isBusy),
          );
        }),
      ],
    );
  }

  Widget _legendDot(Color fill, Color border, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: border),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _slotTile({
    required TimeSlotModel slot,
    required bool busy,
    required String? reason,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    final Color bg;
    final Color borderColor;
    if (busy) {
      bg = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFE2E8F0);
    } else if (selected) {
      bg = theme.colorScheme.primary.withValues(alpha: 0.12);
      borderColor = theme.colorScheme.primary;
    } else {
      bg = Colors.white;
      borderColor = const Color(0xFFCBD5E1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Slot number badge
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: busy
                        ? const Color(0xFFE2E8F0)
                        : selected
                            ? theme.colorScheme.primary
                            : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${slot.slotNo}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: busy
                          ? const Color(0xFF94A3B8)
                          : selected
                              ? Colors.white
                              : theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Slot label + time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Slot ${slot.slotNo}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: busy
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${slot.startTime} – ${slot.endTime}',
                        style: TextStyle(
                          fontSize: 12,
                          color: busy
                              ? const Color(0xFFB6C2D2)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Trailing status
                if (busy)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 14, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        reason ?? 'Busy',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  )
                else if (selected)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Selected',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Returns a conflict description string if there is an overlap, or null if clear.
  String? _checkConflict({
    required List<TimetableSessionModel> timetableSessions,
    required List<ReplacementSessionModel> replacementSessions,
    required List<TimeSlotModel> timeSlots,
    required String lecturerId,
    required String roomId,
    required String replacementDate,
    required String startSlotId,
    required String endSlotId,
  }) {
    final date = DateTime.parse(replacementDate);
    final dayOfWeek = date.weekday; // 1 = Monday … 7 = Sunday

    int slotNo(String id) => _slotNoOf(id, timeSlots);

    final newStart = slotNo(startSlotId);
    final newEnd = slotNo(endSlotId);

    bool overlaps(String aStart, String aEnd) {
      final aS = slotNo(aStart);
      final aE = slotNo(aEnd);
      return newStart <= aE && aS <= newEnd;
    }

    // Check against recurring timetable sessions on the same weekday
    for (final s in timetableSessions) {
      if (s.status.toLowerCase() != 'active') continue;
      if (s.dayOfWeek != dayOfWeek) continue;
      if (!overlaps(s.startSlotId, s.endSlotId)) continue;

      if (s.roomId == roomId) {
        return 'Room conflict: this room is already used at that time on ${_formatDate(date)}.';
      }
      if (s.lecturerId == lecturerId) {
        return 'Schedule conflict: you already have a class at that time on ${_formatDate(date)}.';
      }
    }

    // Check against other replacement sessions on the same date
    for (final s in replacementSessions) {
      if (s.replacementDate != replacementDate) continue;
      if (s.status == ReplacementSessionStatus.rejected.value) continue;
      if (s.status == ReplacementSessionStatus.cancelled.value) continue;
      if (!overlaps(s.startSlotId, s.endSlotId)) continue;

      if (s.roomId == roomId) {
        return 'Room conflict: this room already has a replacement class booked on ${_formatDate(date)}.';
      }
      if (s.lecturerId == lecturerId) {
        return 'Schedule conflict: you already have a replacement class at that time on ${_formatDate(date)}.';
      }
    }

    return null;
  }

  void _submit(List<TimeSlotModel> timeSlots) async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedStartSlotId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an available time slot.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // A single-slot booking is allowed: end defaults to the start.
    final effectiveEndSlotId = _selectedEndSlotId ?? _selectedStartSlotId!;

    final user = ref.read(authProvider);
    final lecturers = ref.read(lecturersProvider).value ?? [];
    final currentLecturer = lecturers.firstWhere(
      (l) => l.userUid == user?.uid,
      orElse: () => LecturerModel(
        lecturerId: '',
        userUid: '',
        fullName: '',
        email: '',
        status: '',
      ),
    );

    if (currentLecturer.lecturerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No lecturer record found for your account.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Safety net: re-validate against the latest data in case it changed
    // since the slot grid was rendered.
    final timetableSessions = ref.read(timetableSessionsProvider).value ?? [];
    final replacementSessions =
        ref.read(replacementSessionsProvider).value ?? [];
    final conflict = _checkConflict(
      timetableSessions: timetableSessions,
      replacementSessions: replacementSessions,
      timeSlots: timeSlots,
      lecturerId: currentLecturer.lecturerId,
      roomId: _selectedRoomId!,
      replacementDate: _toDateString(_selectedDate!),
      startSlotId: _selectedStartSlotId!,
      endSlotId: effectiveEndSlotId,
    );

    if (conflict != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(conflict),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref
          .read(replacementSessionServiceProvider)
          .createSession(
            lecturerId: currentLecturer.lecturerId,
            subjectId: _selectedSubjectId!,
            classGroupId: _selectedClassGroupId!,
            roomId: _selectedRoomId!,
            replacementDate: _toDateString(_selectedDate!),
            startSlotId: _selectedStartSlotId!,
            endSlotId: effectiveEndSlotId,
            reason: _reasonController.text.trim(),
            createdByUid: user!.uid,
          );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Replacement class submitted for approval.'),
        ),
      );
      navigator.pop();
    } catch (e) {
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error submitting session: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
