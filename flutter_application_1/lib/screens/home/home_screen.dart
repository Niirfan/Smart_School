import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'widgets/attendance_card.dart';
import 'widgets/conduct_card.dart';
import 'widgets/guardian_card.dart';
import 'widgets/schedule_card.dart';
import 'widgets/student_card.dart';

class HomeScreen extends StatefulWidget {
  final String studentId;

  const HomeScreen({super.key, this.studentId = 'S001'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _dashboardFuture = ApiService.getDashboard(studentId: widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1D58D8),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'SmartSchool',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF99F6E4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'TH',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Dashboard Scores • ภาคเรียนที่ 1/2568',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ไม่มีการแจ้งเตือนใหม่')),
              );
            },
            icon: const Icon(Icons.notifications_none_outlined,
                color: AppColors.textPrimary, size: 24),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFE11D48),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'เกิดข้อผิดพลาดในการโหลดข้อมูลจากฐานข้อมูล',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF9F1239),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFBE123C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE11D48),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('ลองใหม่อีกครั้ง'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('ไม่มีข้อมูลในระบบ'),
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _loadData();
              await _dashboardFuture;
            },
            color: AppColors.primaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // 1. Student Profile Card with QR Code Button
                  StudentProfileCard(student: data.student),
                  const SizedBox(height: 14),

                  // 2. Attendance Statistics Card
                  AttendanceCard(stat: data.attendance),
                  const SizedBox(height: 14),

                  // 3. Conduct Score Card
                  ConductCard(conduct: data.conduct),
                  const SizedBox(height: 14),

                  // 4. Today's Schedule Card
                  ScheduleCard(
                    scheduleItems: data.schedule,
                    room: data.student.classroom,
                  ),
                  const SizedBox(height: 14),

                  // 5. Guardian & Advisor Card
                  GuardianContactCard(student: data.student),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
