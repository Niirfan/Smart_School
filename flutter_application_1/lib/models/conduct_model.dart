class ConductRecord {
  final String studentId;
  final String title;
  final String date;
  final String recordedBy;
  final num pointsChange;

  const ConductRecord({
    this.studentId = '',
    required this.title,
    required this.date,
    required this.recordedBy,
    required this.pointsChange,
  });

  num get scoreChange => pointsChange;
  String get reason => title;

  factory ConductRecord.fromJson(Map<String, dynamic> json) {
    num parsedPoints = 0;
    final rawChange = json['score_change'] ?? json['pointsChange'];
    if (rawChange is num) {
      parsedPoints = rawChange;
    } else if (rawChange != null) {
      parsedPoints = num.tryParse(rawChange.toString()) ?? 0;
    }

    return ConductRecord(
      studentId: json['student_id']?.toString() ?? json['studentId']?.toString() ?? '',
      title: json['reason'] ?? json['title'] ?? '',
      date: json['date'] ?? json['created_at'] ?? '',
      recordedBy: json['teacher_name'] ?? json['recordedBy'] ?? '',
      pointsChange: parsedPoints,
    );
  }
}

class ConductModel {
  final num currentScore;
  final num maxScore;
  final String gradeLevel;
  final List<ConductRecord> recentRecords;

  const ConductModel({
    required this.currentScore,
    required this.maxScore,
    required this.gradeLevel,
    required this.recentRecords,
  });

  factory ConductModel.fromJson(Map<String, dynamic> json) {
    final list = (json['recentRecords'] as List<dynamic>?)
            ?.map((e) => ConductRecord.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final rawCurrent = json['currentScore'];
    final parsedCurrent = rawCurrent is num ? rawCurrent : (num.tryParse(rawCurrent?.toString() ?? '100') ?? 100);

    final rawMax = json['maxScore'];
    final parsedMax = rawMax is num ? rawMax : (num.tryParse(rawMax?.toString() ?? '100') ?? 100);

    return ConductModel(
      currentScore: parsedCurrent,
      maxScore: parsedMax,
      gradeLevel: json['gradeLevel'] ?? '',
      recentRecords: list,
    );
  }
}
