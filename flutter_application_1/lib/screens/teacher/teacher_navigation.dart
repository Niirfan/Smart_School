import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/teacher_model.dart';
import '../../theme/app_theme.dart';
import 'teacher_home_screen.dart';
import 'teacher_qr_scanner_screen.dart';
import 'teacher_attendance_screen.dart';
import 'teacher_leave_screen.dart'; // ← ไฟล์ใหม่ที่จะสร้างในขั้นถัดไป
import 'teacher_conduct_screen.dart';
import 'teacher_profile_screen.dart';

enum TeacherTab { home, qrScan, subjectAttendance, leaveRequest, conduct, profile }

class TeacherNavigation extends StatefulWidget {
  final TeacherModel teacher;

  const TeacherNavigation({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherNavigation> createState() => _TeacherNavigationState();
}

class _TeacherNavigationState extends State<TeacherNavigation> {
  late TeacherTab _currentTab;
  late final List<_NavEntry> _entries;

  @override
  void initState() {
    super.initState();
    _currentTab = TeacherTab.home;

    final teacher = widget.teacher;
    // เงื่อนไขการมองเห็น ตามสิทธิ์ของครูแต่ละคน
    final canScanQr = teacher.isDisciplinary || teacher.isAdvisor;
    final canRecordLeave = teacher.isAdvisor;

    _entries = [
      _NavEntry(
        tab: TeacherTab.home,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'หน้าหลัก',
        visible: true,
        builder: () => TeacherHomeScreen(
          teacher: teacher,
          onNavigateToTab: _goToTab,
        ),
      ),
      _NavEntry(
        tab: TeacherTab.qrScan,
        icon: Icons.qr_code_scanner_outlined,
        activeIcon: Icons.qr_code_scanner,
        label: 'สแกน QR',
        visible: canScanQr, // ซ่อนถ้าไม่ใช่ที่ปรึกษาและไม่ใช่ฝ่ายปกครอง
        builder: () => TeacherQrScannerScreen(teacher: teacher),
      ),
      _NavEntry(
        tab: TeacherTab.subjectAttendance,
        icon: Icons.how_to_reg_outlined,
        activeIcon: Icons.how_to_reg,
        label: 'เช็คชื่อ',
        visible: true, // ครูทุกคนเช็คชื่อคาบที่ตัวเองสอนได้
        builder: () => TeacherAttendanceScreen(teacher: teacher),
      ),
      _NavEntry(
        tab: TeacherTab.leaveRequest,
        icon: Icons.event_busy_outlined,
        activeIcon: Icons.event_busy,
        label: 'บันทึกลา',
        visible: canRecordLeave, // เฉพาะครูที่ปรึกษาเท่านั้น
        builder: () => TeacherLeaveScreen(teacher: teacher),
      ),
      _NavEntry(
        tab: TeacherTab.conduct,
        icon: Icons.gavel_outlined,
        activeIcon: Icons.gavel,
        label: 'คะแนนพฤติกรรม',
        visible: teacher.isDisciplinary,
        builder: () => TeacherConductScreen(teacher: teacher),
      ),
      _NavEntry(
        tab: TeacherTab.profile,
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'ข้อมูลผู้สอน',
        visible: true,
        builder: () => TeacherProfileScreen(teacher: teacher),
      ),
    ];
  }

  List<_NavEntry> get _visibleEntries => _entries.where((e) => e.visible).toList();

  void _goToTab(TeacherTab tab) {
    final target = _entries.firstWhere((e) => e.tab == tab);
    if (!target.visible) return; // กันเผื่อมีที่เรียกไปยังแท็บที่ถูกซ่อนไว้
    setState(() => _currentTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleEntries;
    final currentIndex = visible.indexWhere((e) => e.tab == _currentTab);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex < 0 ? 0 : currentIndex,
        children: visible.map((e) => e.builder()).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex < 0 ? 0 : currentIndex,
          onTap: (index) => setState(() => _currentTab = visible[index].tab),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryNavy,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.prompt(fontSize: 10),
          elevation: 0,
          items: visible
              .map((e) => BottomNavigationBarItem(
                    icon: Icon(e.icon),
                    activeIcon: Icon(e.activeIcon),
                    label: e.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _NavEntry {
  final TeacherTab tab;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool visible;
  final Widget Function() builder;

  _NavEntry({
    required this.tab,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.visible,
    required this.builder,
  });
}
