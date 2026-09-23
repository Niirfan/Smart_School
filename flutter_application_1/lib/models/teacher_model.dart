class TeacherModel {
  final String teacherId;
  final String name;
  final String? department;
  final String? phoneNumber;
  final String? address;
  final String? bloodGroup;
  final bool isDisciplinary;

  const TeacherModel({
    required this.teacherId,
    required this.name,
    this.department,
    this.phoneNumber,
    this.address,
    this.bloodGroup,
    this.isDisciplinary = false,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      teacherId: json['teacher_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      department: json['department']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      address: json['address']?.toString(),
      bloodGroup: json['blood_group']?.toString(),
      isDisciplinary: (json['is_disciplinary'] == 1 ||
          json['is_disciplinary'] == '1' ||
          json['is_disciplinary'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teacher_id': teacherId,
      'name': name,
      'department': department,
      'phone_number': phoneNumber,
      'address': address,
      'blood_group': bloodGroup,
      'is_disciplinary': isDisciplinary ? 1 : 0,
    };
  }
}

class TeacherStats {
  final int periodsToday;
  final int studentsCount;
  final int notCheckedInToday;

  const TeacherStats({
    this.periodsToday = 0,
    this.studentsCount = 0,
    this.notCheckedInToday = 0,
  });

  factory TeacherStats.fromJson(Map<String, dynamic> json) {
    return TeacherStats(
      periodsToday: json['periods_today'] is int
          ? json['periods_today']
          : int.tryParse(json['periods_today']?.toString() ?? '0') ?? 0,
      studentsCount: json['students_count'] is int
          ? json['students_count']
          : int.tryParse(json['students_count']?.toString() ?? '0') ?? 0,
      notCheckedInToday: json['not_checked_in_today'] is int
          ? json['not_checked_in_today']
          : int.tryParse(json['not_checked_in_today']?.toString() ?? '0') ?? 0,
    );
  }
}
