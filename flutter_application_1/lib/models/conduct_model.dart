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

  int get scoreChange => pointsChange;
  String get reason => title;

  factory ConductRecord.fromJson(Map<String, dynamic> json) {
    return ConductRecord(
      title: json['reason'] ?? json['title'] ?? '',
      date: json['date'] ?? json['created_at'] ?? '',
      recordedBy: json['teacher_name'] ?? json['recordedBy'] ?? '',
      pointsChange: json['score_change'] is int
          ? json['score_change']
          : json['pointsChange'] is int
              ? json['pointsChange']
              : int.tryParse(json['score_change']?.toString() ?? json['pointsChange']?.toString() ?? '0') ?? 0,
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
