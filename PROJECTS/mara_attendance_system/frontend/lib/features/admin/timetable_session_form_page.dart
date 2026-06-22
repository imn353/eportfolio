import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_models.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/providers/timetable_provider.dart';
import '../notifications/widgets/notification_bell.dart';

class TimetableSessionFormPage extends ConsumerStatefulWidget {
  final TimetableSessionModel? session;

  const TimetableSessionFormPage({super.key, this.session});

  @override
  ConsumerState<TimetableSessionFormPage> createState() =>
      _TimetableSessionFormPageState();
}

class _TimetableSessionFormPageState
    extends ConsumerState<TimetableSessionFormPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedClassGroupId;
  String? _selectedSubjectId;
  String? _selectedLecturerId;
  String? _selectedRoomId;
  int? _selectedDayOfWeek;
  String? _selectedStartSlotId;
  String? _selectedEndSlotId;
  String _selectedStatus = 'active';

  bool _isSaving = false;

  final Map<int, String> _daysOfWeek = {
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
    // If editing, prefill the values
    if (widget.session != null) {
      _selectedClassGroupId = widget.session!.classGroupId;
      _selectedSubjectId = widget.session!.subjectId;
      _selectedLecturerId = widget.session!.lecturerId;
      _selectedRoomId = widget.session!.roomId;
      _selectedDayOfWeek = widget.session!.dayOfWeek;
      _selectedStartSlotId = widget.session!.startSlotId;
      _selectedEndSlotId = widget.session!.endSlotId;
      _selectedStatus = widget.session!.status.toLowerCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final classGroupsState = ref.watch(classGroupsProvider);
    final subjectsState = ref.watch(subjectsProvider);
    final lecturersState = ref.watch(timetableAssignableLecturersProvider);
    final roomsState = ref.watch(roomsProvider);
    final timeSlotsState = ref.watch(timeSlotsProvider);

    final isNew = widget.session == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          isNew ? 'Add Timetable Session' : 'Edit Timetable Session',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [NotificationBell()],
      ),
      body: classGroupsState.when(
        data: (classGroups) => subjectsState.when(
          data: (subjects) => lecturersState.when(
            data: (assignableLecturers) => roomsState.when(
              data: (rooms) => timeSlotsState.when(
                data: (timeSlots) => _buildForm(
                  classGroups: classGroups,
                  subjects: subjects,
                  assignableLecturers: assignableLecturers,
                  rooms: rooms,
                  timeSlots: timeSlots,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) =>
                    Center(child: Text('Error loading time slots: $e')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error loading rooms: $e')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading lecturers: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading subjects: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading class groups: $e')),
      ),
    );
  }

  Widget _buildForm({
    required List<ClassGroupModel> classGroups,
    required List<SubjectModel> subjects,
    required List<TimetableAssignableLecturer> assignableLecturers,
    required List<RoomModel> rooms,
    required List<TimeSlotModel> timeSlots,
  }) {
    final theme = Theme.of(context);

    // Form Dropdown Border Style
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
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Theme(
              data: Theme.of(
                context,
              ).copyWith(inputDecorationTheme: inputDecorationTheme),
              child: Column(
                children: [
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
                    onChanged: (val) =>
                        setState(() => _selectedClassGroupId = val),
                    validator: (val) =>
                        val == null ? 'Please select a Class Group' : null,
                  ),
                  const SizedBox(height: 20),

                  // Subject
                  DropdownButtonFormField<String>(
                    initialValue: _selectedSubjectId,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: subjects
                        .map(
                          (x) => DropdownMenuItem(
                            value: x.subjectId,
                            child: Text('${x.code} - ${x.name}'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedSubjectId = val),
                    validator: (val) =>
                        val == null ? 'Please select a Subject' : null,
                  ),
                  const SizedBox(height: 20),

                  // Lecturer
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLecturerId,
                    decoration: const InputDecoration(
                      labelText: 'Lecturer / teaching staff',
                    ),
                    items: assignableLecturers
                        .map(
                          (x) => DropdownMenuItem(
                            value: x.lecturer.lecturerId,
                            child: Text(x.dropdownLabel),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedLecturerId = val),
                    validator: (val) =>
                        val == null ? 'Please select a Lecturer' : null,
                  ),
                  const SizedBox(height: 20),

                  // Room
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRoomId,
                    decoration: const InputDecoration(labelText: 'Room'),
                    items: rooms
                        .map(
                          (x) => DropdownMenuItem(
                            value: x.roomId,
                            child: Text(x.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedRoomId = val),
                    validator: (val) =>
                        val == null ? 'Please select a Room' : null,
                  ),
                  const SizedBox(height: 20),

                  // Day of Week
                  DropdownButtonFormField<int>(
                    initialValue: _selectedDayOfWeek,
                    decoration: const InputDecoration(labelText: 'Day of Week'),
                    items: _daysOfWeek.entries
                        .map(
                          (x) => DropdownMenuItem(
                            value: x.key,
                            child: Text(x.value),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedDayOfWeek = val),
                    validator: (val) =>
                        val == null ? 'Please select a day' : null,
                  ),
                  const SizedBox(height: 20),

                  // Start Slot
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStartSlotId,
                    decoration: const InputDecoration(labelText: 'Start Slot'),
                    items: timeSlots
                        .map(
                          (x) => DropdownMenuItem(
                            value: x.timeSlotId,
                            child: Text('${x.timeSlotId} (${x.startTime})'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedStartSlotId = val),
                    validator: (val) =>
                        val == null ? 'Please select a start slot' : null,
                  ),
                  const SizedBox(height: 20),

                  // End Slot
                  DropdownButtonFormField<String>(
                    initialValue: _selectedEndSlotId,
                    decoration: const InputDecoration(labelText: 'End Slot'),
                    items: timeSlots
                        .map(
                          (x) => DropdownMenuItem(
                            value: x.timeSlotId,
                            child: Text('${x.timeSlotId} (${x.endTime})'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedEndSlotId = val),
                    validator: (val) =>
                        val == null ? 'Please select an end slot' : null,
                  ),
                  const SizedBox(height: 20),

                  // Status
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (val) =>
                        setState(() => _selectedStatus = val ?? 'active'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : () => _saveForm(timeSlots),
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
                      'Save Session',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveForm(List<TimeSlotModel> timeSlots) async {
    if (!_formKey.currentState!.validate()) return;

    // Strict slot range validation
    final startSlot = timeSlots.firstWhere(
      (x) => x.timeSlotId == _selectedStartSlotId,
    );
    final endSlot = timeSlots.firstWhere(
      (x) => x.timeSlotId == _selectedEndSlotId,
    );

    if (startSlot.slotNo > endSlot.slotNo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Validation Error: Start slot cannot be after the End slot.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref
          .read(timetableServiceProvider)
          .saveSession(
            originalSessionId: widget.session?.timetableSessionId,
            classGroupId: _selectedClassGroupId!,
            subjectId: _selectedSubjectId!,
            lecturerId: _selectedLecturerId!,
            roomId: _selectedRoomId!,
            dayOfWeek: _selectedDayOfWeek!,
            startSlotId: _selectedStartSlotId!,
            endSlotId: _selectedEndSlotId!,
            status: _selectedStatus,
          );

      messenger.showSnackBar(
        const SnackBar(content: Text('Timetable session saved successfully!')),
      );
      navigator.pop();
    } catch (e) {
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error saving session: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}
