// leave_model.dart
class LeaveRecord {
  final String leaveId;
  final String studentId;
  final String studentName;
  final String leaveType; // 'ลาป่วย' หรือ 'ลากิจ'
  final String leaveDate; // 'YYYY-MM-DD'
  final String? reason;
  final String createdAt;

  const LeaveRecord({
    required this.leaveId,
    required this.studentId,
    required this.studentName,
    required this.leaveType,
    required this.leaveDate,
    this.reason,
    required this.createdAt,
  });

  factory LeaveRecord.fromJson(Map<String, dynamic> json) {
    return LeaveRecord(
      leaveId: json['leaveId']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      studentName: json['studentName']?.toString() ?? '',
      leaveType: json['leaveType']?.toString() ?? '',
      leaveDate: json['leaveDate']?.toString() ?? '',
      reason: json['reason']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}