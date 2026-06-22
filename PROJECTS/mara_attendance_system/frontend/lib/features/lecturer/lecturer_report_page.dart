import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../dashboard/widgets/app_drawer.dart';
import '../../core/providers/report_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/services/pdf_report_service.dart';
import '../../core/firestore/firestore_models.dart';
import 'lecturer_class_detail_page.dart';
import '../notifications/widgets/notification_bell.dart';

class LecturerReportPage extends ConsumerStatefulWidget {
  const LecturerReportPage({super.key});

  @override
  ConsumerState<LecturerReportPage> createState() => _LecturerReportPageState();
}

class _LecturerReportPageState extends ConsumerState<LecturerReportPage> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final classesAsync = ref.watch(filteredLecturerClassesProvider);
    final allClassesAsync = ref.watch(lecturerClassesProvider);

    // Current filter values
    final moduleTypeFilter = ref.watch(lecturerReportModuleTypeFilter);
    final subjectFilter = ref.watch(lecturerReportSubjectFilter);
    final classGroupFilter = ref.watch(lecturerReportClassGroupFilter);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Classes',
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
      drawer: const AppDrawer(currentPage: 'reports'),
      body: SafeArea(
        child: allClassesAsync.when(
          data: (allClasses) {
            // Extract unique values for filter dropdowns from ALL classes (not filtered)
            final moduleTypes =
                allClasses.map((c) => c.moduleType).toSet().toList()..sort();
            final subjects =
                allClasses
                    .map(
                      (c) => _SubjectOption(
                        c.subjectId,
                        c.subjectCode,
                        c.subjectName,
                      ),
                    )
                    .toSet()
                    .toList()
                  ..sort((a, b) => a.code.compareTo(b.code));
            final classGroups =
                allClasses.map((c) => c.classGroupId).toSet().toList()..sort();

            return classesAsync.when(
              data: (classes) {
                // Overall stats from filtered classes
                final avgAttendance = classes.isEmpty
                    ? 0.0
                    : classes
                              .map((c) => c.averageAttendancePercentage)
                              .reduce((a, b) => a + b) /
                          classes.length;
                final totalClasses = classes.length;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    // Summary cards
                    _buildSummaryCards(avgAttendance, totalClasses),
                    const SizedBox(height: 10),

                    // Single-row filters
                    _buildFilterRow(
                      context,
                      moduleTypes: moduleTypes,
                      subjects: subjects,
                      classGroups: classGroups,
                      currentModuleType: moduleTypeFilter,
                      currentSubject: subjectFilter,
                      currentClassGroup: classGroupFilter,
                    ),
                    const SizedBox(height: 10),

                    // Section title + Export PDF button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Classes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172033),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (moduleTypeFilter != null ||
                                subjectFilter != null ||
                                classGroupFilter != null)
                              TextButton.icon(
                                onPressed: () {
                                  ref
                                      .read(
                                        lecturerReportModuleTypeFilter.notifier,
                                      )
                                      .set(null);
                                  ref
                                      .read(
                                        lecturerReportSubjectFilter.notifier,
                                      )
                                      .set(null);
                                  ref
                                      .read(
                                        lecturerReportClassGroupFilter.notifier,
                                      )
                                      .set(null);
                                },
                                icon: const Icon(Icons.clear_all, size: 18),
                                label: const Text(
                                  'Clear Filters',
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF64748B),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                            _buildExportButton(classes),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (classes.isEmpty)
                      _buildEmptyState(
                        moduleTypeFilter != null ||
                                subjectFilter != null ||
                                classGroupFilter != null
                            ? 'No classes match the selected filters.'
                            : 'No attendance records yet.',
                      )
                    else
                      ...classes.map(
                        (classData) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildClassCard(context, classData),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _buildErrorState(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => _buildErrorState(),
        ),
      ),
    );
  }

  // ── Export PDF button ─────────────────────────────────────────
  Widget _buildExportButton(List<LecturerClassData> classes) {
    return Material(
      color: _isExporting
          ? const Color(0xFF0B3A8D).withValues(alpha: 0.06)
          : const Color(0xFF0B3A8D).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _isExporting ? null : () => _showExportOptionsDialog(classes),
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFF0B3A8D).withValues(alpha: 0.15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF0B3A8D).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isExporting)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF0B3A8D),
                  ),
                )
              else
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 16,
                  color: Color(0xFF0B3A8D),
                ),
              const SizedBox(width: 6),
              Text(
                _isExporting ? 'Generating...' : 'Export PDF',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0B3A8D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PDF generation logic ──────────────────────────────────────
  Future<void> _exportPdf(
    List<LecturerClassData> classes, {
    required bool includeSessionList,
    required bool includeStudentList,
  }) async {
    setState(() => _isExporting = true);

    try {
      final user = ref.read(authProvider);
      final moduleTypeFilter = ref.read(lecturerReportModuleTypeFilter);
      final subjectFilter = ref.read(lecturerReportSubjectFilter);
      final classGroupFilter = ref.read(lecturerReportClassGroupFilter);

      // Get student data if the user opted to include student list
      List<StudentModel> allStudents = [];
      if (includeStudentList) {
        final studentsAsync = ref.read(studentsProvider);
        allStudents = studentsAsync.value ?? [];
      }

      final pdfBytes = await PdfReportService.generateLecturerReport(
        lecturerName: user?.displayName ?? 'Unknown Lecturer',
        lecturerEmail: user?.email ?? '',
        classes: classes,
        activeModuleTypeFilter: moduleTypeFilter,
        activeSubjectFilter: subjectFilter,
        activeClassGroupFilter: classGroupFilter,
        includeSessionList: includeSessionList,
        includeStudentList: includeStudentList,
        allStudents: allStudents,
      );

      if (!mounted) return;

      // Show print / save dialog (works on web, mobile, desktop)
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'Lecturer_Attendance_Report',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  // ── Export options dialog ──────────────────────────────────────
  void _showExportOptionsDialog(List<LecturerClassData> classes) {
    bool includeSessionList = false;
    bool includeStudentList = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0B3A8D,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.picture_as_pdf_rounded,
                            size: 22,
                            color: Color(0xFF0B3A8D),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Export PDF Report',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF172033),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Choose what to include in your report',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Always included info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Color(0xFF16A34A),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Summary, class details & attendance breakdown are always included.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Toggle: Session List
                    _buildToggleOption(
                      icon: Icons.event_note_outlined,
                      title: 'Include Session List',
                      subtitle:
                          'Detailed attendance counts per session for each class',
                      value: includeSessionList,
                      onChanged: (val) =>
                          setModalState(() => includeSessionList = val),
                    ),
                    const SizedBox(height: 10),

                    // Toggle: Student List
                    _buildToggleOption(
                      icon: Icons.people_outline_rounded,
                      title: 'Include Student List',
                      subtitle:
                          'Enrolled student names and matric numbers per class',
                      value: includeStudentList,
                      onChanged: (val) =>
                          setModalState(() => includeStudentList = val),
                    ),
                    const SizedBox(height: 20),

                    // Generate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _exportPdf(
                            classes,
                            includeSessionList: includeSessionList,
                            includeStudentList: includeStudentList,
                          );
                        },
                        icon: const Icon(
                          Icons.picture_as_pdf_rounded,
                          size: 18,
                        ),
                        label: const Text(
                          'Generate PDF',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0B3A8D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: value
            ? const Color(0xFF0B3A8D).withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? const Color(0xFF0B3A8D).withValues(alpha: 0.25)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: value ? const Color(0xFF0B3A8D) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: value
                        ? const Color(0xFF0B3A8D)
                        : const Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF0B3A8D),
          ),
        ],
      ),
    );
  }

  // ── Summary cards ─────────────────────────────────────────────
  Widget _buildSummaryCards(double avgAttendance, int totalClasses) {
    final avgColor = avgAttendance >= 80
        ? const Color(0xFF0B3A8D)
        : const Color(0xFFEF4444);
    return Row(
      children: [
        // Avg Attendance Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: avgColor.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: avgColor.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: avgAttendance / 100.0,
                        strokeWidth: 4,
                        color: avgColor,
                        backgroundColor: avgColor.withValues(alpha: 0.1),
                      ),
                      Text(
                        '${avgAttendance.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: avgColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Avg Attendance',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        avgAttendance >= 80 ? 'High' : 'Low',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: avgColor,
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
        ),
        const SizedBox(width: 10),
        // Total Classes Card
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF0B3A8D).withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0B3A8D).withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B3A8D).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_outlined,
                    size: 22,
                    color: Color(0xFF0B3A8D),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Total Classes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalClasses',
                        style: const TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
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
        ),
      ],
    );
  }

  // ── Single-row filter bar ─────────────────────────────────────────────
  Widget _buildFilterRow(
    BuildContext context, {
    required List<String> moduleTypes,
    required List<_SubjectOption> subjects,
    required List<String> classGroups,
    required String? currentModuleType,
    required String? currentSubject,
    required String? currentClassGroup,
  }) {
    final anyActive =
        currentModuleType != null ||
        currentSubject != null ||
        currentClassGroup != null;
    return Row(
      children: [
        // Module Type
        Expanded(
          child: _buildFilterChip(
            label: currentModuleType != null
                ? _formatModuleType(currentModuleType)
                : 'Type',
            isActive: currentModuleType != null,
            expand: true,
            onTap: () => _showFilterBottomSheet(
              context,
              title: 'Module Type',
              options: moduleTypes,
              labelBuilder: _formatModuleType,
              currentValue: currentModuleType,
              onSelected: (v) =>
                  ref.read(lecturerReportModuleTypeFilter.notifier).set(v),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Subject
        Expanded(
          child: _buildFilterChip(
            label: currentSubject != null
                ? subjects
                      .firstWhere(
                        (s) => s.id == currentSubject,
                        orElse: () => _SubjectOption(
                          currentSubject,
                          currentSubject,
                          currentSubject,
                        ),
                      )
                      .code
                : 'Subject',
            isActive: currentSubject != null,
            expand: true,
            onTap: () => _showFilterBottomSheet(
              context,
              title: 'Subject',
              options: subjects.map((s) => s.id).toList(),
              labelBuilder: (v) {
                final m = subjects.firstWhere(
                  (s) => s.id == v,
                  orElse: () => _SubjectOption(v, v, v),
                );
                return '${m.code} — ${m.name}';
              },
              currentValue: currentSubject,
              onSelected: (v) =>
                  ref.read(lecturerReportSubjectFilter.notifier).set(v),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Class Group
        Expanded(
          child: _buildFilterChip(
            label: currentClassGroup ?? 'Group',
            isActive: currentClassGroup != null,
            expand: true,
            onTap: () => _showFilterBottomSheet(
              context,
              title: 'Class Group',
              options: classGroups,
              labelBuilder: (v) => v,
              currentValue: currentClassGroup,
              onSelected: (v) =>
                  ref.read(lecturerReportClassGroupFilter.notifier).set(v),
            ),
          ),
        ),
        // Clear all
        if (anyActive) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () {
              ref.read(lecturerReportModuleTypeFilter.notifier).set(null);
              ref.read(lecturerReportSubjectFilter.notifier).set(null);
              ref.read(lecturerReportClassGroupFilter.notifier).set(null);
            },
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
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    bool expand = false,
  }) {
    final chip = Material(
      color: isActive
          ? const Color(0xFF0B3A8D).withValues(alpha: 0.1)
          : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.black.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF0B3A8D).withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF0B3A8D)
                        : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: isActive
                    ? const Color(0xFF0B3A8D)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
    return expand ? chip : chip;
  }

  void _showFilterBottomSheet(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String Function(String) labelBuilder,
    required String? currentValue,
    required void Function(String?) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                      if (currentValue != null)
                        TextButton(
                          onPressed: () {
                            onSelected(null);
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                ...options.map((option) {
                  final isSelected = option == currentValue;
                  return ListTile(
                    leading: Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? const Color(0xFF0B3A8D)
                          : const Color(0xFF94A3B8),
                      size: 22,
                    ),
                    title: Text(
                      labelBuilder(option),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF0B3A8D)
                            : const Color(0xFF172033),
                      ),
                    ),
                    onTap: () {
                      onSelected(isSelected ? null : option);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Class Card (compact) ────────────────────────────────────────────────
  Widget _buildClassCard(BuildContext context, LecturerClassData classData) {
    final bool isWarning = classData.averageAttendancePercentage < 80.0;
    final Color badgeColor = isWarning
        ? const Color(0xFFEF4444)
        : const Color(0xFF10B981);
    final Color badgeBg = isWarning
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFECFDF5);
    final mt = classData.moduleType;
    final mtLabel = mt.isNotEmpty ? mt[0].toUpperCase() + mt.substring(1) : '–';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LecturerClassDetailPage(classData: classData),
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.black.withValues(alpha: 0.02),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top section with green accent line
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The green vertical accent line
                    Container(
                      width: 4,
                      margin: const EdgeInsets.only(
                        top: 2,
                        bottom: 2,
                        right: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B3A8D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // The text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Row 1: code + tags + badge
                          Row(
                            children: [
                              Text(
                                classData.subjectCode,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0B3A8D),
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildTag(
                                classData.classGroupId,
                                const Color(0xFF475569),
                                const Color(0xFFF1F5F9),
                              ),
                              const SizedBox(width: 5),
                              _buildTag(
                                mtLabel,
                                mt == 'industry'
                                    ? const Color(0xFF7C3AED)
                                    : const Color(0xFF2563EB),
                                mt == 'industry'
                                    ? const Color(0xFFF5F3FF)
                                    : const Color(0xFFEFF6FF),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${classData.averageAttendancePercentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Row 2: subject name
                          Text(
                            classData.subjectName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172033),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),

                          // Row 3: students + sessions
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 17,
                                color: const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${classData.totalStudents} Students',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Icon(
                                Icons.event_outlined,
                                size: 17,
                                color: const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${classData.totalSessions} Sessions',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF475569),
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
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  Widget _buildTag(String text, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Unable to load reports. Please try again.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.folder_open_rounded,
            size: 56,
            color: Color(0xFFCBD5E1),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 17),
          ),
        ],
      ),
    );
  }

  String _formatModuleType(String type) {
    if (type.isEmpty) return 'Unknown';
    return type[0].toUpperCase() + type.substring(1);
  }
}

// Helper class for subject dropdown options
class _SubjectOption {
  final String id;
  final String code;
  final String name;

  _SubjectOption(this.id, this.code, this.name);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _SubjectOption && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
