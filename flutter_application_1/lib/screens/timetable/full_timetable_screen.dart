import 'package:flutter/material.dart';
import '../../models/schedule_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class FullTimetableScreen extends StatefulWidget {
  final String room;

  const FullTimetableScreen({super.key, this.room = 'ม.1/1'});

  @override
  State<FullTimetableScreen> createState() => _FullTimetableScreenState();
}

class _FullTimetableScreenState extends State<FullTimetableScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<TimetableEntry>> _timetableFuture;

  final List<Map<String, String>> _days = const [
    {'key': 'Monday', 'label': 'จันทร์'},
    {'key': 'Tuesday', 'label': 'อังคาร'},
    {'key': 'Wednesday', 'label': 'พุธ'},
    {'key': 'Thursday', 'label': 'พฤหัสบดี'},
    {'key': 'Friday', 'label': 'ศุกร์'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _days.length, vsync: this);
    _loadTimetable();
  }

  void _loadTimetable() {
    setState(() {
      _timetableFuture = ApiService.getFullTimetable(room: widget.room);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildClassCard(TimetableEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.timeRange,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.room,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  entry.subjectCode,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.subjectName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    entry.teacherName,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '${entry.credit} หน่วยกิต',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ตารางเรียนห้อง ${widget.room}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _days.map((d) => Tab(text: d['label'])).toList(),
        ),
      ),
      body: FutureBuilder<List<TimetableEntry>>(
        future: _timetableFuture,
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
                      const Icon(Icons.error_outline, color: Color(0xFFE11D48), size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'ไม่สามารถโหลดตารางเรียนได้',
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
                        style: const TextStyle(fontSize: 12, color: Color(0xFFBE123C)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadTimetable,
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

          final allEntries = snapshot.data ?? [];

          return TabBarView(
            controller: _tabController,
            children: _days.map((day) {
              final dayKey = day['key']!;
              final entriesForDay =
                  allEntries.where((e) => e.day == dayKey).toList();

              if (entriesForDay.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'ไม่มีตารางเรียนในวัน${day['label']}',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entriesForDay.length,
                itemBuilder: (context, index) {
                  return _buildClassCard(entriesForDay[index]);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
