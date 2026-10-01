import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class StudentAttendanceHistoryScreen extends StatefulWidget {
  final String studentId;

  const StudentAttendanceHistoryScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<StudentAttendanceHistoryScreen> createState() =>
      _StudentAttendanceHistoryScreenState();
}

class _StudentAttendanceHistoryScreenState
    extends State<StudentAttendanceHistoryScreen> {
  late Future<List<DailyAttendanceRecord>> _historyFuture;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<DailyAttendanceRecord>> _loadHistory() {
    return ApiService.getStudentAttendanceHistory(studentId: widget.studentId);
  }

  DateTime? _recordDate(DailyAttendanceRecord record) =>
      DateTime.tryParse(record.date);

  DailyAttendanceRecord? _recordForDate(
    List<DailyAttendanceRecord> records,
    DateTime date,
  ) {
    for (final record in records) {
      final recordDate = _recordDate(record);
      if (recordDate != null &&
          recordDate.year == date.year &&
          recordDate.month == date.month &&
          recordDate.day == date.day) {
        return record;
      }
    }
    return null;
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'มาเรียน':
        return const Color(0xFF16834A);
      case 'มาสาย':
        return const Color(0xFFD97706);
      case 'ลากิจ':
        return const Color(0xFF2563EB);
      case 'ลาป่วย':
        return const Color(0xFF7C3AED);
      case 'ขาด':
        return const Color(0xFFDC2626);
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _refresh() async {
    setState(() => _historyFuture = _loadHistory());
    try {
      await _historyFuture;
    } catch (_) {
      // FutureBuilder displays the request error and its retry button.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ประวัติการมาเรียน'),
        actions: [
          IconButton(
            tooltip: 'โหลดประวัติใหม่',
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<DailyAttendanceRecord>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_outlined,
                        size: 40, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text('โหลดประวัติไม่สำเร็จ'),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _historyFuture = _loadHistory()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองอีกครั้ง'),
                    ),
                  ],
                ),
              ),
            );
          }

          final records = snapshot.data ?? const <DailyAttendanceRecord>[];
          final selectedRecord = _recordForDate(records, _selectedDate);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCalendar(records),
              const SizedBox(height: 14),
              _buildSelectedDay(selectedRecord),
              if (records.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Text(
                    'ยังไม่มีประวัติการเข้า-ออกโรงเรียน',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendar(List<DailyAttendanceRecord> records) {
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final offset = firstOfMonth.weekday - 1;
    final cellCount = ((offset + daysInMonth + 6) ~/ 7) * 7;
    final weekdays = ['จ', 'อ', 'พ', 'พฤ', 'ศ', 'ส', 'อา'];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
                  _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
                }),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy', 'th').format(_visibleMonth),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
                  _selectedDate = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
                }),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: weekdays
                .map((day) => Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(day,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary)),
                        ),
                      ),
                    ))
                .toList(),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cellCount,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - offset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }
              final date = DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
              final record = _recordForDate(records, date);
              final selected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final color = record == null ? Colors.transparent : _statusColor(record.status);
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryBlue : color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.primaryBlue : color.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected || record != null ? FontWeight.bold : FontWeight.normal,
                          color: selected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      if (record != null)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: selected ? Colors.white : color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: ['มาเรียน', 'มาสาย', 'ลากิจ', 'ลาป่วย', 'ขาด']
                .map((status) => _legendItem(status, _statusColor(status)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildSelectedDay(DailyAttendanceRecord? record) {
    final title = DateFormat('d MMMM yyyy', 'th').format(_selectedDate);
    if (record == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text('$title\nไม่มีรายการบันทึกในวันที่เลือก',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, height: 1.5)),
      );
    }

    final statusColor = _statusColor(record.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_note_outlined, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(record.status,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _timeTile('เวลาเข้า', record.scanInTime, Icons.login,
                    const Color(0xFF16834A)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _timeTile('เวลาออก', record.scanOutTime, Icons.logout,
                    const Color(0xFF2563EB)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeTile(String label, String? time, IconData icon, Color color) {
    final displayTime = (time == null || time.isEmpty) ? 'ไม่มีข้อมูล' : time;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
                Text(displayTime,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
