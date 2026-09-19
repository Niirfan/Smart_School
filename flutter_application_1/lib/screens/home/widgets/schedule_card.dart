import 'package:flutter/material.dart';
import '../../../models/schedule_model.dart';
import '../../../theme/app_theme.dart';
import '../../timetable/full_timetable_screen.dart';

class ScheduleCard extends StatelessWidget {
  final List<ScheduleItem> scheduleItems;
  final String room;

  const ScheduleCard({
    super.key,
    required this.scheduleItems,
    this.room = 'ม.1/1',
  });

  Widget _buildStatusBadge(ClassStatus status) {
    switch (status) {
      case ClassStatus.normal:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.circle, size: 6, color: Color(0xFF0F9456)),
              SizedBox(width: 4),
              Text(
                'เข้าเรียนปกติ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F9456),
                ),
              ),
            ],
          ),
        );
      case ClassStatus.inProgress:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primaryNavy,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'กำลังเรียน',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        );
      case ClassStatus.upcoming:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'ยังไม่ถึงเวลา',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with "ดูทั้งหมด" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.access_time_filled,
                    size: 18,
                    color: AppColors.primaryNavy,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ตารางเรียนวันนี้',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullTimetableScreen(room: room),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: const [
                      Text(
                        'ดูทั้งหมด',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 16, color: AppColors.primaryBlue),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // List of classes without score
          ...scheduleItems.map((item) {
            final isInProgress = item.status == ClassStatus.inProgress;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isInProgress ? const Color(0xFFF8FAFC) : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isInProgress ? const Color(0xFFCBD5E1) : AppColors.border,
                  width: isInProgress ? 1.2 : 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: time & status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.timeRange}  •  ${item.room}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      _buildStatusBadge(item.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Subject Name
                  Row(
                    children: [
                      if (item.subjectCode != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EEFC),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.subjectCode!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          item.subjectName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isInProgress ? const Color(0xFF0F2C59) : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Teacher Name & Note
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.teacherName,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (item.note != null)
                        Text(
                          item.note!,
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
          }),
          const SizedBox(height: 6),
          // Bottom Action Button to view all
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullTimetableScreen(room: room),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.calendar_month_outlined, size: 16, color: AppColors.primaryNavy),
              label: const Text(
                'ดูตารางเรียนทั้งหมด (จันทร์ - ศุกร์)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
