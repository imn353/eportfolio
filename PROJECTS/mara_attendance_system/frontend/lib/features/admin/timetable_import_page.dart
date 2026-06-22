import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' hide Border, BorderStyle;

import 'dart:typed_data';
import '../../core/firestore/firestore_models.dart';
import '../../core/providers/metadata_provider.dart';
import '../../core/providers/timetable_provider.dart';
import '../notifications/widgets/notification_bell.dart';

class ParsedRow {
  final String classGroupId;
  final String subjectId;
  final String lecturerId;
  final String roomId;
  final int? dayOfWeek;
  final String startSlotId;
  final String endSlotId;
  final String status;
  final String rawLine;
  final List<String> errors;
  final List<String> warnings;

  ParsedRow({
    required this.classGroupId,
    required this.subjectId,
    required this.lecturerId,
    required this.roomId,
    required this.dayOfWeek,
    required this.startSlotId,
    required this.endSlotId,
    required this.status,
    required this.rawLine,
    required this.errors,
    required this.warnings,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
}

class TimetableImportPage extends ConsumerStatefulWidget {
  const TimetableImportPage({super.key});

  @override
  ConsumerState<TimetableImportPage> createState() =>
      _TimetableImportPageState();
}

class _TimetableImportPageState extends ConsumerState<TimetableImportPage> {
  String? _uploadedFileName;
  List<ParsedRow> _parsedRows = [];
  bool _isImporting = false;
  bool _showPreview = false;

  final Map<int, String> _daysOfWeek = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  int? _parseDay(String dayStr) {
    dayStr = dayStr.trim().toLowerCase();
    if (dayStr == '1' || dayStr == 'monday' || dayStr == 'mon') return 1;
    if (dayStr == '2' || dayStr == 'tuesday' || dayStr == 'tue') return 2;
    if (dayStr == '3' || dayStr == 'wednesday' || dayStr == 'wed') return 3;
    if (dayStr == '4' || dayStr == 'thursday' || dayStr == 'thu') return 4;
    if (dayStr == '5' || dayStr == 'friday' || dayStr == 'fri') return 5;
    if (dayStr == '6' || dayStr == 'saturday' || dayStr == 'sat') return 6;
    if (dayStr == '7' || dayStr == 'sunday' || dayStr == 'sun') return 7;
    return int.tryParse(dayStr);
  }

  Future<void> _pickAndParseFile({
    required List<ClassGroupModel> classGroups,
    required List<SubjectModel> subjects,
    required List<LecturerModel> lecturers,
    required List<RoomModel> rooms,
    required List<TimeSlotModel> timeSlots,
  }) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes ?? (file.path != null ? File(file.path!).readAsBytesSync() : null);

    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to read file bytes.')));
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _uploadedFileName = file.name;
      _showPreview = false;
      _parsedRows = [];
    });

    List<String> lines = [];

    try {
      if (file.extension?.toLowerCase() == 'csv') {
        final decoded = utf8.decode(bytes);
        lines = decoded.split(RegExp(r'\r\n|\n'));
      } else if (file.extension?.toLowerCase() == 'xlsx' || file.extension?.toLowerCase() == 'xls') {
        final excel = Excel.decodeBytes(bytes);
        for (var table in excel.tables.keys) {
          final sheet = excel.tables[table]!;
          for (var row in sheet.rows) {
            final mappedRow = row.map((cell) => cell?.value?.toString() ?? '').toList();
            if (mappedRow.any((cell) => cell.isNotEmpty)) {
              lines.add(mappedRow.join(','));
            }
          }
          break; // Only parse first sheet
        }
      }

      _processLines(
        lines: lines,
        classGroups: classGroups,
        subjects: subjects,
        lecturers: lecturers,
        rooms: rooms,
        timeSlots: timeSlots,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error parsing file: $e')));
      }
    }
  }

  Future<void> _downloadTemplate() async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Add headers
      sheet.appendRow([
        TextCellValue('class_group'),
        TextCellValue('subject'),
        TextCellValue('lecturer'),
        TextCellValue('room'),
        TextCellValue('day'),
        TextCellValue('start_slot'),
        TextCellValue('end_slot'),
        TextCellValue('status'),
      ]);

      // Add sample rows
      sheet.appendRow([
        TextCellValue('C7-S1'),
        TextCellValue('SECP03'),
        TextCellValue('mock-uid-lecturer-001'),
        TextCellValue('BK-2'),
        TextCellValue('Monday'),
        TextCellValue('TS01'),
        TextCellValue('TS02'),
        TextCellValue('active'),
      ]);
      sheet.appendRow([
        TextCellValue('C8-S2'),
        TextCellValue('DED10044'),
        TextCellValue('mock-uid-lecturer-002'),
        TextCellValue('WIRING-BAY-3'),
        TextCellValue('Tuesday'),
        TextCellValue('TS03'),
        TextCellValue('TS05'),
        TextCellValue('active'),
      ]);

      final bytes = excel.encode();
      if (bytes == null) return;

      final result = await FilePicker.saveFile(
        dialogTitle: 'Save Timetable Template',
        fileName: 'timetable_template.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(bytes),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template downloaded successfully.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate template: $e')));
      }
    }
  }

  void _processLines({
    required List<String> lines,
    required List<ClassGroupModel> classGroups,
    required List<SubjectModel> subjects,
    required List<LecturerModel> lecturers,
    required List<RoomModel> rooms,
    required List<TimeSlotModel> timeSlots,
  }) {
    if (lines.isEmpty) {
      setState(() {
        _parsedRows = [];
        _showPreview = false;
      });
      return;
    }

    final List<ParsedRow> newRows = [];

    // Helper maps for quick lookup of active metadata
    final classGroupIds = classGroups.map((x) => x.classGroupId).toSet();
    final subjectIds = subjects.map((x) => x.subjectId).toSet();
    final lecturerIds = lecturers.map((x) => x.lecturerId).toSet();
    final roomIds = rooms.map((x) => x.roomId).toSet();
    final timeSlotMap = {for (var x in timeSlots) x.timeSlotId: x};

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Auto-detect delimiter: comma or tab
      final commaCount = ','.allMatches(line).length;
      final tabCount = '\t'.allMatches(line).length;
      final delimiter = tabCount > commaCount ? '\t' : ',';

      final cols = line.split(delimiter).map((c) => c.trim()).toList();

      // Check if it's the header row. If so, skip it.
      if (i == 0 &&
          (cols[0].toLowerCase().contains('class') ||
              cols[0].toLowerCase().contains('subject') ||
              cols[0].toLowerCase().contains('group_id'))) {
        continue;
      }

      final List<String> rowErrors = [];
      final List<String> rowWarnings = [];

      if (cols.length < 7) {
        newRows.add(
          ParsedRow(
            classGroupId: '',
            subjectId: '',
            lecturerId: '',
            roomId: '',
            dayOfWeek: null,
            startSlotId: '',
            endSlotId: '',
            status: 'active',
            rawLine: line,
            errors: [
              'Insufficient columns. Expected at least 7 fields, got ${cols.length}.',
            ],
            warnings: [],
          ),
        );
        continue;
      }

      final classGroupId = cols[0];
      final subjectId = cols[1];
      final lecturerId = cols[2];
      final roomId = cols[3];
      final dayStr = cols[4];
      final startSlotId = cols[5];
      final endSlotId = cols[6];
      final status = cols.length > 7 ? cols[7].toLowerCase() : 'active';

      final dayOfWeek = _parseDay(dayStr);

      // 1. Mandatory Fields Presence Check
      if (classGroupId.isEmpty) rowErrors.add('Class Group ID is empty.');
      if (subjectId.isEmpty) rowErrors.add('Subject ID is empty.');
      if (lecturerId.isEmpty) rowErrors.add('Lecturer ID is empty.');
      if (roomId.isEmpty) rowErrors.add('Room ID is empty.');
      if (dayOfWeek == null || dayOfWeek < 1 || dayOfWeek > 7) {
        rowErrors.add('Invalid Day of Week: "$dayStr". Use 1-7 or Day Names.');
      }
      if (startSlotId.isEmpty) rowErrors.add('Start Slot ID is empty.');
      if (endSlotId.isEmpty) rowErrors.add('End Slot ID is empty.');

      // 2. Metadata Cross-reference Warnings (Non-blocking but helpful)
      if (classGroupId.isNotEmpty && !classGroupIds.contains(classGroupId)) {
        rowWarnings.add(
          'Class Group "$classGroupId" not found in active classes.',
        );
      }
      if (subjectId.isNotEmpty && !subjectIds.contains(subjectId)) {
        rowWarnings.add('Subject "$subjectId" not found in active subjects.');
      }
      if (lecturerId.isNotEmpty && !lecturerIds.contains(lecturerId)) {
        rowWarnings.add(
          'Lecturer ID "$lecturerId" not found in active lecturers.',
        );
      }
      if (roomId.isNotEmpty && !roomIds.contains(roomId)) {
        rowWarnings.add('Room "$roomId" not found in active rooms.');
      }

      // 3. Time Slot Chronological Sequence Validation
      final startSlot = timeSlotMap[startSlotId];
      final endSlot = timeSlotMap[endSlotId];

      if (startSlot == null && startSlotId.isNotEmpty) {
        rowWarnings.add(
          'Start Slot "$startSlotId" not found in time slot metadata.',
        );
      }
      if (endSlot == null && endSlotId.isNotEmpty) {
        rowWarnings.add(
          'End Slot "$endSlotId" not found in time slot metadata.',
        );
      }

      if (startSlot != null && endSlot != null) {
        if (startSlot.slotNo > endSlot.slotNo) {
          rowErrors.add(
            'Timeline error: Start slot (${startSlot.timeSlotId}) cannot be after End slot (${endSlot.timeSlotId}).',
          );
        }
      }

      newRows.add(
        ParsedRow(
          classGroupId: classGroupId,
          subjectId: subjectId,
          lecturerId: lecturerId,
          roomId: roomId,
          dayOfWeek: dayOfWeek,
          startSlotId: startSlotId,
          endSlotId: endSlotId,
          status: status == 'inactive' ? 'inactive' : 'active',
          rawLine: line,
          errors: rowErrors,
          warnings: rowWarnings,
        ),
      );
    }

    setState(() {
      _parsedRows = newRows;
      _showPreview = true;
    });
  }

  void _confirmImport() async {
    final validRows = _parsedRows.where((r) => !r.hasErrors).toList();
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No valid sessions to import! Please fix the errors in your data first.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    final timetableService = ref.read(timetableServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    int successCount = 0;
    int errorCount = 0;

    try {
      // Process sequential futures to write to Firestore cleanly
      for (final row in validRows) {
        try {
          await timetableService.saveSession(
            originalSessionId: null, // Always treat as a new session insertion
            classGroupId: row.classGroupId,
            subjectId: row.subjectId,
            lecturerId: row.lecturerId,
            roomId: row.roomId,
            dayOfWeek: row.dayOfWeek!,
            startSlotId: row.startSlotId,
            endSlotId: row.endSlotId,
            status: row.status,
          );
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Import complete! Successfully saved $successCount sessions.${errorCount > 0 ? " Failed to save $errorCount sessions." : ""}',
          ),
          backgroundColor: errorCount > 0
              ? Colors.orangeAccent
              : const Color(0xFF10B981),
        ),
      );
      navigator.pop();
    } catch (e) {
      setState(() {
        _isImporting = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text('Bulk import error: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final classGroupsState = ref.watch(classGroupsProvider);
    final subjectsState = ref.watch(subjectsProvider);
    final lecturersState = ref.watch(timetableAssignableLecturersProvider);
    final roomsState = ref.watch(roomsProvider);
    final timeSlotsState = ref.watch(timeSlotsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Bulk Import Schedule',
          style: TextStyle(fontWeight: FontWeight.bold),
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
                data: (timeSlots) => _isImporting
                    ? _buildImportingState()
                    : _buildImportForm(
                        classGroups: classGroups,
                        subjects: subjects,
                        lecturers: assignableLecturers
                            .map((entry) => entry.lecturer)
                            .toList(),
                        rooms: rooms,
                        timeSlots: timeSlots,
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error: $e')),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildImportingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(strokeWidth: 5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Importing Timetable Sessions...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF172033),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Writing records to Firestore database. Please do not close the app.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildImportForm({
    required List<ClassGroupModel> classGroups,
    required List<SubjectModel> subjects,
    required List<LecturerModel> lecturers,
    required List<RoomModel> rooms,
    required List<TimeSlotModel> timeSlots,
  }) {
    final errorRows = _parsedRows.where((r) => r.hasErrors).length;
    final warningRows = _parsedRows
        .where((r) => !r.hasErrors && r.hasWarnings)
        .length;
    final validRows = _parsedRows.where((r) => !r.hasErrors).length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions Card
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Text(
                              'How it works',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF172033),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'You can upload a standard CSV file or Excel (.xlsx) file below. Ensure your file has the correct column structure without headers in the first row.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expected Columns order:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF172033),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'class_group, subject, lecturer, room, day (1-7/name), start_slot, end_slot, status(optional)',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Sample Paste content:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF172033),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'CS110-4A, CSC238, L001, BK101, Monday, slot_1, slot_2, active\nCS110-4B, CSC238, L002, BK102, Tuesday, slot_3, slot_5, active',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.download),
                    label: const Text('Download Sample Template'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF2563EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (!_showPreview) ...[
                  // File Upload Area
                  const Text(
                    'UPLOAD EXCEL / CSV FILE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _pickAndParseFile(
                      classGroups: classGroups,
                      subjects: subjects,
                      lecturers: lecturers,
                      rooms: rooms,
                      timeSlots: timeSlots,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.upload_file,
                            size: 48,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _uploadedFileName ?? 'Click to browse Excel or CSV files',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: _uploadedFileName != null ? FontWeight.bold : FontWeight.normal,
                              color: _uploadedFileName != null ? const Color(0xFF172033) : const Color(0xFF64748B),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_uploadedFileName == null) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Supported formats: .xlsx, .csv',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  // Summary Badges
                  Row(
                    children: [
                      _buildSummaryBadge(
                        'Total Rows',
                        _parsedRows.length.toString(),
                        const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      _buildSummaryBadge(
                        'Valid',
                        validRows.toString(),
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 8),
                      if (warningRows > 0) ...[
                        _buildSummaryBadge(
                          'Warnings',
                          warningRows.toString(),
                          const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (errorRows > 0)
                        _buildSummaryBadge(
                          'Errors',
                          errorRows.toString(),
                          const Color(0xFFEF4444),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Session Preview Table
                  const Text(
                    'PARSED SESSIONS PREVIEW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _parsedRows.length,
                    itemBuilder: (context, index) {
                      final row = _parsedRows[index];
                      return _buildPreviewCard(row, index + 1);
                    },
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _showPreview = false;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF94A3B8)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Edit Paste Data',
                            style: TextStyle(
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: validRows > 0 ? _confirmImport : null,
                          icon: const Icon(Icons.check_circle),
                          label: Text(
                            'Import $validRows Sessions',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ParsedRow row, int lineNo) {
    final bool hasErrors = row.hasErrors;
    final bool hasWarnings = row.hasWarnings;

    Color borderColor = const Color(0xFFE2E8F0);
    Color bgColor = Colors.white;

    if (hasErrors) {
      borderColor = const Color(0xFFFCA5A5);
      bgColor = const Color(0xFFFEF2F2);
    } else if (hasWarnings) {
      borderColor = const Color(0xFFFDE047);
      bgColor = const Color(0xFFFEFCE8);
    }

    return Card(
      color: bgColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: hasErrors
                      ? const Color(0xFFEF4444)
                      : hasWarnings
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFF64748B),
                  child: Text(
                    lineNo.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (!hasErrors) ...[
                  Text(
                    '${row.classGroupId} | ${row.subjectId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF172033),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: row.status == 'active'
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      row.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: row.status == 'active'
                            ? const Color(0xFF10B981)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Row parsing failed',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),

            if (!hasErrors) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPreviewDetail(
                    'Day',
                    row.dayOfWeek != null
                        ? (_daysOfWeek[row.dayOfWeek] ??
                              row.dayOfWeek.toString())
                        : '??',
                  ),
                  _buildPreviewDetail(
                    'Time Slot',
                    '${row.startSlotId} - ${row.endSlotId}',
                  ),
                  _buildPreviewDetail('Room', row.roomId),
                  _buildPreviewDetail('Lecturer', row.lecturerId),
                ],
              ),
            ] else ...[
              Text(
                'Raw data: "${row.rawLine}"',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
            ],

            if (row.errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...row.errors.map(
                (err) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cancel,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          err,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFEF4444),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (row.warnings.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...row.warnings.map(
                (warn) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        size: 14,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          warn,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF475569),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
