class AttendanceStat {
  final double percentage;
  final String statusText;
  final String note;
  final int presentCount;
  final int lateCount;
  final int businessLeaveCount;
  final int sickLeaveCount;
  final int absentCount;

  const AttendanceStat({
    required this.percentage,
    required this.statusText,
    required this.note,
    required this.presentCount,
    required this.lateCount,
    required this.businessLeaveCount,
    required this.sickLeaveCount,
    required this.absentCount,
  });

  factory AttendanceStat.fromJson(Map<String, dynamic> json) {
    return AttendanceStat(
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      statusText: json['statusText'] ?? '',
      note: json['note'] ?? '',
      presentCount: json['presentCount'] ?? 0,
      lateCount: json['lateCount'] ?? 0,
      businessLeaveCount: json['businessLeaveCount'] ?? 0,
      sickLeaveCount: json['sickLeaveCount'] ?? 0,
      absentCount: json['absentCount'] ?? 0,
    );
  }
}
