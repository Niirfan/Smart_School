import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import '../models/conduct_model.dart';
import '../models/grade_model.dart';
import '../models/schedule_model.dart';
import '../models/student_model.dart';
import '../models/teacher_model.dart';
import '../models/leave_model.dart';

class DashboardData {
  final StudentModel student;
  final AttendanceStat attendance;
  final ConductModel conduct;
  final List<ScheduleItem> schedule;

  const DashboardData({
    required this.student,
    required this.attendance,
    required this.conduct,
    required this.schedule,
  });
}

class AdvisorRoomStats {
  final String room;
  final int totalStudents;
  final int presentCount;
  final int lateCount;
  final int sickLeaveCount;
  final int businessLeaveCount;
  final int absentCount;
  final int notCheckedInCount;

  const AdvisorRoomStats({
    required this.room,
    required this.totalStudents,
    required this.presentCount,
    required this.lateCount,
    required this.sickLeaveCount,
    required this.businessLeaveCount,
    required this.absentCount,
    required this.notCheckedInCount,
  });

  factory AdvisorRoomStats.fromJson(Map<String, dynamic> json) {
    return AdvisorRoomStats(
      room: json['room']?.toString() ?? '',
      totalStudents: json['totalStudents'] ?? 0,
      presentCount: json['presentCount'] ?? 0,
      lateCount: json['lateCount'] ?? 0,
      sickLeaveCount: json['sickLeaveCount'] ?? 0,
      businessLeaveCount: json['businessLeaveCount'] ?? 0,
      absentCount: json['absentCount'] ?? 0,
      notCheckedInCount: json['notCheckedInCount'] ?? 0,
    );
  }
}

class AbsentOrLeaveStudent {
  final String studentId;
  final String name;
  final String status;

  const AbsentOrLeaveStudent({
    required this.studentId,
    required this.name,
    required this.status,
  });

  factory AbsentOrLeaveStudent.fromJson(Map<String, dynamic> json) {
    return AbsentOrLeaveStudent(
      studentId: json['studentId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}

class TeacherDashboardData {
  final TeacherModel teacher;
  final List<ScheduleItem> todaySchedule;
  final TeacherStats stats;
  final AdvisorRoomStats? advisorRoomStats;
  final List<AbsentOrLeaveStudent> absentOrLeaveList;

  const TeacherDashboardData({
    required this.teacher,
    required this.todaySchedule,
    required this.stats,
    this.advisorRoomStats,
    this.absentOrLeaveList = const [],
  });
}

class ApiService {
  // กำหนด Base URL บน Server 172.18.111.42
  // Base URL ชี้ไปที่โฟลเดอร์ api
  static String baseUrl = 'https://std.mcs.psu.ac.th/6620310131/html/Mobile/api';

  // ============================================================
  // ฝั่งนักเรียน (เดิม)
  // ============================================================

  /// ดึงข้อมูล Dashboard ทั้งหมดของนักเรียน (จากฐานข้อมูลจริงเท่านั้น)
  static Future<DashboardData> getDashboard({String studentId = 'S001'}) async {
    final url = '$baseUrl/api_dashboard.php?student_id=$studentId';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true && json['data'] != null) {
        final data = json['data'];
        return DashboardData(
          student: StudentModel.fromJson(data['student']),
          attendance: AttendanceStat.fromJson(data['attendance']),
          conduct: ConductModel.fromJson(data['conduct']),
          schedule: (data['schedule'] as List<dynamic>?)
                  ?.map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
        );
      } else {
        throw Exception(json['message'] ?? 'ไม่พบข้อมูลนักเรียนในฐานข้อมูล');
      }
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ดึงข้อมูลผลการเรียนและเกรด (จากฐานข้อมูลจริงเท่านั้น)
  static Future<List<GradeItem>> getGrades({String studentId = 'S001'}) async {
    final url = '$baseUrl/api_grades.php?student_id=$studentId';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true && json['grades'] != null) {
        return (json['grades'] as List<dynamic>)
            .map((e) => GradeItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(json['message'] ?? 'ไม่พบข้อมูลเกรดในฐานข้อมูล');
      }
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ดึงประวัติคะแนนพฤติกรรมทั้งหมดของนักเรียน
  static Future<List<ConductRecord>> getConductHistory({String studentId = 'S001'}) async {
    final url = '$baseUrl/api_conduct_history.php?student_id=$studentId';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true && json['records'] != null) {
        return (json['records'] as List<dynamic>)
            .map((e) => ConductRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(json['message'] ?? 'ไม่พบข้อมูลประวัติพฤติกรรม');
      }
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ดึงตารางเรียนทั้งหมดของห้องเรียน (จากฐานข้อมูลจริงเท่านั้น)
  static Future<List<TimetableEntry>> getFullTimetable({String room = 'ม.1/1'}) async {
    final url = '$baseUrl/api_full_timetable.php?room=${Uri.encodeComponent(room)}';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true && json['timetable'] != null) {
        final Map<String, dynamic> map = json['timetable'];
        final List<TimetableEntry> entries = [];
        map.forEach((day, list) {
          if (list is List) {
            for (final item in list) {
              entries.add(TimetableEntry.fromJson(day, item as Map<String, dynamic>));
            }
          }
        });
        return entries;
      } else {
        throw Exception(json['message'] ?? 'ไม่พบตารางเรียนในฐานข้อมูล');
      }
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// Login นักเรียนด้วย student_id/password
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final url = '$baseUrl/api_login.php';
    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'student_id': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return json;
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// สมัครสมาชิกนักเรียนใหม่ (ตั้งรหัสผ่านครั้งแรก)
  static Future<Map<String, dynamic>> register({
    required String studentId,
    required String password,
    String accountType = 'student',
  }) async {
    final url = '$baseUrl/api_register.php';
    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'account_id': studentId,
            'account_type': accountType,
            'password': password,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return json;
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// รีเซ็ตรหัสผ่านนักเรียน (ยืนยันตัวตนผ่าน Google Account Email)
  static Future<Map<String, dynamic>> forgotPassword({
    required String studentId,
    required String email,
    required String newPassword,
  }) async {
    final url = '$baseUrl/api_forgot_password.php';
    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'student_id': studentId,
            'email': email,
            'new_password': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return json;
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  // ============================================================
  // ฝั่งครู (ใหม่)
  // ============================================================

  /// Login ครูด้วย teacher_id/password
  static Future<Map<String, dynamic>> teacherLogin({
    required String teacherId,
    required String password,
  }) async {
    final url = '$baseUrl/api_teacher_login.php';
    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'teacher_id': teacherId, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      return json;
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ดึงข้อมูล Dashboard ครู (ข้อมูลผู้สอน + ตารางสอนวันนี้ + สถิติ)
  static Future<TeacherDashboardData> getTeacherDashboard({required String teacherId}) async {
    final url = '$baseUrl/api_teacher_dashboard.php?teacher_id=${Uri.encodeComponent(teacherId)}';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true) {
        return TeacherDashboardData(
          teacher: TeacherModel.fromJson(json['teacher']),
          todaySchedule: (json['today_schedule'] as List<dynamic>?)
                  ?.map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
          stats: TeacherStats.fromJson(json['stats']),
          advisorRoomStats: json['advisor_room_stats'] != null
              ? AdvisorRoomStats.fromJson(json['advisor_room_stats'])
              : null,
          absentOrLeaveList: (json['absent_or_leave_list'] as List<dynamic>?)
                  ?.map((e) => AbsentOrLeaveStudent.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
        );
      } else {
        throw Exception(json['message'] ?? 'ไม่พบข้อมูลครูในฐานข้อมูล');
      }
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ดึงรายชื่อนักเรียนตามห้อง
  static Future<List<StudentModel>> getStudentsByRoom({required String room}) async {
    final url = '$baseUrl/api_teacher_students.php?room=${Uri.encodeComponent(room)}';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true && json['students'] != null) {
        return (json['students'] as List<dynamic>)
            .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(json['message'] ?? 'ไม่พบรายชื่อนักเรียน');
      }
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ดึงคาบสอนของครูตามวันที่เลือก
  static Future<List<ScheduleItem>> getTeacherSchedule({
    required String teacherId,
    required String date,
  }) async {
    final url = '$baseUrl/api_teacher_schedule.php?teacher_id=${Uri.encodeComponent(teacherId)}&date=${Uri.encodeComponent(date)}';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true) {
        return (json['schedule'] as List<dynamic>? ?? [])
            .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(json['message'] ?? 'ไม่พบตารางสอน');
    }
    throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
  }

  /// บันทึกเช็คชื่อจากสแกน QR หรือกรอกรหัส (daily_attendance)
  static Future<Map<String, dynamic>> saveQrAttendance({
    required String studentId,
    required String teacherId,
    required String scanType, // 'in' หรือ 'out'
    String status = 'มาเรียน',
    String? time,
  }) async {
    final url = '$baseUrl/api_teacher_attendance.php';
    final Map<String, dynamic> body = {
      'student_id': studentId,
      'teacher_id': teacherId,
      'scan_type': scanType,
      'status': status,
    };
    if (time != null && time.trim().isNotEmpty) {
      body['time'] = time.trim();
    }

    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ดึงรายชื่อ + สถานะเช็คชื่อวันนี้ (daily_attendance) ตามห้อง
  static Future<List<StudentModel>> getDailyAttendance({required String room}) async {
    final url = '$baseUrl/api_teacher_attendance.php?room=${Uri.encodeComponent(room)}';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true && json['students'] != null) {
        return (json['students'] as List<dynamic>)
            .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(json['message'] ?? 'ไม่พบข้อมูลเช็คชื่อ');
      }
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// บันทึกเช็คชื่อรายคาบ (subject_attendance) ทั้งห้องพร้อมกัน
  static Future<Map<String, dynamic>> saveSubjectAttendance({
    required String scheduleId,
    required String teacherId,
    required List<Map<String, String>> records, // [{student_id, status}, ...]
    String? date,
  }) async {
    final url = '$baseUrl/api_teacher_subject_attendance.php';
    final Map<String, dynamic> body = {
      'schedule_id': scheduleId,
      'teacher_id': teacherId,
      'records': records,
    };
    if (date != null && date.trim().isNotEmpty) {
      body['date'] = date.trim();
    }

    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ดึงรายชื่อ + สถานะเช็คชื่อรายคาบ
  static Future<List<StudentModel>> getSubjectAttendance({
    required String scheduleId,
    required String teacherId,
    String? date,
  }) async {
    var url =
        '$baseUrl/api_teacher_subject_attendance.php?schedule_id=${Uri.encodeComponent(scheduleId)}&teacher_id=${Uri.encodeComponent(teacherId)}';
    if (date != null && date.trim().isNotEmpty) {
      url += '&date=${Uri.encodeComponent(date.trim())}';
    }

    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true && json['students'] != null) {
        return (json['students'] as List<dynamic>)
            .map((e) => StudentModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(json['message'] ?? 'ไม่พบข้อมูลเช็คชื่อ');
      }
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// บันทึกคะแนนความประพฤติ
  static Future<Map<String, dynamic>> saveConductScore({
    required String studentId,
    required String teacherId,
    required num scoreChange,
    required String reason,
  }) async {
    final url = '$baseUrl/api_teacher_conduct.php';
    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'student_id': studentId,
            'teacher_id': teacherId,
            'score_change': scoreChange,
            'reason': reason,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ดึงประวัติคะแนนความประพฤติที่ครูคนนี้เคยบันทึก
  static Future<List<ConductRecord>> getTeacherConductHistory({required String teacherId}) async {
    final url = '$baseUrl/api_teacher_conduct.php?teacher_id=${Uri.encodeComponent(teacherId)}';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true && json['history'] != null) {
        return (json['history'] as List<dynamic>)
            .map((e) => ConductRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(json['message'] ?? 'ไม่พบประวัติการบันทึก');
      }
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// บันทึกคะแนนรายวิชาทั้งห้องพร้อมกัน
  static Future<Map<String, dynamic>> saveGrades({
    required String subjectId,
    required int academicYear,
    required int semester,
    required List<Map<String, dynamic>> records, // [{student_id, total_score}, ...]
  }) async {
    final url = '$baseUrl/api_teacher_grades.php';
    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'subject_id': subjectId,
            'academic_year': academicYear,
            'semester': semester,
            'records': records,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ดึงคะแนนรายวิชาปัจจุบัน ตามวิชา/ห้อง/ปี/เทอม
  static Future<List<GradeItem>> getGradesByRoom({
    required String subjectId,
    required String room,
    required int academicYear,
    required int semester,
  }) async {
    final url = '$baseUrl/api_teacher_grades.php'
        '?subject_id=${Uri.encodeComponent(subjectId)}'
        '&room=${Uri.encodeComponent(room)}'
        '&academic_year=$academicYear'
        '&semester=$semester';
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true && json['students'] != null) {
        return (json['students'] as List<dynamic>)
            .map((e) => GradeItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(json['message'] ?? 'ไม่พบข้อมูลคะแนน');
      }
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// บันทึกการลาของนักเรียน (leave_requests) — เฉพาะครูที่ปรึกษา
  static Future<Map<String, dynamic>> saveLeaveRequest({
    required String studentId,
    required String teacherId,
    required String leaveType, // 'ลาป่วย' หรือ 'ลากิจ'
    required String leaveDate, // 'YYYY-MM-DD'
    String? reason,
  }) async {
    final url = '$baseUrl/api_teacher_leave.php';
    final response = await http
        .post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'student_id': studentId,
            'teacher_id': teacherId,
            'leave_type': leaveType,
            'leave_date': leaveDate,
            'reason': reason ?? '',
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ดึงรายการลาทั้งห้องที่ปรึกษา (หรือของนักเรียนคนเดียวถ้าระบุ studentId)
  static Future<List<LeaveRecord>> getLeaveRequests({
    required String teacherId,
    String? studentId,
  }) async {
    var url = '$baseUrl/api_teacher_leave.php?teacher_id=${Uri.encodeComponent(teacherId)}';
    if (studentId != null && studentId.isNotEmpty) {
      url += '&student_id=${Uri.encodeComponent(studentId)}';
    }
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true && json['records'] != null) {
        return (json['records'] as List<dynamic>)
            .map((e) => LeaveRecord.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(json['message'] ?? 'ไม่พบรายการลา');
      }
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ยกเลิกรายการลาที่บันทึกผิด
  static Future<Map<String, dynamic>> deleteLeaveRequest({
    required String leaveId,
    required String teacherId,
  }) async {
    final url = '$baseUrl/api_teacher_leave.php';
    final request = http.Request('DELETE', Uri.parse(url))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'leave_id': leaveId, 'teacher_id': teacherId});

    final streamedResponse = await request.send().timeout(const Duration(seconds: 10));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }

  /// ดึงรายการแจ้งเตือนของนักเรียน
  static Future<List<Map<String, dynamic>>> getNotifications({required String studentId}) async {
    final url = '$baseUrl/api_notifications.php?student_id=${Uri.encodeComponent(studentId)}';
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success'] == true && json['notifications'] != null) {
        return List<Map<String, dynamic>>.from(json['notifications']);
      }
      return [];
    } else {
      throw Exception('เซิร์ฟเวอร์ตอบกลับรหัสข้อผิดพลาด: HTTP ${response.statusCode}');
    }
  }
}
