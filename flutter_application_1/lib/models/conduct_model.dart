class ConductRecord {
  final String title;
  final String date;
  final String recordedBy;
  final int pointsChange;

  const ConductRecord({
    required this.title,
    required this.date,
    required this.recordedBy,
    required this.pointsChange,
  });

  factory ConductRecord.fromJson(Map<String, dynamic> json) {
    return ConductRecord(
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      recordedBy: json['recordedBy'] ?? '',
      pointsChange: json['pointsChange'] ?? 0,
    );
  }
}

class ConductModel {
  final int currentScore;
  final int maxScore;
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

    return ConductModel(
      currentScore: json['currentScore'] ?? 0,
      maxScore: json['maxScore'] ?? 100,
      gradeLevel: json['gradeLevel'] ?? '',
      recentRecords: list,
    );
  }
}
