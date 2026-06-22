import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore/firestore_models.dart';
import '../../core/firestore/firestore_schema.dart';
import '../../core/providers/report_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../notifications/widgets/notification_bell.dart';

class LecturerClassDetailPage extends ConsumerStatefulWidget {
  final LecturerClassData classData;

  const LecturerClassDetailPage({super.key, required this.classData});

  @override
  ConsumerState<LecturerClassDetailPage> createState() =>
      _LecturerClassDetailPageState();
}

class _LecturerClassDetailPageState
    extends ConsumerState<LecturerClassDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Student search
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // Session date filter
  String? _dateFrom;
  String? _dateTo;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(
      () =>
          setState(() => _searchQuery = _searchCtrl.text.trim().toLowerCase()),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classData = widget.classData;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Class Detail',
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
      ),
      body: Column(
        children: [
          _buildHeader(classData),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0B3A8D),
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicatorColor: const Color(0xFF0B3A8D),
              indicatorWeight: 2,
              labelPadding: EdgeInsets.zero,
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(height: 40, text: 'Students'),
                Tab(height: 40, text: 'Sessions'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentTab(classData),
                _buildSessionTab(classData),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Compact Header ────────────────────────────────────────────────────────
  Widget _buildHeader(LecturerClassData classData) {
    final mt = classData.moduleType;
    final mtLabel = mt.isNotEmpty ? mt[0].toUpperCase() + mt.substring(1) : '–';
    final avgPct = classData.averageAttendancePercentage;
    final avgColor = avgPct >= 80
        ? const Color(0xFF0B3A8D)
        : const Color(0xFFEF4444);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single Row: Code + Name (Left) and Tags (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Code and Name
              Expanded(
                child: Row(
                  children: [
                    Text(
                      classData.subjectCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B3A8D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        classData.subjectName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF172033),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right: Tags
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _tag(
                    classData.classGroupId,
                    const Color(0xFF475569),
                    const Color(0xFFF1F5F9),
                  ),
                  const SizedBox(width: 6),
                  _tag(
                    mtLabel,
                    mt == 'industry'
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFF2563EB),
                    mt == 'industry'
                        ? const Color(0xFFF5F3FF)
                        : const Color(0xFFEFF6FF),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row 2: summary cards
          Row(
            children: [
              _buildMiniStatCard(
                icon: Icons.people_alt_outlined,
                value: '${classData.totalStudents}',
                label: 'Students',
                color: const Color(0xFF0B3A8D),
              ),
              const SizedBox(width: 6),
              _buildMiniStatCard(
                icon: Icons.calendar_today_outlined,
                value: '${classData.totalSessions}',
                label: 'Sessions',
                color: const Color(0xFF0B3A8D),
              ),
              const SizedBox(width: 6),
              _buildMiniStatCard(
                value: '${avgPct.toStringAsFixed(0)}%',
                label: 'Avg Attend.',
                color: avgColor,
                progressValue: avgPct / 100.0,
                statusText: avgPct >= 80 ? 'High' : 'Low',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
    ),
  );

  Widget _buildMiniStatCard({
    IconData? icon,
    required String value,
    required String label,
    required Color color,
    double? progressValue,
    String? statusText,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left graphic (Circle Icon or Circular Progress)
            if (progressValue != null)
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progressValue,
                      strokeWidth: 3,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.1),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              )
            else if (icon != null)
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            const SizedBox(width: 8),
            // Right text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    statusText ?? value,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: statusText != null
                          ? color
                          : const Color(0xFF172033),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Student Tab ───────────────────────────────────────────────────────────
  Widget _buildStudentTab(LecturerClassData classData) {
    final studentsAsync = ref.watch(studentsProvider);
    return studentsAsync.when(
      data: (all) {
        final students =
            all.where((s) => s.classGroupId == classData.classGroupId).toList()
              ..sort(
                (a, b) => a.fullName.toLowerCase().compareTo(
                  b.fullName.toLowerCase(),
                ),
              );

        if (students.isEmpty) {
          return _emptyState('No students enrolled in this class.');
        }

        final stats = _calcStats(students, classData);
        final filtered = _searchQuery.isEmpty
            ? students
            : students
                  .where(
                    (s) =>
                        s.fullName.toLowerCase().contains(_searchQuery) ||
                        s.matricNo.toLowerCase().contains(_searchQuery),
                  )
                  .toList();

        return Column(
          children: [
            // ── Search bar (single compact row)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search name or matric…',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFCBD5E1),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            size: 16,
                            color: Color(0xFF94A3B8),
                          ),
                          onPressed: _searchCtrl.clear,
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF0B3A8D)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Text(
                    '${filtered.length}/${students.length} students',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? _emptyState('No match. Try a different search.')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final s = filtered[i];
                        return _buildStudentRow(
                          s,
                          stats[s.studentId],
                          students.indexOf(s) + 1,
                          classData.totalSessions,
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _emptyState('Error loading students.'),
    );
  }

  Map<String, _StudentStats> _calcStats(
    List<StudentModel> students,
    LecturerClassData classData,
  ) {
    final map = <String, _StudentStats>{};
    for (var s in students) {
      map[s.studentId] = _StudentStats();
    }
    for (var record in classData.records) {
      for (var entry in record.students) {
        final s = map[entry.studentId];
        if (s == null) continue;
        switch (entry.status) {
          case AttendanceStatus.present:
            s.present++;
            break;
          case AttendanceStatus.late:
            s.late++;
            break;
          case AttendanceStatus.absent:
            s.absent++;
            break;
          case AttendanceStatus.mc:
            s.mc++;
            break;
          case AttendanceStatus.ck:
            s.ck++;
            break;
        }
        s.sessions++;
      }
    }
    return map;
  }

  /// Single slim row: index | name+matric | attendance summary
  Widget _buildStudentRow(
    StudentModel student,
    _StudentStats? s,
    int index,
    int totalSessions,
  ) {
    final hasIssues = s != null && (s.absent > 0 || s.mc > 0 || s.ck > 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasIssues
              ? const Color(0xFFFECDD3).withValues(alpha: 0.8)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        children: [
          // Green accent line
          Container(
            width: 4,
            height: 32,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B3A8D),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Index
          SizedBox(
            width: 24,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: hasIssues
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF0B3A8D),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),

          // Name + matric
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
                Text(
                  student.matricNo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          // Attendance summary
          if (s != null && s.sessions > 0) _buildAttSummary(s),
        ],
      ),
    );
  }

  /// Shows "(present+late)/sessions" and extra chips only when issues exist.
  Widget _buildAttSummary(_StudentStats s) {
    final attended = s.present + s.late;
    final hasIssues = s.absent > 0 || s.mc > 0 || s.ck > 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main fraction
        _chip(
          '$attended/${s.sessions}',
          hasIssues ? const Color(0xFFEF4444) : const Color(0xFF10B981),
          hasIssues ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        ),
        // Late pill — only if late > 0
        if (s.late > 0) ...[
          const SizedBox(width: 4),
          _chip(
            'Late:${s.late}',
            const Color(0xFF14B8A6),
            const Color(0xFFF0FDFA),
          ),
        ],
        // MC — only if mc > 0
        if (s.mc > 0) ...[
          const SizedBox(width: 4),
          _chip('MC:${s.mc}', const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
        ],
        // Absent — only if absent > 0
        if (s.absent > 0) ...[
          const SizedBox(width: 4),
          _chip(
            'Abs:${s.absent}',
            const Color(0xFFEF4444),
            const Color(0xFFFEF2F2),
          ),
        ],
        // CK — only if ck > 0
        if (s.ck > 0) ...[
          const SizedBox(width: 4),
          _chip('CK:${s.ck}', const Color(0xFF6366F1), const Color(0xFFEEF2FF)),
        ],
      ],
    );
  }

  Widget _chip(String text, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: fg),
    ),
  );

  // ── Session Tab ───────────────────────────────────────────────────────────
  Widget _buildSessionTab(LecturerClassData classData) {
    final records = classData.records;
    if (records.isEmpty) return _emptyState('No sessions recorded yet.');

    final filtered = records.where((r) {
      if (_dateFrom != null && r.attendanceDate.compareTo(_dateFrom!) < 0) {
        return false;
      }
      if (_dateTo != null && r.attendanceDate.compareTo(_dateTo!) > 0) {
        return false;
      }
      return true;
    }).toList();

    final isFiltered = _dateFrom != null || _dateTo != null;

    return Column(
      children: [
        // ── Date filter — single compact row ──────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Row(
            children: [
              Expanded(
                child: _dateChip(
                  label: _dateFrom ?? 'From',
                  isSet: _dateFrom != null,
                  onTap: () => _pickDate(
                    context,
                    initial: _dateFrom,
                    onPicked: (d) => setState(() => _dateFrom = d),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '–',
                  style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                ),
              ),
              Expanded(
                child: _dateChip(
                  label: _dateTo ?? 'To',
                  isSet: _dateTo != null,
                  onTap: () => _pickDate(
                    context,
                    initial: _dateTo,
                    onPicked: (d) => setState(() => _dateTo = d),
                  ),
                ),
              ),
              if (isFiltered) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() => _dateFrom = _dateTo = null),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 14,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Text(
                '${filtered.length}/${records.length} sessions',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _emptyState('No sessions in this date range.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) =>
                      _buildSessionRow(filtered[i], classData),
                ),
        ),
      ],
    );
  }

  Widget _dateChip({
    required String label,
    required bool isSet,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSet
              ? const Color(0xFF0B3A8D).withValues(alpha: 0.07)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSet
                ? const Color(0xFF0B3A8D).withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: isSet ? const Color(0xFF0B3A8D) : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSet ? FontWeight.w600 : FontWeight.w400,
                  color: isSet
                      ? const Color(0xFF0B3A8D)
                      : const Color(0xFFCBD5E1),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context, {
    required String? initial,
    required void Function(String) onPicked,
  }) async {
    DateTime? init;
    if (initial != null) {
      try {
        init = DateTime.parse(initial);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: init ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0B3A8D),
            onPrimary: Colors.white,
            onSurface: Color(0xFF172033),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      onPicked(picked.toIso8601String().split('T')[0]);
    }
  }

  /// Single-row session card: date | attended/total | issue chips (tappable)
  Widget _buildSessionRow(
    AttendanceRecordModel record,
    LecturerClassData classData,
  ) {
    final s = record.summary;
    final attended = s.presentCount + s.lateCount;
    final isWarning = s.attendancePercentage < 80;
    final mainColor = isWarning
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    final mainBg = isWarning
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFECFDF5);

    return GestureDetector(
      onTap: () => _showSessionStudentsSheet(record, classData),
      child: Container(
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isWarning
                ? const Color(0xFFFECDD3).withValues(alpha: 0.7)
                : const Color(0xFFF1F5F9),
          ),
        ),
        child: Row(
          children: [
            // Blue accent line
            Container(
              width: 4,
              height: 24,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B3A8D),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Date
            const Icon(
              Icons.event_outlined,
              size: 15,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(width: 5),
            Text(
              record.attendanceDate,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF172033),
              ),
            ),
            const Spacer(),

            // Attended fraction
            _chip('$attended/${s.totalStudents}', mainColor, mainBg),

            // Issue chips — only when non-zero
            if (s.lateCount > 0) ...[
              const SizedBox(width: 4),
              _chip(
                'Late:${s.lateCount}',
                const Color(0xFF14B8A6),
                const Color(0xFFF0FDFA),
              ),
            ],
            if (s.mcCount > 0) ...[
              const SizedBox(width: 4),
              _chip(
                'MC:${s.mcCount}',
                const Color(0xFFF59E0B),
                const Color(0xFFFFFBEB),
              ),
            ],
            if (s.absentCount > 0) ...[
              const SizedBox(width: 4),
              _chip(
                'Abs:${s.absentCount}',
                const Color(0xFFEF4444),
                const Color(0xFFFEF2F2),
              ),
            ],
            if (s.ckCount > 0) ...[
              const SizedBox(width: 4),
              _chip(
                'CK:${s.ckCount}',
                const Color(0xFF6366F1),
                const Color(0xFFEEF2FF),
              ),
            ],

            // Chevron hint
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }

  // ── Session Student Sheet ─────────────────────────────────────────────────
  void _showSessionStudentsSheet(
    AttendanceRecordModel record,
    LecturerClassData classData,
  ) {
    final studentsAsync = ref.read(studentsProvider);
    final classStudents =
        studentsAsync.value
            ?.where((s) => s.classGroupId == classData.classGroupId)
            .toList() ??
        [];

    // Build a quick lookup map: studentId -> StudentModel
    final studentMap = {for (var s in classStudents) s.studentId: s};

    // Sort: present/late first, then by status, then by name
    final sessionStudents = List<AttendanceStudentModel>.from(record.students)
      ..sort((a, b) {
        const order = {
          'present': 0,
          'late': 1,
          'mc': 2,
          'ck': 3,
          'absent': 4,
        };
        final aO = order[a.status.value] ?? 5;
        final bO = order[b.status.value] ?? 5;
        if (aO != bO) return aO.compareTo(bO);
        final aName =
            studentMap[a.studentId]?.fullName.toLowerCase() ?? a.studentId;
        final bName =
            studentMap[b.studentId]?.fullName.toLowerCase() ?? b.studentId;
        return aName.compareTo(bName);
      });

    final summary = record.summary;
    final attended = summary.presentCount + summary.lateCount;
    final isWarning = summary.attendancePercentage < 80;
    final headerColor =
        isWarning ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // ── Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),

                  // ── Header card
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: headerColor.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: headerColor.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B3A8D).withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.event_note_rounded,
                                size: 20,
                                color: Color(0xFF0B3A8D),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Session Attendance',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF172033),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        record.attendanceDate,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Attendance rate badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: headerColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: headerColor.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$attended/${summary.totalStudents}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: headerColor,
                                    ),
                                  ),
                                  Text(
                                    '${summary.attendancePercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: headerColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Summary chips row
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (summary.presentCount > 0)
                              _statusSummaryChip(
                                'Present',
                                summary.presentCount,
                                const Color(0xFF10B981),
                                const Color(0xFFECFDF5),
                              ),
                            if (summary.lateCount > 0)
                              _statusSummaryChip(
                                'Late',
                                summary.lateCount,
                                const Color(0xFF14B8A6),
                                const Color(0xFFF0FDFA),
                              ),
                            if (summary.mcCount > 0)
                              _statusSummaryChip(
                                'MC',
                                summary.mcCount,
                                const Color(0xFFF59E0B),
                                const Color(0xFFFFFBEB),
                              ),
                            if (summary.absentCount > 0)
                              _statusSummaryChip(
                                'Absent',
                                summary.absentCount,
                                const Color(0xFFEF4444),
                                const Color(0xFFFEF2F2),
                              ),
                            if (summary.ckCount > 0)
                              _statusSummaryChip(
                                'CK',
                                summary.ckCount,
                                const Color(0xFF6366F1),
                                const Color(0xFFEEF2FF),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Student list
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                    child: Row(
                      children: [
                        Text(
                          '${sessionStudents.length} students',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: sessionStudents.isEmpty
                        ? const Center(
                            child: Text(
                              'No student data for this session.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollCtrl,
                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                            itemCount: sessionStudents.length,
                            itemBuilder: (_, i) {
                              final entry = sessionStudents[i];
                              final student = studentMap[entry.studentId];
                              return _buildSessionStudentRow(
                                index: i + 1,
                                studentName:
                                    student?.fullName ?? entry.studentId,
                                matricNo: student?.matricNo ?? '–',
                                status: entry.status,
                                remarks: entry.remarks,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusSummaryChip(
    String label,
    int count,
    Color fg,
    Color bg,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: fg,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$label · $count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      );

  Widget _buildSessionStudentRow({
    required int index,
    required String studentName,
    required String matricNo,
    required AttendanceStatus status,
    required String remarks,
  }) {
    final (statusLabel, statusFg, statusBg) = switch (status) {
      AttendanceStatus.present => (
        'Present',
        const Color(0xFF10B981),
        const Color(0xFFECFDF5),
      ),
      AttendanceStatus.late => (
        'Late',
        const Color(0xFF14B8A6),
        const Color(0xFFF0FDFA),
      ),
      AttendanceStatus.absent => (
        'Absent',
        const Color(0xFFEF4444),
        const Color(0xFFFEF2F2),
      ),
      AttendanceStatus.mc => (
        'MC',
        const Color(0xFFF59E0B),
        const Color(0xFFFFFBEB),
      ),
      AttendanceStatus.ck => (
        'CK',
        const Color(0xFF6366F1),
        const Color(0xFFEEF2FF),
      ),
    };

    final isIssue = status == AttendanceStatus.absent ||
        status == AttendanceStatus.mc ||
        status == AttendanceStatus.ck;

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isIssue
              ? statusFg.withValues(alpha: 0.18)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        children: [
          // Accent bar
          Container(
            width: 3,
            height: 30,
            margin: const EdgeInsets.only(right: 10),
            decoration: BoxDecoration(
              color: statusFg,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Index
          SizedBox(
            width: 22,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isIssue ? statusFg : const Color(0xFF0B3A8D),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Name + matric
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172033),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  matricNo,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF94A3B8),
                  ),
                ),
                if (remarks.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      remarks,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB45309),
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusFg.withValues(alpha: 0.25)),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusFg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        msg,
        style: const TextStyle(fontSize: 15, color: Color(0xFF94A3B8)),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

// ── Per-student stats ─────────────────────────────────────────────────────
class _StudentStats {
  int present = 0;
  int late = 0;
  int absent = 0;
  int mc = 0;
  int ck = 0;
  int sessions = 0;
}
