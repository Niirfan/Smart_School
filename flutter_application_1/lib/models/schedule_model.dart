enum ClassStatus {
  normal,      // เข้าเรียนปกติ
  inProgress,  // กำลังเรียน
  upcoming,    // ยังไม่ถึงเวลา
}

class ScheduleItem {
  final String timeRange;
  final String room;
  final String subjectName;
  final String teacherName;
  final ClassStatus status;
  final String? subjectCode;
  final String? note;

  const ScheduleItem({
    required this.timeRange,
    required this.room,
    required this.subjectName,
    required this.teacherName,
    required this.status,
    this.subjectCode,
    this.note,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    ClassStatus st = ClassStatus.normal;
    final statusStr = json['status']?.toString().toLowerCase();
    if (statusStr == 'inprogress' || statusStr == 'กำลังเรียน') {
      st = ClassStatus.inProgress;
    } else if (statusStr == 'upcoming' || statusStr == 'ยังไม่ถึงเวลา') {
      st = ClassStatus.upcoming;
    }

    return ScheduleItem(
      timeRange: json['timeRange'] ?? '',
      room: json['room'] ?? '',
      subjectName: json['subjectName'] ?? '',
      teacherName: json['teacherName'] ?? '',
      status: st,
      subjectCode: json['subjectCode'],
      note: json['note'],
    );
  }
}

class TimetableEntry {
  final String scheduleId;
  final String day;
  final String timeRange;
  final String room;
  final String subjectCode;
  final String subjectName;
  final double credit;
  final String teacherName;

  const TimetableEntry({
    required this.scheduleId,
    required this.day,
    required this.timeRange,
    required this.room,
    required this.subjectCode,
    required this.subjectName,
    required this.credit,
    required this.teacherName,
  });

  factory TimetableEntry.fromJson(String day, Map<String, dynamic> json) {
    return TimetableEntry(
      scheduleId: json['scheduleId'] ?? '',
      day: day,
      timeRange: json['timeRange'] ?? '',
      room: json['room'] ?? '',
      subjectCode: json['subjectCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      credit: (json['credit'] as num?)?.toDouble() ?? 1.5,
      teacherName: json['teacherName'] ?? '',
    );
  }
}
