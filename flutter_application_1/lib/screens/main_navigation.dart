import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'grades/grades_screen.dart';
import 'home/home_screen.dart';
import 'profile/profile_screen.dart';
import 'qr/qr_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String studentId;

  const MainNavigationScreen({super.key, this.studentId = 'S001'});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(studentId: widget.studentId),
      QrScreen(studentId: widget.studentId),
      GradesScreen(),
      ProfileScreen(studentId: widget.studentId),
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
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          height: 65,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryLight,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primaryBlue),
              label: 'หน้าหลัก',
            ),
            NavigationDestination(
              icon: Icon(Icons.qr_code_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.qr_code_scanner, color: AppColors.primaryBlue),
              label: 'QR Code',
            ),
            NavigationDestination(
              icon: Icon(Icons.stars_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.stars_rounded, color: AppColors.primaryBlue),
              label: 'ผลการเรียน',
            ),
            NavigationDestination(
              icon: Icon(Icons.badge_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.badge, color: AppColors.primaryBlue),
              label: 'ข้อมูลผู้เรียน',
            ),
          ],
        ),
      ),
    );
  }
}
