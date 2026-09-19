class GradeItem {
  final int gradeId;
  final String subjectCode;
  final String subjectName;
  final double credit;
  final int academicYear;
  final int semester;
  final double totalScore;
  final double gradeResult;

  const GradeItem({
    required this.gradeId,
    required this.subjectCode,
    required this.subjectName,
    required this.credit,
    required this.academicYear,
    required this.semester,
    required this.totalScore,
    required this.gradeResult,
  });

  factory GradeItem.fromJson(Map<String, dynamic> json) {
    return GradeItem(
      gradeId: json['gradeId'] ?? 0,
      subjectCode: json['subjectCode'] ?? '',
      subjectName: json['subjectName'] ?? '',
      credit: (json['credit'] as num?)?.toDouble() ?? 1.5,
      academicYear: json['academicYear'] ?? 2568,
      semester: json['semester'] ?? 1,
      totalScore: (json['totalScore'] as num?)?.toDouble() ?? 0.0,
      gradeResult: (json['gradeResult'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
