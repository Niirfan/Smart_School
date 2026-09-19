import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import '../models/conduct_model.dart';
import '../models/grade_model.dart';
import '../models/schedule_model.dart';
import '../models/student_model.dart';

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

class ApiService {
  // กำหนด Base URL บน Server 172.18.111.42
  // Base URL ชี้ไปที่โฟลเดอร์ api
  static String baseUrl = 'https://std.mcs.psu.ac.th/6620310131/html/Mobile/api';

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
}
