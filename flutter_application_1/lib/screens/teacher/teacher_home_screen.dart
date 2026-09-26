import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/teacher_model.dart';
import '../../models/schedule_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'teacher_navigation.dart';

class TeacherHomeScreen extends StatefulWidget {
  final TeacherModel teacher;
  final Function(TeacherTab tab)? onNavigateToTab;

  const TeacherHomeScreen({
    super.key,
    required this.teacher,
    this.onNavigateToTab,
  });

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  late Future<TeacherDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  void _loadDashboard() {
    setState(() {
      _dashboardFuture = ApiService.getTeacherDashboard(teacherId: widget.teacher.teacherId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => _loadDashboard(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDashboardContent(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryNavy, Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยินดีต้อนรับคุณครู 👋',
                      style: GoogleFonts.prompt(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      widget.teacher.name,
                      style: GoogleFonts.prompt(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'กลุ่มสาระ: ${widget.teacher.department ?? "ทั่วไป"}${widget.teacher.advisorRoom != null && widget.teacher.advisorRoom!.isNotEmpty ? " • ประจำชั้น ${widget.teacher.advisorRoom}" : ""}',
                      style: GoogleFonts.prompt(
                        color: Colors.amber.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.teacher.isDisciplinary)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.redAccent, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shield, color: Colors.redAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'ฝ่ายปกครอง',
                        style: GoogleFonts.prompt(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return FutureBuilder<TeacherDashboardData>(
      future: _dashboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.danger, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'เกิดข้อผิดพลาดในการโหลดข้อมูล',
                    style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${snapshot.error}',
                    style: GoogleFonts.prompt(color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _loadDashboard,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: Text('ลองใหม่', style: GoogleFonts.prompt()),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'คาบสอนวันนี้',
                    value: '${data.stats.periodsToday}',
                    subtitle: 'คาบ',
                    icon: Icons.menu_book,
                    color: AppColors.primaryBlue,
                    bgColor: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'นักเรียนในคาบ',
                    value: '${data.stats.studentsCount}',
                    subtitle: 'คน',
                    icon: Icons.people,
                    color: AppColors.purple,
                    bgColor: AppColors.purpleBg,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (data.advisorRoomStats != null) ...[
              _buildAdvisorRoomOverview(data),
              const SizedBox(height: 20),
            ],

            // Quick Menu Section
            Text(
              'เมนูจัดการการสอน',
              style: GoogleFonts.prompt(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildQuickMenuGrid(),

            const SizedBox(height: 24),

            // Today Schedule Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ตารางสอนวันนี้',
                  style: GoogleFonts.prompt(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${data.todaySchedule.length} คาบ',
                  style: GoogleFonts.prompt(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (data.todaySchedule.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_available, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'ไม่มีตารางสอนในวันนี้',
                          style: GoogleFonts.prompt(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.todaySchedule.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = data.todaySchedule[index];
                  return _buildScheduleCard(item);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildAdvisorRoomOverview(TeacherDashboardData data) {
    final stats = data.advisorRoomStats!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'สรุปห้องที่ปรึกษา ${stats.room}',
              style: GoogleFonts.prompt(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMiniStatus('มาเรียน', stats.presentCount, Colors.green),
                _buildMiniStatus('มาสาย', stats.lateCount, Colors.orange),
                _buildMiniStatus('ลากิจ', stats.businessLeaveCount, Colors.blue),
                _buildMiniStatus('ลาป่วย', stats.sickLeaveCount, Colors.indigo),
                _buildMiniStatus('ขาด', stats.absentCount, Colors.red),
                _buildMiniStatus('ยังไม่เช็คชื่อ', stats.notCheckedInCount, Colors.grey),
              ],
            ),
            if (data.absentOrLeaveList.isNotEmpty) ...[
              const Divider(height: 24),
              Text('รายชื่อที่ต้องติดตาม', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...data.absentOrLeaveList.map((student) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.person_outline),
                    title: Text(student.name, style: GoogleFonts.prompt(fontSize: 13)),
                    subtitle: Text(student.studentId, style: GoogleFonts.prompt(fontSize: 11)),
                    trailing: Text(student.status, style: GoogleFonts.prompt(fontSize: 12, color: AppColors.danger)),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatus(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label $count', style: GoogleFonts.prompt(fontSize: 12, color: color)),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.prompt(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.prompt(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.prompt(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenuGrid() {
    final items = [
      {
        'title': 'สแกน QR',
        'subtitle': 'เช็กชื่อเข้า/ออก',
        'icon': Icons.qr_code_scanner,
        'color': AppColors.primaryBlue,
        'bgColor': AppColors.primaryLight,
        'tab': TeacherTab.qrScan,
      },
      {
        'title': 'เช็กชื่อคาบเรียน',
        'subtitle': 'เลือกรายวิชา',
        'icon': Icons.how_to_reg,
        'color': AppColors.success,
        'bgColor': AppColors.successBg,
        'tab': TeacherTab.subjectAttendance,
      },
      if (widget.teacher.isAdvisor)
        {
          'title': 'บันทึกลา',
          'subtitle': 'ลาป่วย/ลากิจ',
          'icon': Icons.event_busy,
          'color': Colors.orange.shade800,
          'bgColor': Colors.orange.shade50,
          'tab': TeacherTab.leaveRequest,
        },
      {
        'title': 'ข้อมูลผู้สอน',
        'subtitle': 'โปรไฟล์/ความประพฤติ',
        'icon': Icons.person_outline,
        'color': AppColors.purple,
        'bgColor': AppColors.purpleBg,
        'tab': TeacherTab.profile,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () {
            if (widget.onNavigateToTab != null) {
              widget.onNavigateToTab!(item['tab'] as TeacherTab);
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item['bgColor'] as Color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: item['color'] as Color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item['subtitle'] as String,
                        style: GoogleFonts.prompt(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScheduleCard(ScheduleItem item) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Icon(Icons.access_time, size: 16, color: AppColors.primaryNavy),
                  const SizedBox(height: 4),
                  Text(
                    item.timeRange,
                    style: GoogleFonts.prompt(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.subjectName,
                    style: GoogleFonts.prompt(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.room, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Text(
                        'ห้อง ${item.room}',
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.subjectCode != null && item.subjectCode!.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(${item.subjectCode})',
                          style: GoogleFonts.prompt(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (widget.onNavigateToTab != null) {
                  widget.onNavigateToTab!(TeacherTab.subjectAttendance); // ไปหน้าเช็กชื่อ
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'เช็กชื่อ',
                style: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
