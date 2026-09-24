import 'package:flutter/material.dart';
import '../../../models/conduct_model.dart';
import '../../../services/api_service.dart';
import '../../../theme/app_theme.dart';

class ConductHistoryScreen extends StatefulWidget {
  final String studentId;
  final ConductModel conduct;

  const ConductHistoryScreen({
    super.key,
    required this.studentId,
    required this.conduct,
  });

  @override
  State<ConductHistoryScreen> createState() => _ConductHistoryScreenState();
}

class _ConductHistoryScreenState extends State<ConductHistoryScreen> {
  late Future<List<ConductRecord>> _historyFuture;
  String _filter = 'ทั้งหมด'; // ทั้งหมด, บวก, ลบ

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _historyFuture =
          ApiService.getConductHistory(studentId: widget.studentId);
    });
  }

  Color _scoreColor(num score, num max) {
    if (max == 0) return const Color(0xFFDC2626);
    final pct = score / max;
    if (pct >= 0.8) return const Color(0xFF16A34A);
    if (pct >= 0.6) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  @override
  Widget build(BuildContext context) {
    final conduct = widget.conduct;
    final scorePct = conduct.currentScore / conduct.maxScore;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ประวัติคะแนนพฤติกรรม'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── Summary Header ──────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Score Circle
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: scorePct,
                            strokeWidth: 7,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _scoreColor(conduct.currentScore, conduct.maxScore),
                            ),
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${conduct.currentScore}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _scoreColor(
                                        conduct.currentScore, conduct.maxScore),
                                  ),
                                ),
                                Text(
                                  '/${conduct.maxScore}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'คะแนนพฤติกรรมปัจจุบัน',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${conduct.currentScore} คะแนน',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _scoreColor(
                                  conduct.currentScore, conduct.maxScore),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '★  ระดับ ${conduct.gradeLevel}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: scorePct,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _scoreColor(conduct.currentScore, conduct.maxScore),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(scorePct * 100).toStringAsFixed(0)}% ของคะแนนเต็ม',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Text(
                      'เต็ม ${conduct.maxScore} คะแนน',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Filter chips ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: ['ทั้งหมด', 'บวก', 'ลบ'].map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: AppColors.primaryLight,
                    checkmarkColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primaryBlue
                          : AppColors.textSecondary,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected
                          ? AppColors.primaryBlue
                          : AppColors.border,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── History list ────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<ConductRecord>>(
              future: _historyFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryBlue),
                  );
                }

                // ถ้า API ยังไม่มี endpoint ให้ fallback ใช้ recentRecords
                final List<ConductRecord> all = snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty
                    ? widget.conduct.recentRecords
                    : snapshot.data!;

                final filtered = all.where((r) {
                  if (_filter == 'บวก') return r.pointsChange > 0;
                  if (_filter == 'ลบ') return r.pointsChange < 0;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_toggle_off,
                            size: 52, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'ไม่มีบันทึกในหมวดนี้',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _load(),
                  color: AppColors.primaryBlue,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final rec = filtered[index];
                      final isNeg = rec.pointsChange < 0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isNeg
                              ? const Color(0xFFFFF7F7)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isNeg
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFDCFCE7),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Icon badge
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isNeg
                                    ? const Color(0xFFFEE2E2)
                                    : const Color(0xFFBBF7D0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isNeg
                                    ? Icons.remove_circle_outline
                                    : Icons.add_circle_outline,
                                size: 20,
                                color: isNeg
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF16A34A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Detail
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    rec.title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_outlined,
                                          size: 11,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 3),
                                      Text(
                                        rec.date,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.person_outline,
                                          size: 11,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 3),
                                      Flexible(
                                        child: Text(
                                          rec.recordedBy,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Score change badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isNeg
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF16A34A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                rec.pointsChange > 0
                                    ? '+${rec.pointsChange}'
                                    : '${rec.pointsChange}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
