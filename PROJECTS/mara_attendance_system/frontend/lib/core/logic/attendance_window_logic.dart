/// Parses a time string (HH:mm) and a date (YYYY-MM-DD) into a DateTime object.
DateTime? parseAttendanceSlotTime({
  required String attendanceDate,
  required String timeString,
}) {
  try {
    final dateParts = attendanceDate.split('-');
    if (dateParts.length != 3) return null;

    final timeParts = timeString.split(':');
    if (timeParts.length < 2) return null;

    return DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );
  } catch (_) {
    return null;
  }
}

/// True when the current time is past the session start time minus 10 minutes.
bool isAttendanceMarkingWindowOpen({
  required String attendanceDate,
  required String startTime,
  DateTime? now,
}) {
  final slotStart = parseAttendanceSlotTime(
    attendanceDate: attendanceDate,
    timeString: startTime,
  );
  if (slotStart == null) return true; // fallback open if parse error

  final reference = now ?? DateTime.now();
  // Opens 10 minutes before the actual class start time
  return reference.isAfter(slotStart.subtract(const Duration(minutes: 10)));
}

/// True when the current time is past the session end plus 10 minutes.
bool isAttendanceMarkingWindowClosed({
  required String attendanceDate,
  required String endTime,
  DateTime? now,
}) {
  final slotEnd = parseAttendanceSlotTime(
    attendanceDate: attendanceDate,
    timeString: endTime,
  );
  if (slotEnd == null) return false;

  final reference = now ?? DateTime.now();
  // Closes 10 minutes after the actual class end time
  return reference.isAfter(slotEnd.add(const Duration(minutes: 10)));
}

String attendanceWindowClosedMessage(String endTime) =>
    'Attendance can no longer be marked. The window closed 10 minutes after $endTime.';

String attendanceWindowNotYetOpenMessage(String startTime) =>
    'Attendance marking will open 10 minutes before $startTime.';
