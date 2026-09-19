class StudentModel {
  final String id;
  final String fullName;
  final String classroom;
  final int seatNumber;
  final String schoolName;
  final double gpax;
  final String status;
  final String avatarUrl;
  final String birthDate;
  final int age;
  final String bloodGroup;
  final String advisorName;
  final String advisorPhone;
  final String guardianName;
  final String guardianRelation;
  final String guardianPhone;

  const StudentModel({
    required this.id,
    required this.fullName,
    required this.classroom,
    required this.seatNumber,
    required this.schoolName,
    required this.gpax,
    required this.status,
    required this.avatarUrl,
    required this.birthDate,
    required this.age,
    required this.bloodGroup,
    required this.advisorName,
    required this.advisorPhone,
    required this.guardianName,
    required this.guardianRelation,
    required this.guardianPhone,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      classroom: json['classroom'] ?? '',
      seatNumber: json['seatNumber'] is int
          ? json['seatNumber']
          : int.tryParse(json['seatNumber']?.toString() ?? '0') ?? 0,
      schoolName: json['schoolName'] ?? '',
      gpax: (json['gpax'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      avatarUrl: json['avatarUrl'] ??
          'https://images.unsplash.com/photo-1544717305-2782549b5136?w=200&auto=format&fit=crop&q=80',
      birthDate: json['birthDate'] ?? '',
      age: json['age'] is int
          ? json['age']
          : int.tryParse(json['age']?.toString() ?? '0') ?? 0,
      bloodGroup: json['bloodGroup'] ?? '',
      advisorName: json['advisorName'] ?? '',
      advisorPhone: json['advisorPhone'] ?? '',
      guardianName: json['guardianName'] ?? '',
      guardianRelation: json['guardianRelation'] ?? '',
      guardianPhone: json['guardianPhone'] ?? '',
    );
  }
}
