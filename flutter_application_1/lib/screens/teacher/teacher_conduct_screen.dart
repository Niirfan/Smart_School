import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/conduct_model.dart';
import '../../models/teacher_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class TeacherConductScreen extends StatefulWidget {
  final TeacherModel teacher;

  const TeacherConductScreen({super.key, required this.teacher});

  @override
  State<TeacherConductScreen> createState() => _TeacherConductScreenState();
}

class _TeacherConductScreenState extends State<TeacherConductScreen> {
  final _studentIdController = TextEditingController();
  final _scoreController = TextEditingController(text: '-5');
  final _reasonController = TextEditingController();
  late Future<List<ConductRecord>> _historyFuture;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    _historyFuture = ApiService.getTeacherConductHistory(
      teacherId: widget.teacher.teacherId,
    );
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _scoreController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final studentId = _studentIdController.text.trim().toUpperCase();
    final score = double.tryParse(_scoreController.text.trim());
    final reason = _reasonController.text.trim();

    if (studentId.isEmpty || score == null || score == 0 || reason.isEmpty) {
      _showMessage('กรุณากรอกรหัสนักเรียน คะแนนที่ไม่เป็นศูนย์ และเหตุผล', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await ApiService.saveConductScore(
        studentId: studentId,
        teacherId: widget.teacher.teacherId,
        scoreChange: score,
        reason: reason,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        _studentIdController.clear();
        _reasonController.clear();
        setState(_loadHistory);
        _showMessage('บันทึกคะแนนพฤติกรรมสำเร็จ');
      } else {
        _showMessage(result['message'] ?? 'บันทึกไม่สำเร็จ', error: true);
      }
    } catch (e) {
      if (mounted) _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.prompt()),
      backgroundColor: error ? AppColors.danger : AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('คะแนนพฤติกรรม', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(_loadHistory),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFormCard(),
            const SizedBox(height: 20),
            Text('ประวัติการบันทึกคะแนน', style: GoogleFonts.prompt(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('บันทึกคะแนนนักเรียน', style: GoogleFonts.prompt(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            TextField(
              controller: _studentIdController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'รหัสนักเรียน', prefixIcon: Icon(Icons.badge_outlined)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _scoreController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: const InputDecoration(labelText: 'คะแนน (+ เพิ่ม / - ลด)', prefixIcon: Icon(Icons.score_outlined)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'เหตุผล *', prefixIcon: Icon(Icons.notes_outlined)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined),
                label: Text(_saving ? 'กำลังบันทึก...' : 'บันทึกคะแนน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory() {
    return FutureBuilder<List<ConductRecord>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Text('โหลดประวัติไม่สำเร็จ: ${snapshot.error}', style: GoogleFonts.prompt(color: AppColors.danger));
        }
        final history = snapshot.data ?? [];
        if (history.isEmpty) {
          return Text('ยังไม่มีประวัติการบันทึก', style: GoogleFonts.prompt(color: AppColors.textMuted));
        }
        return Column(
          children: history.map((item) {
            final positive = item.pointsChange >= 0;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: (positive ? AppColors.success : AppColors.danger).withValues(alpha: 0.12),
                  child: Icon(positive ? Icons.add : Icons.remove, color: positive ? AppColors.success : AppColors.danger),
                ),
                title: Text('${item.pointsChange >= 0 ? '+' : ''}${item.pointsChange} คะแนน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
                subtitle: Text('${item.title}\n${item.studentId ?? ''}', style: GoogleFonts.prompt(fontSize: 12)),
                isThreeLine: true,
                trailing: Text(item.date, style: GoogleFonts.prompt(fontSize: 11, color: AppColors.textMuted)),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
