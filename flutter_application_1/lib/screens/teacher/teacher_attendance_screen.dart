import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/teacher_model.dart';
import '../../models/schedule_model.dart';
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
  static const List<String> _statusOptions = ['มาเรียน', 'มาสาย', 'ขาด', 'ลาป่วย', 'ลากิจ'];

  List<ScheduleItem> _periods = []; // คาบสอนของครูคนนี้ (มี scheduleId เท่านั้น)
  ScheduleItem? _selectedPeriod;
  DateTime _selectedDate = DateTime.now();

  List<StudentModel> _students = [];
  final Map<String, String> _attendanceStatusMap = {};

  bool _isLoadingPeriods = true;
  bool _isLoadingStudents = false;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _fetchPeriods();
  }

  String get _dateKey =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  String get _dateLabel =>
      '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year + 543}';

  Future<void> _fetchPeriods() async {
    setState(() {
      _isLoadingPeriods = true;
      _loadError = null;
    });

    try {
      final rawPeriods = await ApiService.getTeacherSchedule(
        teacherId: widget.teacher.teacherId,
        date: _dateKey,
      );
      // เอาเฉพาะคาบที่มี scheduleId จริง (กันกรณี field ว่างจาก backend เก่าที่ยังไม่ได้แก้)
      final periods = rawPeriods
          .where((p) => p.scheduleId != null && p.scheduleId!.isNotEmpty)
          .toList();

      setState(() {
        _periods = periods;
        _selectedPeriod = periods.isNotEmpty ? periods.first : null;
      });

      if (_selectedPeriod != null) {
        await _fetchStudents();
      }
    } catch (e) {
      setState(() {
        _loadError = 'โหลดตารางสอนไม่สำเร็จ: $e';
      });
    } finally {
      setState(() {
        _isLoadingPeriods = false;
      });
    }
  }

  Future<void> _fetchStudents() async {
    if (_selectedPeriod == null || _selectedPeriod!.scheduleId == null) return;

    setState(() {
      _isLoadingStudents = true;
      _students = [];
      _attendanceStatusMap.clear();
    });

    try {
      final list = await ApiService.getSubjectAttendance(
        scheduleId: _selectedPeriod!.scheduleId!,
        teacherId: widget.teacher.teacherId,
        date: _dateKey,
      );
      setState(() {
        _students = list;
        for (final s in list) {
          // ค่าเริ่มต้นเป็น "มาเรียน" ทุกคน (ถ้าต้องการดึงสถานะที่บันทึกไว้แล้วมา prefill
          // ต้องเพิ่ม field สถานะใน student_model.dart ให้รับ 'status' จาก backend ด้วย)
          // ใช้สถานะเดิมจากฐานข้อมูล ไม่รีเซ็ตข้อมูลเก่าเป็น "มาเรียน"
          final savedStatus = s.status.trim();
          _attendanceStatusMap[s.studentId] = _statusOptions.contains(savedStatus)
              ? savedStatus
              : 'มาเรียน';
        }
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
        _isLoadingStudents = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _fetchPeriods();
    }
  }

  Future<void> _saveAttendance() async {
    if (_selectedPeriod == null || _selectedPeriod!.scheduleId == null || _students.isEmpty) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final records = _students
          .map((s) => {
                'student_id': s.studentId,
                'status': _attendanceStatusMap[s.studentId] ?? 'มาเรียน',
              })
          .toList();

      final res = await ApiService.saveSubjectAttendance(
        scheduleId: _selectedPeriod!.scheduleId!,
        teacherId: widget.teacher.teacherId,
        records: records,
        date: _dateKey,
      );

      if (mounted) {
        final success = res['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ?? (success ? 'บันทึกสำเร็จ' : 'เกิดข้อผิดพลาด'),
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
        title: Text('เช็คชื่อรายคาบ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingPeriods
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_loadError!, style: GoogleFonts.prompt(color: AppColors.danger), textAlign: TextAlign.center),
                  ),
                )
              : _periods.isEmpty
                  ? Center(
                      child: Text('วันนี้คุณไม่มีคาบสอน', style: GoogleFonts.prompt(color: AppColors.textMuted)),
                    )
                  : Column(
                      children: [
                        _buildSelectorBar(),
                        const SizedBox(height: 10),
                        _buildSummaryRow(),
                        Expanded(child: _buildStudentList()),
                      ],
                    ),
      bottomNavigationBar: (_periods.isEmpty || _students.isEmpty) ? null : _buildSaveBar(),
    );
  }

  Widget _buildSelectorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('คาบเรียน: ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ScheduleItem>(
                      value: _selectedPeriod,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryNavy),
                      items: _periods.map((p) {
                        return DropdownMenuItem<ScheduleItem>(
                          value: p,
                          child: Text(
                            '${p.timeRange} • ${p.subjectName} (${p.room})',
                            style: GoogleFonts.prompt(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPeriod = val);
                          _fetchStudents();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('วันที่: ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_dateLabel, style: GoogleFonts.prompt(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'รายชื่อนักเรียน (${_students.length} คน)',
            style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary),
          ),
          TextButton.icon(
            onPressed: _students.isEmpty
                ? null
                : () {
                    setState(() {
                      for (final s in _students) {
                        _attendanceStatusMap[s.studentId] = 'มาเรียน';
                      }
                    });
                  },
            icon: const Icon(Icons.select_all, size: 16),
            label: Text('ตั้งค่าทุกคนเป็นมาเรียน', style: GoogleFonts.prompt(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList() {
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_students.isEmpty) {
      return Center(
        child: Text('ไม่พบรายชื่อนักเรียนในคาบนี้', style: GoogleFonts.prompt(color: AppColors.textMuted)),
      );
    }

    return ListView.builder(
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
                        style: GoogleFonts.prompt(color: AppColors.primaryNavy, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(student.name, style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(
                            'รหัส: ${student.studentId}',
                            style: GoogleFonts.prompt(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _statusOptions
                      .map((opt) => _buildStatusChip(student.studentId, opt, currentStatus))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String studentId, String statusLabel, String currentStatus) {
    final isSelected = currentStatus == statusLabel;
    final Color activeColor = switch (statusLabel) {
      'มาเรียน' => AppColors.success,
      'มาสาย' => AppColors.warning,
      'ลาป่วย' => AppColors.info,
      'ลากิจ' => AppColors.info,
      'ขาด' => AppColors.danger,
      _ => AppColors.textMuted,
    };

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

  Widget _buildSaveBar() {
    return Container(
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
          onPressed: _isSaving ? null : _saveAttendance,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.save, color: Colors.white),
          label: Text(
            _isSaving ? 'กำลังบันทึก...' : 'บันทึกผลการเช็กชื่อคาบนี้',
            style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
