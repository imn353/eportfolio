import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:printing/printing.dart';

import '../dashboard/widgets/app_drawer.dart';
import '../../core/providers/report_provider.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/admin_pdf_report_service.dart';
import 'admin_audit_log_page.dart';
import '../notifications/widgets/notification_bell.dart';

class AdminReportPage extends ConsumerStatefulWidget {
  const AdminReportPage({super.key});

  @override
  ConsumerState<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends ConsumerState<AdminReportPage> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(filteredAdminRecordsWithFiltersProvider);
    final trendState = ref.watch(adminTrendProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Attendance Reports',
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
        child: ListView(
          children: [
            _buildFilterBar(context),
            reportState.when(
              data: (records) {
                final totalEnrollment = records.fold<int>(
                  0,
                  (sum, r) => sum + r.summary.totalStudents,
                );
                final totalAbsences = records.fold<int>(
                  0,
                  (sum, r) => sum + r.summary.absentCount,
                );
                final totalMcCk = records.fold<int>(
                  0,
                  (sum, r) => sum + r.summary.mcCount + r.summary.ckCount,
                );
                final avgAttendance = records.isEmpty
                    ? 0.0
                    : records
                              .map((r) => r.summary.attendancePercentage)
                              .reduce((a, b) => a + b) /
                          records.length;

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Institutional Summary',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172033),
                            ),
                          ),
                          _buildExportButton(records: records),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildPremiumStatCard(
                            title: 'Attendance Average',
                            value: avgAttendance >= 80.0 ? 'Good' : 'Low',
                            baseColor: avgAttendance >= 80.0
                                ? const Color(0xFF0B3A8D)
                                : const Color(0xFFEF4444),
                            progressValue: avgAttendance / 100.0,
                          ),
                          const SizedBox(width: 12),
                          _buildPremiumStatCard(
                            title: 'Total Enrollment',
                            value: totalEnrollment.toString(),
                            baseColor: const Color(0xFF0B3A8D),
                            icon: Icons.people_outline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildPremiumStatCard(
                            title: 'Total Absences',
                            value: totalAbsences.toString(),
                            baseColor: const Color(0xFFEF4444),
                            icon: Icons.person_off_outlined,
                          ),
                          const SizedBox(width: 12),
                          _buildPremiumStatCard(
                            title: 'Total MC/CK',
                            value: totalMcCk.toString(),
                            baseColor: const Color(0xFFF59E0B),
                            icon: Icons.medical_services_outlined,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Attendance Trend',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF172033),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTrendChart(trendState),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Audit Log (Recent)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF172033),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AdminAuditLogPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0B3A8D),
                            ),
                            child: const Text(
                              'View All',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (records.isEmpty)
                        _buildEmptyState('No attendance records yet.')
                      else
                        ...records
                            .take(3)
                            .map(
                              (record) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AdminAuditLogCard(
                                  subject: record.subjectId,
                                  date: record.attendanceDate,
                                  totalStudents: record.summary.totalStudents,
                                  present: record.summary.presentCount,
                                  lateCount: record.summary.lateCount,
                                  absent: record.summary.absentCount,
                                  mc: record.summary.mcCount,
                                  ck: record.summary.ckCount,
                                  percentage:
                                      record.summary.attendancePercentage,
                                ),
                              ),
                            ),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => _buildErrorState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final classesAsync = ref.watch(classGroupsProvider);
    final subjectsAsync = ref.watch(subjectsProvider);
    final lecturersAsync = ref.watch(lecturersProvider);

    final currentClass = ref.watch(adminReportClassFilter);
    final currentSubject = ref.watch(adminReportSubjectFilter);
    final currentModule = ref.watch(adminReportModuleFilter);
    final currentLecturer = ref.watch(adminReportLecturerFilter);
    final dateStart = ref.watch(adminReportDateStartFilter);
    final dateEnd = ref.watch(adminReportDateEndFilter);

    String dateRangeText = 'All Time';
    if (dateStart != null && dateEnd != null) {
      dateRangeText =
          '${_formatDateShort(dateStart)} - ${_formatDateShort(dateEnd)}';
    } else if (dateStart != null) {
      dateRangeText = 'Since ${_formatDateShort(dateStart)}';
    } else if (dateEnd != null) {
      dateRangeText = 'Until ${_formatDateShort(dateEnd)}';
    }

    final isDateActive = dateStart != null || dateEnd != null;
    final anyActive =
        currentClass != null ||
        currentSubject != null ||
        currentModule != null ||
        currentLecturer != null ||
        isDateActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),
              if (anyActive)
                TextButton.icon(
                  onPressed: () {
                    ref.read(adminReportClassFilter.notifier).set(null);
                    ref.read(adminReportSubjectFilter.notifier).set(null);
                    ref.read(adminReportModuleFilter.notifier).set(null);
                    ref.read(adminReportLecturerFilter.notifier).set(null);
                    ref.read(adminReportDateStartFilter.notifier).set(null);
                    ref.read(adminReportDateEndFilter.notifier).set(null);
                  },
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text(
                    'Clear Filters',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // FIRST ROW: Date and Subject
          Row(
            children: [
              // Date Filter
              Expanded(
                flex: 3,
                child: _buildFilterChip(
                  label: dateRangeText,
                  isActive: isDateActive,
                  icon: Icons.date_range,
                  expand: true,
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                      initialDateRange: dateStart != null && dateEnd != null
                          ? DateTimeRange(start: dateStart, end: dateEnd)
                          : null,
                      builder: (context, child) {
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 400,
                              maxHeight: 600,
                            ),
                            child: child,
                          ),
                        );
                      },
                    );
                    if (range != null) {
                      ref
                          .read(adminReportDateStartFilter.notifier)
                          .set(range.start);
                      ref
                          .read(adminReportDateEndFilter.notifier)
                          .set(range.end);
                    }
                  },
                ),
              ),
              if (isDateActive) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    ref.read(adminReportDateStartFilter.notifier).set(null);
                    ref.read(adminReportDateEndFilter.notifier).set(null);
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
              const SizedBox(width: 6),

              // Subject Filter
              Expanded(
                flex: 4,
                child: _buildFilterChip(
                  label: currentSubject != null
                      ? (subjectsAsync.value
                              ?.where((e) => e.subjectId == currentSubject)
                              .firstOrNull
                              ?.name ??
                          currentSubject)
                      : 'Subject',
                  isActive: currentSubject != null,
                  expand: true,
                  onTap: () => _showFilterBottomSheet(
                    context,
                    title: 'Subject',
                    options:
                        subjectsAsync.value?.map((e) => e.subjectId).toList() ??
                        [],
                    labelBuilder: (val) {
                      final sub = subjectsAsync.value
                          ?.where((e) => e.subjectId == val)
                          .firstOrNull;
                      return sub?.name ?? val;
                    },
                    currentValue: currentSubject,
                    onSelected: (val) =>
                        ref.read(adminReportSubjectFilter.notifier).set(val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // SECOND ROW: Class Group, Module Type, Lecturer
          Row(
            children: [
              // Class Filter
              Expanded(
                flex: 3,
                child: _buildFilterChip(
                  label: currentClass != null
                      ? (classesAsync.value
                              ?.where((e) => e.classGroupId == currentClass)
                              .firstOrNull
                              ?.name ??
                          currentClass)
                      : 'Class',
                  isActive: currentClass != null,
                  expand: true,
                  onTap: () => _showFilterBottomSheet(
                    context,
                    title: 'Class',
                    options:
                        classesAsync.value
                            ?.map((e) => e.classGroupId)
                            .toList() ??
                        [],
                    labelBuilder: (val) {
                      final cls = classesAsync.value
                          ?.where((e) => e.classGroupId == val)
                          .firstOrNull;
                      return cls?.name ?? val;
                    },
                    currentValue: currentClass,
                    onSelected: (val) =>
                        ref.read(adminReportClassFilter.notifier).set(val),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Module Type Filter
              Expanded(
                flex: 3,
                child: _buildFilterChip(
                  label: currentModule != null
                      ? (currentModule[0].toUpperCase() +
                            currentModule.substring(1))
                      : 'Module',
                  isActive: currentModule != null,
                  expand: true,
                  onTap: () => _showFilterBottomSheet(
                    context,
                    title: 'Module',
                    options: ['Core', 'Elective', 'General'],
                    labelBuilder: (val) => val,
                    currentValue: currentModule,
                    onSelected: (val) =>
                        ref.read(adminReportModuleFilter.notifier).set(val),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Lecturer Filter
              Expanded(
                flex: 4,
                child: _buildFilterChip(
                  label: currentLecturer != null
                      ? (lecturersAsync.value
                                ?.where((e) => e.lecturerId == currentLecturer)
                                .firstOrNull
                                ?.fullName ??
                            currentLecturer)
                      : 'Lecturer',
                  isActive: currentLecturer != null,
                  expand: true,
                  onTap: () => _showFilterBottomSheet(
                    context,
                    title: 'Lecturer',
                    options:
                        lecturersAsync.value
                            ?.map((e) => e.lecturerId)
                            .toList() ??
                        [],
                    labelBuilder: (val) {
                      final lec = lecturersAsync.value
                          ?.where((e) => e.lecturerId == val)
                          .firstOrNull;
                      return lec?.fullName ?? val;
                    },
                    currentValue: currentLecturer,
                    onSelected: (val) =>
                        ref.read(adminReportLecturerFilter.notifier).set(val),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    IconData? icon,
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
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isActive
                      ? const Color(0xFF0B3A8D)
                      : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
              ],
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
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

  Widget _buildTrendChart(AsyncValue<List<AdminTrendData>> trendState) {
    return trendState.when(
      data: (data) {
        if (data.isEmpty) {
          return _buildEmptyState(
            'No trend data available for current filters.',
          );
        }

        return Container(
          height: 200,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: data.length > 5
                        ? (data.length / 5).ceilToDouble()
                        : 1,
                    getTitlesWidget: (value, meta) {
                      final int index = value.toInt();
                      if (index >= 0 && index < data.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            '${data[index].date.month}/${data[index].date.day}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 10,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: (data.length - 1).toDouble(),
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) {
                    return FlSpot(e.key.toDouble(), e.value.averagePercentage);
                  }).toList(),
                  isCurved: true,
                  color: const Color(0xFF0B3A8D),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF0B3A8D).withValues(alpha: 0.1),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();
                      final date = data[index].date;
                      return LineTooltipItem(
                        '${_formatDateShort(date)}\n${spot.y.toStringAsFixed(1)}%',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _buildEmptyState('Error loading chart: $err'),
    );
  }

  String _formatDateShort(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildErrorState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Unable to load reports. Please try again.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(message, style: const TextStyle(color: Color(0xFF64748B))),
    );
  }

  Widget _buildPremiumStatCard({
    required String title,
    required String value,
    required Color baseColor,
    IconData? icon,
    double? progressValue,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: baseColor.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: baseColor.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            if (progressValue != null)
              SizedBox(
                width: 48,
                height: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progressValue,
                      strokeWidth: 4,
                      color: baseColor,
                      backgroundColor: baseColor.withValues(alpha: 0.1),
                    ),
                    Text(
                      '${(progressValue * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: baseColor,
                      ),
                    ),
                  ],
                ),
              )
            else if (icon != null)
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: baseColor),
              ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17.5,
                      fontWeight: FontWeight.bold,
                      color: baseColor == const Color(0xFF172033)
                          ? const Color(0xFF172033)
                          : baseColor,
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

  // ── Export PDF button ─────────────────────────────────────────
  Widget _buildExportButton({required List<dynamic> records}) {
    return Material(
      color: _isExporting
          ? const Color(0xFF0B3A8D).withValues(alpha: 0.06)
          : const Color(0xFF0B3A8D).withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: _isExporting ? null : () => _showExportOptionsDialog(records),
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

  // ── Export options dialog ──────────────────────────────────────
  void _showExportOptionsDialog(List<dynamic> records) {
    bool includeSubjectPerformance = false;
    bool includeModulePerformance = false;
    bool includeLecturerPerformance = false;

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
                              'Overall attendance summary is always included.',
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

                    // Toggle: Subject List
                    _buildToggleOption(
                      icon: Icons.subject,
                      title: 'Include Subject Performance',
                      subtitle:
                          'Detailed attendance breakdown grouped by subject',
                      value: includeSubjectPerformance,
                      onChanged: (val) =>
                          setModalState(() => includeSubjectPerformance = val),
                    ),
                    const SizedBox(height: 10),

                    // Toggle: Module List
                    _buildToggleOption(
                      icon: Icons.category_outlined,
                      title: 'Include Module Performance',
                      subtitle:
                          'Detailed attendance breakdown grouped by module',
                      value: includeModulePerformance,
                      onChanged: (val) =>
                          setModalState(() => includeModulePerformance = val),
                    ),
                    const SizedBox(height: 10),

                    // Toggle: Lecturer List
                    _buildToggleOption(
                      icon: Icons.person_outline,
                      title: 'Include Lecturer Performance',
                      subtitle:
                          'Detailed attendance breakdown grouped by lecturer',
                      value: includeLecturerPerformance,
                      onChanged: (val) =>
                          setModalState(() => includeLecturerPerformance = val),
                    ),
                    const SizedBox(height: 20),

                    // Generate button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _exportPdf(
                            records,
                            includeSubjectPerformance:
                                includeSubjectPerformance,
                            includeModulePerformance: includeModulePerformance,
                            includeLecturerPerformance:
                                includeLecturerPerformance,
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
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: value
                        ? const Color(0xFF0B3A8D).withValues(alpha: 0.8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF0B3A8D),
            activeTrackColor: const Color(0xFF0B3A8D).withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }

  // ── PDF generation logic ──────────────────────────────────────
  Future<void> _exportPdf(
    List<dynamic> records, {
    required bool includeSubjectPerformance,
    required bool includeModulePerformance,
    required bool includeLecturerPerformance,
  }) async {
    setState(() => _isExporting = true);

    try {
      final user = ref.read(authProvider);

      final currentClass = ref.read(adminReportClassFilter);
      final currentSubject = ref.read(adminReportSubjectFilter);
      final currentModule = ref.read(adminReportModuleFilter);
      final currentLecturer = ref.read(adminReportLecturerFilter);
      final dateStart = ref.read(adminReportDateStartFilter);
      final dateEnd = ref.read(adminReportDateEndFilter);

      String? dateRangeText;
      if (dateStart != null && dateEnd != null) {
        dateRangeText =
            '${_formatDateShort(dateStart)} - ${_formatDateShort(dateEnd)}';
      } else if (dateStart != null) {
        dateRangeText = 'Since ${_formatDateShort(dateStart)}';
      } else if (dateEnd != null) {
        dateRangeText = 'Until ${_formatDateShort(dateEnd)}';
      }

      final subjectsAsync = ref.read(subjectsProvider);
      final lecturersAsync = ref.read(lecturersProvider);

      final pdfBytes = await AdminPdfReportService.generateAdminReport(
        adminName: user?.displayName ?? 'Administrator',
        adminEmail: user?.email ?? '',
        records: records.cast(), // List<AttendanceRecordModel>
        subjects: subjectsAsync.value ?? [],
        lecturers: lecturersAsync.value ?? [],
        activeDateRangeFilter: dateRangeText,
        activeSubjectFilter: currentSubject,
        activeClassGroupFilter: currentClass,
        activeModuleFilter: currentModule,
        activeLecturerFilter: currentLecturer,
        includeSubjectPerformance: includeSubjectPerformance,
        includeModulePerformance: includeModulePerformance,
        includeLecturerPerformance: includeLecturerPerformance,
      );

      if (!mounted) return;

      // Show print / save dialog (works on web, mobile, desktop)
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'Admin_Attendance_Report',
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
}

class AdminAuditLogCard extends StatelessWidget {
  final String subject;
  final String date;
  final int totalStudents;
  final int present;
  final int lateCount;
  final int absent;
  final int mc;
  final int ck;
  final double percentage;

  const AdminAuditLogCard({
    super.key,
    required this.subject,
    required this.date,
    required this.totalStudents,
    required this.present,
    required this.lateCount,
    required this.absent,
    required this.mc,
    required this.ck,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$subject - $date',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172033),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: percentage < 80.0
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Compact Data Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactStat(
                'Total',
                totalStudents.toString(),
                const Color(0xFF64748B),
              ),
              _buildCompactStat(
                'P',
                present.toString(),
                const Color(0xFF10B981),
              ),
              _buildCompactStat(
                'L',
                lateCount.toString(),
                const Color(0xFF14B8A6),
              ),
              _buildCompactStat(
                'A',
                absent.toString(),
                const Color(0xFFEF4444),
              ),
              _buildCompactStat('MC', mc.toString(), const Color(0xFFF59E0B)),
              _buildCompactStat('CK', ck.toString(), const Color(0xFF6366F1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(String label, String value, Color valueColor) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
