import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_models.dart';
import '../../../core/providers/replacement_session_provider.dart';

/// A card displaying one pending replacement-class request with
/// inline Approve and Reject actions. Used by both the admin
/// dashboard preview and the dedicated approvals page.
class PendingApprovalCard extends ConsumerStatefulWidget {
  final ReplacementSessionModel session;
  final List<SubjectModel> subjects;
  final List<LecturerModel> lecturers;
  final List<RoomModel> rooms;
  final List<TimeSlotModel> timeSlots;
  final List<ClassGroupModel> classGroups;
  final String reviewerUid;

  const PendingApprovalCard({
    super.key,
    required this.session,
    required this.subjects,
    required this.lecturers,
    required this.rooms,
    required this.timeSlots,
    required this.classGroups,
    required this.reviewerUid,
  });

  @override
  ConsumerState<PendingApprovalCard> createState() =>
      _PendingApprovalCardState();
}

class _PendingApprovalCardState extends ConsumerState<PendingApprovalCard> {
  bool _isProcessing = false;

  SubjectModel get _subject => widget.subjects.firstWhere(
    (s) => s.subjectId == widget.session.subjectId,
    orElse: () => SubjectModel(
      subjectId: '',
      code: '?',
      name: 'Unknown',
      moduleType: '',
      status: '',
    ),
  );
  LecturerModel get _lecturer => widget.lecturers.firstWhere(
    (l) => l.lecturerId == widget.session.lecturerId,
    orElse: () => LecturerModel(
      lecturerId: '',
      userUid: '',
      fullName: 'Unknown',
      email: '',
      status: '',
    ),
  );
  RoomModel get _room => widget.rooms.firstWhere(
    (r) => r.roomId == widget.session.roomId,
    orElse: () => RoomModel(
      roomId: '',
      name: widget.session.roomId,
      location: '',
      status: '',
    ),
  );
  ClassGroupModel get _classGroup => widget.classGroups.firstWhere(
    (c) => c.classGroupId == widget.session.classGroupId,
    orElse: () => ClassGroupModel(
      classGroupId: '',
      name: widget.session.classGroupId,
      programName: '',
      intake: '',
      status: '',
    ),
  );
  String get _timeRange {
    final start = widget.timeSlots.firstWhere(
      (t) => t.timeSlotId == widget.session.startSlotId,
      orElse: () => TimeSlotModel(
        timeSlotId: '',
        slotNo: 0,
        startTime: '--:--',
        endTime: '--:--',
        durationMinutes: 0,
        status: '',
      ),
    );
    final end = widget.timeSlots.firstWhere(
      (t) => t.timeSlotId == widget.session.endSlotId,
      orElse: () => TimeSlotModel(
        timeSlotId: '',
        slotNo: 0,
        startTime: '--:--',
        endTime: '--:--',
        durationMinutes: 0,
        status: '',
      ),
    );
    return '${start.startTime} — ${end.endTime}';
  }

  String _formatDate(String dateStr) {
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
    final m = int.tryParse(parts[1]);
    return '${parts[2]} ${(m != null && m >= 1 && m <= 12) ? months[m - 1] : parts[1]} ${parts[0]}';
  }

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Replacement Class'),
        content: Text(
          'Approve replacement for ${_subject.code} on ${_formatDate(widget.session.replacementDate)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(replacementSessionServiceProvider)
          .approveSession(
            widget.session.replacementSessionId,
            widget.reviewerUid,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Replacement Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reject replacement for ${_subject.code} on ${_formatDate(widget.session.replacementDate)}?',
            ),
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
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(replacementSessionServiceProvider)
          .rejectSession(
            widget.session.replacementSessionId,
            widget.reviewerUid,
            reasonController.text,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_subject.code} — ${_subject.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF172033),
                    ),
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
                    _classGroup.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _lecturer.fullName,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            _iconRow(
              Icons.calendar_today_outlined,
              _formatDate(widget.session.replacementDate),
            ),
            const SizedBox(height: 4),
            _iconRow(Icons.schedule_outlined, _timeRange),
            const SizedBox(height: 4),
            _iconRow(Icons.room_outlined, _room.name),
            if (widget.session.reason.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '"${widget.session.reason}"',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (_isProcessing)
              const Center(
                child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _reject,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _approve,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                    ),
                    child: const Text('Approve'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _iconRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
        ),
      ],
    ),
  );
}
