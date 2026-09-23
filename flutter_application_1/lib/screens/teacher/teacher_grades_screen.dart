import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/teacher_model.dart';
import '../../models/student_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class TeacherGradesScreen extends StatefulWidget {
  final TeacherModel teacher;

  const TeacherGradesScreen({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherGradesScreen> createState() => _TeacherGradesScreenState();
}

class _TeacherGradesScreenState extends State<TeacherGradesScreen> {
  String _selectedSubject = 'MATH101';
  final Map<String, String> _subjects = {
    'MATH101': 'คณิตศาสตร์พื้นฐาน',
    'SCI101': 'วิทยาศาสตร์และเทคโนโลยี',
    'ENG101': 'ภาษาอังกฤษพื้นฐาน',
    'THAI101': 'ภาษาไทยพื้นฐาน',
  };

  String _selectedRoom = 'ม.1/1';
  final List<String> _rooms = ['ม.1/1', 'ม.1/2', 'ม.2/1', 'ม.3/1'];

  final int _academicYear = 2567;
  final int _semester = 1;

  List<StudentModel> _students = [];
  final Map<String, TextEditingController> _scoreControllers = {};
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchStudentsAndGrades();
  }

  @override
  void dispose() {
    for (var controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchStudentsAndGrades() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await ApiService.getStudentsByRoom(room: _selectedRoom);
      _students = list;

      for (var controller in _scoreControllers.values) {
        controller.dispose();
      }
      _scoreControllers.clear();

      for (var student in list) {
        _scoreControllers[student.studentId] = TextEditingController(text: '80');
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการดึงข้อมูล: $e', style: GoogleFonts.prompt()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _calculateGrade(double score) {
    if (score >= 80) return '4.0';
    if (score >= 75) return '3.5';
    if (score >= 70) return '3.0';
    if (score >= 65) return '2.5';
    if (score >= 60) return '2.0';
    if (score >= 55) return '1.5';
    if (score >= 50) return '1.0';
    return '0.0';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case '4.0':
      case '3.5':
        return AppColors.success;
      case '3.0':
      case '2.5':
        return AppColors.primaryBlue;
      case '2.0':
      case '1.5':
        return AppColors.warning;
      default:
        return AppColors.danger;
    }
  }

  Future<void> _saveBatchGrades() async {
    if (_students.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final List<Map<String, dynamic>> records = [];
      _scoreControllers.forEach((studentId, controller) {
        final score = double.tryParse(controller.text.trim()) ?? 0;
        records.add({
          'student_id': studentId,
          'total_score': score,
        });
      });

      final res = await ApiService.saveGrades(
        subjectId: _selectedSubject,
        academicYear: _academicYear,
        semester: _semester,
        records: records,
      );

      if (mounted) {
        final success = res['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ?? (success ? 'บันทึกเกรดสำเร็จ' : 'เกิดข้อผิดพลาด'),
              style: GoogleFonts.prompt(),
            ),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการบันทึก: $e', style: GoogleFonts.prompt()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('บันทึกผลการเรียน (เกรด)', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('วิชา:', style: GoogleFonts.prompt(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSubject,
                                isExpanded: true,
                                items: _subjects.entries.map((e) {
                                  return DropdownMenuItem<String>(
                                    value: e.key,
                                    child: Text(e.value, style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedSubject = val);
                                    _fetchStudentsAndGrades();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ห้อง:', style: GoogleFonts.prompt(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRoom,
                                isExpanded: true,
                                items: _rooms.map((r) {
                                  return DropdownMenuItem<String>(
                                    value: r,
                                    child: Text(r, style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600)),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedRoom = val);
                                    _fetchStudentsAndGrades();
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'กรอกคะแนนรวม (0 - 100)',
                  style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary),
                ),
                Text(
                  'ปีการศึกษา $_academicYear / ภาคเรียนที่ $_semester',
                  style: GoogleFonts.prompt(fontSize: 12, color: AppColors.primaryBlue),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(child: Text('ไม่พบรายชื่อนักเรียน', style: GoogleFonts.prompt(color: AppColors.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final controller = _scoreControllers[student.studentId];
                          final currentScore = double.tryParse(controller?.text ?? '0') ?? 0;
                          final grade = _calculateGrade(currentScore);
                          final gradeColor = _getGradeColor(grade);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primaryLight,
                                    child: Text(
                                      '${index + 1}',
                                      style: GoogleFonts.prompt(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        Text(
                                          'รหัส: ${student.studentId}',
                                          style: GoogleFonts.prompt(fontSize: 12, color: AppColors.textMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    width: 70,
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        labelText: 'คะแนน',
                                        labelStyle: GoogleFonts.prompt(fontSize: 11),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onChanged: (val) {
                                        setState(() {}); // Update grade badge
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: gradeColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: gradeColor),
                                    ),
                                    child: Text(
                                      'เกรด $grade',
                                      style: GoogleFonts.prompt(
                                        color: gradeColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveBatchGrades,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: Text(
              _isSaving ? 'กำลังบันทึก...' : 'บันทึกเกรดทั้งหมด',
              style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
