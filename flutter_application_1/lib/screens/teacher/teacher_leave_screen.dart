import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/teacher_model.dart';
import '../../models/student_model.dart';
import '../../models/leave_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class TeacherLeaveScreen extends StatefulWidget {
  final TeacherModel teacher;

  const TeacherLeaveScreen({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherLeaveScreen> createState() => _TeacherLeaveScreenState();
}

class _TeacherLeaveScreenState extends State<TeacherLeaveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form State
  List<StudentModel> _students = [];
  bool _isLoadingStudents = false;
  StudentModel? _selectedStudent;
  String _selectedLeaveType = 'ลาป่วย';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  // History State
  late Future<List<LeaveRecord>> _leaveHistoryFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.teacher.isAdvisor) {
      _loadStudents();
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _loadStudents() async {
    final room = widget.teacher.advisorRoom;
    if (room == null || room.isEmpty) return;

    setState(() => _isLoadingStudents = true);
    try {
      final list = await ApiService.getStudentsByRoom(room: room);
      if (mounted) {
        setState(() {
          _students = list;
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStudents = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('โหลดรายชื่อนักเรียนไม่สำเร็จ: $e', style: GoogleFonts.prompt()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _loadHistory() {
    setState(() {
      _leaveHistoryFuture = ApiService.getLeaveRequests(teacherId: widget.teacher.teacherId);
    });
  }

  Future<void> _submitLeave() async {
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเลือกนักเรียน', style: GoogleFonts.prompt()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final res = await ApiService.saveLeaveRequest(
        studentId: _selectedStudent!.studentId,
        teacherId: widget.teacher.teacherId,
        leaveType: _selectedLeaveType,
        leaveDate: dateStr,
        reason: _reasonController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'บันทึกการลาสำเร็จ', style: GoogleFonts.prompt()),
              backgroundColor: AppColors.success,
            ),
          );
          _reasonController.clear();
          setState(() {
            _selectedStudent = null;
          });
          _loadHistory();
          _tabController.animateTo(1); // สลับไปแท็บประวัติ
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'บันทึกไม่สำเร็จ', style: GoogleFonts.prompt()),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteLeave(LeaveRecord record) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 8),
            Text('ยืนยันยกเลิกการลา', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'คุณต้องการยกเลิกการลาของ "${record.studentName}" วันที่ ${record.leaveDate} ใช่หรือไม่?\n(ระบบจะปรับสถานะเข้าแถวกลับเป็น "ขาด")',
          style: GoogleFonts.prompt(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('ยกเลิก', style: GoogleFonts.prompt(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('ยืนยันลบ', style: GoogleFonts.prompt()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.deleteLeaveRequest(
          leaveId: record.leaveId,
          teacherId: widget.teacher.teacherId,
        );
        if (mounted) {
          if (res['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ยกเลิกรายการลาเรียบร้อยแล้ว', style: GoogleFonts.prompt()),
                backgroundColor: AppColors.success,
              ),
            );
            _loadHistory();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res['message'] ?? 'ไม่สามารถยกเลิกได้', style: GoogleFonts.prompt()),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt()),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.teacher.isAdvisor) {
      return Scaffold(
        appBar: AppBar(
          title: Text('บันทึกการลา', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_person_outlined, size: 56, color: Colors.amber.shade800),
                ),
                const SizedBox(height: 20),
                Text(
                  'เฉพาะครูที่ปรึกษาเท่านั้น',
                  style: GoogleFonts.prompt(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'คุณไม่ได้เป็นครูที่ปรึกษาประจำห้อง จึงไม่มีสิทธิ์บันทึกหรือจัดการการลาของนักเรียน',
                  style: GoogleFonts.prompt(fontSize: 14, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          children: [
            Text('ระบบบันทึกการลา', style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(
              'ห้องที่ปรึกษา: ${widget.teacher.advisorRoom}',
              style: GoogleFonts.prompt(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primaryNavy,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.edit_calendar, size: 20), text: 'บันทึกการลา'),
            Tab(icon: Icon(Icons.history, size: 20), text: 'ประวัติการลาในห้อง'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFormTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildFormTab() {
    final dateFormat = DateFormat('d MMMM yyyy', 'th');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ข้อมูลการลานักเรียน',
                style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'ระบบจะบันทึกการลาและอัปเดตสถานะเช็คชื่อแถวประจำวันให้อัตโนมัติ',
                style: GoogleFonts.prompt(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Divider(height: 24),

              // นักเรียน
              Text('เลือกนักเรียน *', style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_isLoadingStudents)
                const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
              else
                DropdownButtonFormField<StudentModel>(
                  initialValue: _selectedStudent,
                  isExpanded: true,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryNavy),
                    hintText: 'เลือกนักเรียนในห้องประจำชั้น',
                    hintStyle: GoogleFonts.prompt(fontSize: 13, color: AppColors.textMuted),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  ),
                  items: _students.map((st) {
                    return DropdownMenuItem<StudentModel>(
                      value: st,
                      child: Text(
                        '${st.studentId} - ${st.name} (เลขที่ ${st.seatNumber})',
                        style: GoogleFonts.prompt(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedStudent = val),
                ),

              const SizedBox(height: 20),

              // ประเภทการลา
              Text('ประเภทการลา *', style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.medication_outlined,
                            size: 18,
                            color: _selectedLeaveType == 'ลาป่วย' ? Colors.white : Colors.red.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text('ลาป่วย', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      selected: _selectedLeaveType == 'ลาป่วย',
                      selectedColor: Colors.red.shade600,
                      labelStyle: GoogleFonts.prompt(
                        color: _selectedLeaveType == 'ลาป่วย' ? Colors.white : AppColors.textPrimary,
                      ),
                      backgroundColor: Colors.red.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedLeaveType = 'ลาป่วย');
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 18,
                            color: _selectedLeaveType == 'ลากิจ' ? Colors.white : Colors.blue.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text('ลากิจ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      selected: _selectedLeaveType == 'ลากิจ',
                      selectedColor: Colors.blue.shade600,
                      labelStyle: GoogleFonts.prompt(
                        color: _selectedLeaveType == 'ลากิจ' ? Colors.white : AppColors.textPrimary,
                      ),
                      backgroundColor: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedLeaveType = 'ลากิจ');
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // วันที่ลา
              Text('วันที่ลา *', style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.primaryNavy, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        dateFormat.format(_selectedDate),
                        style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // เหตุผล
              Text('เหตุผลการลา (ถ้ามี)', style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                style: GoogleFonts.prompt(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'เช่น ป่วยเป็นไข้หวัด, ไปทำธุระต่างจังหวัดกับผู้ปกครอง',
                  hintStyle: GoogleFonts.prompt(fontSize: 12, color: AppColors.textMuted),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),

              const SizedBox(height: 24),

              // ปุ่มบันทึก
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSubmitting ? 'กำลังบันทึก...' : 'บันทึกการลา',
                    style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: () async => _loadHistory(),
      child: FutureBuilder<List<LeaveRecord>>(
        future: _leaveHistoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                    const SizedBox(height: 12),
                    Text('เกิดข้อผิดพลาดในการดึงข้อมูล', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                    Text('${snapshot.error}', style: GoogleFonts.prompt(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadHistory,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text('โหลดใหม่', style: GoogleFonts.prompt()),
                    ),
                  ],
                ),
              ),
            );
          }

          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_available, size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('ไม่มีประวัติการลาในห้องประจำชั้น', style: GoogleFonts.prompt(fontSize: 15, color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = records[index];
              final isSick = item.leaveType == 'ลาป่วย';

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.border, width: 0.8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSick ? Colors.red.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isSick ? Icons.medication : Icons.assignment,
                          color: isSick ? Colors.red.shade700 : Colors.blue.shade700,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.studentName,
                                    style: GoogleFonts.prompt(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSick ? Colors.red.shade100 : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    item.leaveType,
                                    style: GoogleFonts.prompt(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSick ? Colors.red.shade800 : Colors.blue.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'รหัส: ${item.studentId} • วันที่ลา: ${item.leaveDate}',
                              style: GoogleFonts.prompt(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            if (item.reason != null && item.reason!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  'เหตุผล: ${item.reason}',
                                  style: GoogleFonts.prompt(fontSize: 11, color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                        tooltip: 'ยกเลิกการลา',
                        onPressed: () => _confirmDeleteLeave(item),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
