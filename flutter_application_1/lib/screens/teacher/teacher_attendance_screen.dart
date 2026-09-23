import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/teacher_model.dart';
import '../../models/student_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  final TeacherModel teacher;

  const TeacherAttendanceScreen({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  String _selectedRoom = 'ม.1/1';
  final List<String> _rooms = ['ม.1/1', 'ม.1/2', 'ม.2/1', 'ม.3/1'];

  List<StudentModel> _students = [];
  Map<String, String> _attendanceStatusMap = {}; // student_id -> 'มาเรียน' | 'ขาด' | 'สาย' | 'ลา'
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final list = await ApiService.getStudentsByRoom(room: _selectedRoom);
      setState(() {
        _students = list;
        _attendanceStatusMap = {
          for (var s in list) s.studentId: 'มาเรียน' // default ทุกคนมาเรียน
        };
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดรายชื่อ: $e', style: GoogleFonts.prompt()),
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

  Future<void> _saveBatchAttendance() async {
    if (_students.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      int successCount = 0;
      for (var student in _students) {
        final status = _attendanceStatusMap[student.studentId] ?? 'มาเรียน';
        await ApiService.saveQrAttendance(
          studentId: student.studentId,
          teacherId: widget.teacher.teacherId,
          scanType: 'in',
          status: status,
        );
        successCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('บันทึกการเช็กชื่อห้อง $_selectedRoom สำเร็จ ($successCount คน)', style: GoogleFonts.prompt()),
            backgroundColor: AppColors.success,
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
        title: Text('เช็กชื่อนักเรียน (มาเรียน)', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Room selector bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  'เลือกห้องเรียน: ',
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRoom,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryNavy),
                        items: _rooms.map((room) {
                          return DropdownMenuItem<String>(
                            value: room,
                            child: Text(
                              'ห้อง $room',
                              style: GoogleFonts.prompt(fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedRoom = val);
                            _fetchStudents();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Student count summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'รายชื่อนักเรียน (${_students.length} คน)',
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      for (var s in _students) {
                        _attendanceStatusMap[s.studentId] = 'มาเรียน';
                      }
                    });
                  },
                  icon: const Icon(Icons.select_all, size: 16),
                  label: Text('ตั้งค่าทุกคนเป็นมาเรียน', style: GoogleFonts.prompt(fontSize: 12)),
                ),
              ],
            ),
          ),

          // Student List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _students.isEmpty
                    ? Center(
                        child: Text(
                          'ไม่พบรายชื่อนักเรียนในห้องนี้',
                          style: GoogleFonts.prompt(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _students.length,
                        itemBuilder: (context, index) {
                          final student = _students[index];
                          final currentStatus = _attendanceStatusMap[student.studentId] ?? 'มาเรียน';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: AppColors.primaryLight,
                                        child: Text(
                                          '${index + 1}',
                                          style: GoogleFonts.prompt(
                                            color: AppColors.primaryNavy,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student.name,
                                              style: GoogleFonts.prompt(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              'รหัส: ${student.studentId} | ห้อง: ${student.room}',
                                              style: GoogleFonts.prompt(
                                                fontSize: 12,
                                                color: AppColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),

                                  // Attendance Status Toggle Buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildStatusChip(student.studentId, 'มาเรียน', currentStatus, AppColors.success),
                                      _buildStatusChip(student.studentId, 'สาย', currentStatus, AppColors.warning),
                                      _buildStatusChip(student.studentId, 'ลา', currentStatus, AppColors.info),
                                      _buildStatusChip(student.studentId, 'ขาด', currentStatus, AppColors.danger),
                                    ],
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
            onPressed: _isSaving ? null : _saveBatchAttendance,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
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
              _isSaving ? 'กำลังบันทึก...' : 'บันทึกผลการเช็กชื่อทั้งหมด',
              style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String studentId, String statusLabel, String currentStatus, Color activeColor) {
    final isSelected = currentStatus == statusLabel;

    return ChoiceChip(
      label: Text(
        statusLabel,
        style: GoogleFonts.prompt(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: Colors.grey.shade100,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _attendanceStatusMap[studentId] = statusLabel;
          });
        }
      },
    );
  }
}
