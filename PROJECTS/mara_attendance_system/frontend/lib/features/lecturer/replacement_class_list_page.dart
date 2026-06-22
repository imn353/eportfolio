import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_models.dart';
import '../../core/firestore/firestore_schema.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/providers/replacement_session_provider.dart';
import '../dashboard/widgets/app_drawer.dart';
import 'replacement_class_booking_page.dart';
import '../notifications/widgets/notification_bell.dart';

class ReplacementClassListPage extends ConsumerStatefulWidget {
  const ReplacementClassListPage({super.key});

  @override
  ConsumerState<ReplacementClassListPage> createState() =>
      _ReplacementClassListPageState();
}

class _ReplacementClassListPageState
    extends ConsumerState<ReplacementClassListPage> {
  // Filter state — applied only for admin / HOD viewers
  DateTime? _filterDate;
  String? _filterTimeSlotId;
  String? _filterRoomId;
  String? _filterStatus; // ReplacementSessionStatus.value or null

  String _toDateString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatDateForChip(DateTime d) {
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
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _filterDate = picked);
    }
  }

  void _resetFilters() {
    setState(() {
      _filterDate = null;
      _filterTimeSlotId = null;
      _filterRoomId = null;
      _filterStatus = null;
    });
  }

  bool get _hasActiveFilters =>
      _filterDate != null ||
      _filterTimeSlotId != null ||
      _filterRoomId != null ||
      _filterStatus != null;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);

    // All ref.watch() calls at the top level — never inside when() callbacks
    final sessionsState = ref.watch(replacementSessionsProvider);
    final lecturersState = ref.watch(lecturersProvider);
    final subjectsState = ref.watch(subjectsProvider);
    final classGroupsState = ref.watch(classGroupsProvider);
    final roomsState = ref.watch(roomsProvider);
    final timeSlotsState = ref.watch(timeSlotsProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isLecturer = user.role == UserRole.lecturer;
    final isAdmin = user.role == UserRole.admin;
    final showFilters = !isLecturer; // admin + HOD see the filter bar

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Replacement Classes',
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
      drawer: const AppDrawer(currentPage: 'replacement'),
      floatingActionButton: isLecturer
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReplacementClassBookingPage(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Book Replacement'),
            )
          : null,
      body: sessionsState.when(
        data: (allSessions) {
          final lecturers = lecturersState.value ?? [];
          final subjects = subjectsState.value ?? [];
          final classGroups = classGroupsState.value ?? [];
          final rooms = roomsState.value ?? [];
          final timeSlots = timeSlotsState.value ?? [];

          // For lecturer: filter locally by lecturerId to avoid needing a composite Firestore index
          List<ReplacementSessionModel> sessions = allSessions;
          if (isLecturer) {
            final currentLecturer = lecturers
                .where((l) => l.userUid == user.uid)
                .toList();
            if (lecturers.isNotEmpty && currentLecturer.isEmpty) {
              return _buildNoLecturerState();
            }
            if (currentLecturer.isNotEmpty) {
              sessions = allSessions
                  .where(
                    (s) => s.lecturerId == currentLecturer.first.lecturerId,
                  )
                  .toList();
            }
          }

          // Apply user-controlled filters (admin / HOD only)
          List<ReplacementSessionModel> visible = sessions;
          if (showFilters) {
            if (_filterDate != null) {
              final dateStr = _toDateString(_filterDate!);
              visible = visible
                  .where((s) => s.replacementDate == dateStr)
                  .toList();
            }
            if (_filterTimeSlotId != null) {
              visible = visible
                  .where(
                    (s) =>
                        s.startSlotId == _filterTimeSlotId ||
                        s.endSlotId == _filterTimeSlotId,
                  )
                  .toList();
            }
            if (_filterRoomId != null) {
              visible = visible
                  .where((s) => s.roomId == _filterRoomId)
                  .toList();
            }
            if (_filterStatus != null) {
              visible = visible
                  .where((s) => s.status == _filterStatus)
                  .toList();
            }
          }

          return Column(
            children: [
              if (showFilters) _buildFiltersBar(rooms, timeSlots),
              Expanded(
                child: sessions.isEmpty
                    ? _buildEmptyState(isLecturer)
                    : visible.isEmpty
                    ? _buildNoMatchesState()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                        itemCount: visible.length,
                        itemBuilder: (context, index) {
                          return _ReplacementSessionCard(
                            session: visible[index],
                            subjects: subjects,
                            classGroups: classGroups,
                            rooms: rooms,
                            timeSlots: timeSlots,
                            lecturers: lecturers,
                            showLecturerName: !isLecturer,
                            isLecturerView: isLecturer,
                            isAdminView: isAdmin,
                            reviewerUid: user.uid,
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error loading sessions: $e')),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter bar — admin / HOD only
  // ---------------------------------------------------------------------------

  Widget _buildFiltersBar(
    List<RoomModel> rooms,
    List<TimeSlotModel> timeSlots,
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Date filter (uses date picker behind a chip-styled button)
            _FilterChipButton(
              icon: Icons.calendar_today_outlined,
              label: _filterDate == null
                  ? 'All Dates'
                  : _formatDateForChip(_filterDate!),
              isActive: _filterDate != null,
              onTap: _pickFilterDate,
              onClear: _filterDate != null
                  ? () => setState(() => _filterDate = null)
                  : null,
            ),
            const SizedBox(width: 12),

            // Status filter
            _FilterDropdown<String>(
              icon: Icons.flag_outlined,
              value: _filterStatus,
              hint: 'All Statuses',
              items: const [
                DropdownMenuItem(value: null, child: Text('All Statuses')),
                DropdownMenuItem(
                  value: 'pending_approval',
                  child: Text('Pending Approval'),
                ),
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (v) => setState(() => _filterStatus = v),
            ),
            const SizedBox(width: 12),

            // Room (place) filter
            _FilterDropdown<String>(
              icon: Icons.room_outlined,
              value: _filterRoomId,
              hint: 'All Rooms',
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Rooms'),
                ),
                ...rooms.map(
                  (r) => DropdownMenuItem<String>(
                    value: r.roomId,
                    child: Text(r.name),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _filterRoomId = v),
            ),
            const SizedBox(width: 12),

            // Time slot filter
            _FilterDropdown<String>(
              icon: Icons.schedule_outlined,
              value: _filterTimeSlotId,
              hint: 'All Slots',
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All Slots'),
                ),
                ...timeSlots.map(
                  (t) => DropdownMenuItem<String>(
                    value: t.timeSlotId,
                    child: Text('Slot ${t.slotNo} (${t.startTime})'),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _filterTimeSlotId = v),
            ),

            if (_hasActiveFilters) ...[
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Reset'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoMatchesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_off_outlined,
              size: 56,
              color: Colors.grey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No replacements match these filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Reset filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isLecturer) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.swap_horiz_outlined,
              size: 64,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Replacement Classes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isLecturer
                  ? 'Tap "Book Replacement" to schedule a replacement class.'
                  : 'No replacement classes have been booked yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLecturerState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.orangeAccent),
            SizedBox(height: 16),
            Text(
              'Lecturer Record Not Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF172033),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No active lecturer record is linked to your account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplacementSessionCard extends ConsumerWidget {
  final ReplacementSessionModel session;
  final List<SubjectModel> subjects;
  final List<ClassGroupModel> classGroups;
  final List<RoomModel> rooms;
  final List<TimeSlotModel> timeSlots;
  final List<LecturerModel> lecturers;
  final bool showLecturerName;

  /// Whether this card belongs to the lecturer (shows cancel button when applicable)
  final bool isLecturerView;

  /// Whether the current user is an admin (shows approve/reject on pending items)
  final bool isAdminView;

  /// UID of the user reviewing the request (used when admin approves/rejects)
  final String reviewerUid;

  const _ReplacementSessionCard({
    required this.session,
    required this.subjects,
    required this.classGroups,
    required this.rooms,
    required this.timeSlots,
    required this.lecturers,
    required this.showLecturerName,
    required this.isLecturerView,
    required this.isAdminView,
    required this.reviewerUid,
  });

  String _formatDisplayDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
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
    final month = int.tryParse(parts[1]);
    final monthName = (month != null && month >= 1 && month <= 12)
        ? months[month - 1]
        : parts[1];
    return '${parts[2]} $monthName ${parts[0]}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    final classGroup = classGroups.firstWhere(
      (c) => c.classGroupId == session.classGroupId,
      orElse: () => ClassGroupModel(
        classGroupId: session.classGroupId,
        name: session.classGroupId,
        programName: '',
        intake: '',
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

    final lecturer = lecturers.firstWhere(
      (l) => l.lecturerId == session.lecturerId,
      orElse: () => LecturerModel(
        lecturerId: session.lecturerId,
        userUid: '',
        fullName: 'Unknown Lecturer',
        email: '',
        status: 'active',
      ),
    );

    // Status display helpers
    final status = session.status;
    final isPending = status == ReplacementSessionStatus.pendingApproval.value;
    final isApproved = status == ReplacementSessionStatus.approved.value;
    final isRejected = status == ReplacementSessionStatus.rejected.value;
    final isCancelled = status == ReplacementSessionStatus.cancelled.value;
    final canCancel = isPending || isApproved;

    Color stripeColor;
    Color chipBg;
    Color chipText;
    String chipLabel;
    if (isPending) {
      stripeColor = const Color(0xFFF59E0B);
      chipBg = const Color(0xFFFEF3C7);
      chipText = const Color(0xFF92400E);
      chipLabel = 'Pending Approval';
    } else if (isApproved) {
      stripeColor = const Color(0xFF10B981);
      chipBg = const Color(0xFFD1FAE5);
      chipText = const Color(0xFF065F46);
      chipLabel = 'Approved';
    } else if (isRejected) {
      stripeColor = const Color(0xFFEF4444);
      chipBg = const Color(0xFFFEE2E2);
      chipText = const Color(0xFF991B1B);
      chipLabel = 'Rejected';
    } else {
      stripeColor = const Color(0xFFCBD5E1);
      chipBg = const Color(0xFFF1F5F9);
      chipText = const Color(0xFF64748B);
      chipLabel = isCancelled ? 'Cancelled' : status;
    }

    return Card(
      color: Colors.white,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status stripe
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: stripeColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: subject code + status chip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${subject.code} — ${subject.name}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172033),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: chipBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            chipLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: chipText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Class group badge
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
                        classGroup.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    _iconRow(
                      Icons.calendar_today_outlined,
                      _formatDisplayDate(session.replacementDate),
                    ),
                    const SizedBox(height: 6),
                    _iconRow(
                      Icons.schedule_outlined,
                      '${startSlot.startTime} — ${endSlot.endTime}',
                    ),
                    const SizedBox(height: 6),
                    _iconRow(Icons.room_outlined, room.name),

                    if (showLecturerName) ...[
                      const SizedBox(height: 6),
                      _iconRow(Icons.person_outline, lecturer.fullName),
                    ],

                    if (session.reason.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 10),
                      Text(
                        '"${session.reason}"',
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],

                    // Rejection reason (shown when rejected)
                    if (isRejected &&
                        session.rejectionReason != null &&
                        session.rejectionReason!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Rejection reason: ${session.rejectionReason}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Admin approve/reject row — pending items only, admin viewer only
                    if (isAdminView && isPending) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _confirmReject(context, ref),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _confirmApprove(context, ref),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],

                    // Cancel button — only for lecturer view and when session is still cancellable
                    if (isLecturerView && canCancel) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _confirmCancel(context, ref),
                          icon: const Icon(Icons.cancel_outlined, size: 16),
                          label: const Text('Cancel Session'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Replacement Class'),
        content: const Text(
          'Are you sure you want to cancel this replacement class? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(replacementSessionServiceProvider)
                    .cancelSession(session.replacementSessionId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Replacement class cancelled.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error cancelling session: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );
  }

  void _confirmApprove(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Replacement Class'),
        content: const Text('Approve this replacement class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(replacementSessionServiceProvider)
                    .approveSession(session.replacementSessionId, reviewerUid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Replacement class approved.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error approving: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _confirmReject(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Replacement Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reject this replacement class?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref
                    .read(replacementSessionServiceProvider)
                    .rejectSession(
                      session.replacementSessionId,
                      reviewerUid,
                      reasonController.text,
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Replacement class rejected.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error rejecting: $e'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bar widgets (admin / HOD only)
// ---------------------------------------------------------------------------

/// Chip-styled button used for the date filter. Tapping opens the date picker;
/// when a date is active, an "x" appears to clear it.
class _FilterChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterChipButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9);
    final fg = isActive ? const Color(0xFF075985) : const Color(0xFF475569);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: 4),
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 14, color: fg),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Chip-styled dropdown used for status / room / time-slot filters.
class _FilterDropdown<T> extends StatelessWidget {
  final IconData icon;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T?>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.icon,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = value != null;
    final bg = isActive ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9);
    final fg = isActive ? const Color(0xFF075985) : const Color(0xFF475569);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          DropdownButtonHideUnderline(
            child: DropdownButton<T?>(
              value: value,
              hint: Text(
                hint,
                style: TextStyle(
                  fontSize: 13,
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              isDense: true,
              icon: Icon(Icons.arrow_drop_down, size: 18, color: fg),
              style: TextStyle(
                fontSize: 13,
                color: fg,
                fontWeight: FontWeight.w600,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
