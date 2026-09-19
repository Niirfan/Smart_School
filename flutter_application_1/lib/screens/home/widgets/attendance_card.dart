import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../models/attendance_model.dart';
import '../../../theme/app_theme.dart';

class AttendanceCard extends StatelessWidget {
  final AttendanceStat stat;

  const AttendanceCard({super.key, required this.stat});

  Widget _buildStatPill({
    required IconData icon,
    required int count,
    required String label,
    required Color bgColor,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: AppColors.primaryNavy,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'สถิติการมาเรียน',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                'ภาคเรียนที่ 1/2568',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Circular Progress and Status Text
          Row(
            children: [
              CircularPercentIndicator(
                radius: 46.0,
                lineWidth: 8.0,
                animation: true,
                percent: (stat.percentage / 100).clamp(0.0, 1.0),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${stat.percentage}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'มาเรียน',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: const Color(0xFF0D9488),
                backgroundColor: const Color(0xFFCCFBF1),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            stat.statusText,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F9456),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat.note,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 5 Stat Pills
          Row(
            children: [
              _buildStatPill(
                icon: Icons.person_outline,
                count: stat.presentCount,
                label: 'มาเรียน',
                bgColor: const Color(0xFFE6F8F0),
                color: const Color(0xFF0F9456),
              ),
              const SizedBox(width: 6),
              _buildStatPill(
                icon: Icons.access_time,
                count: stat.lateCount,
                label: 'มาสาย',
                bgColor: const Color(0xFFFEF5E7),
                color: const Color(0xFFD97706),
              ),
              const SizedBox(width: 6),
              _buildStatPill(
                icon: Icons.event_note_outlined,
                count: stat.businessLeaveCount,
                label: 'ลากิจ',
                bgColor: const Color(0xFFE8EEFC),
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(width: 6),
              _buildStatPill(
                icon: Icons.medical_services_outlined,
                count: stat.sickLeaveCount,
                label: 'ลาป่วย',
                bgColor: const Color(0xFFF3EDFD),
                color: const Color(0xFF7C3AED),
              ),
              const SizedBox(width: 6),
              _buildStatPill(
                icon: Icons.person_off_outlined,
                count: stat.absentCount,
                label: 'ขาด',
                bgColor: const Color(0xFFFEECEB),
                color: const Color(0xFFE12D39),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

