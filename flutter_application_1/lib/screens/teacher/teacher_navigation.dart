import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/teacher_model.dart';
import '../../theme/app_theme.dart';
import 'teacher_home_screen.dart';
import 'teacher_qr_scanner_screen.dart';
import 'teacher_attendance_screen.dart';
import 'teacher_profile_screen.dart';

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
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TeacherHomeScreen(
        teacher: widget.teacher,
        onNavigateToTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      TeacherQrScannerScreen(teacher: widget.teacher),
      TeacherAttendanceScreen(teacher: widget.teacher),
      TeacherProfileScreen(teacher: widget.teacher),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
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
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryNavy,
          unselectedItemColor: AppColors.textMuted,
          selectedLabelStyle: GoogleFonts.prompt(fontSize: 11, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.prompt(fontSize: 10),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'หน้าหลัก',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.qr_code_scanner),
              label: 'สแกน QR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.how_to_reg_outlined),
              activeIcon: Icon(Icons.how_to_reg),
              label: 'มาเรียน',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'ข้อมูลผู้สอน',
            ),
          ],
        ),
      ),
    );
  }
}
