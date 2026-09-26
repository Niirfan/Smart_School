import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/teacher_model.dart';
import '../../models/conduct_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class TeacherProfileScreen extends StatefulWidget {
  final TeacherModel teacher;

  const TeacherProfileScreen({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _scoreInputController = TextEditingController(text: '-5');
  final TextEditingController _reasonController = TextEditingController();
  num _scoreChange = -5; // default หัก 5 คะแนน
  bool _isSavingConduct = false;

  List<ConductRecord> _conductHistory = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _fetchConductHistory();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _scoreInputController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _fetchConductHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final list = await ApiService.getTeacherConductHistory(teacherId: widget.teacher.teacherId);
      setState(() {
        _conductHistory = list;
      });
    } catch (e) {
      // SILENT or fallback if empty
    } finally {
      setState(() {
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _saveConduct() async {
    final studentId = _studentIdController.text.trim();
    final reason = _reasonController.text.trim();
    final inputScoreText = _scoreInputController.text.trim();
    final parsedScore = num.tryParse(inputScoreText) ?? _scoreChange;

    if (studentId.isEmpty || reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณากรอกรหัสนักเรียนและสาเหตุที่บันทึก', style: GoogleFonts.prompt()),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSavingConduct = true;
    });

    try {
      final res = await ApiService.saveConductScore(
        studentId: studentId,
        teacherId: widget.teacher.teacherId,
        scoreChange: parsedScore,
        reason: reason,
      );

      if (mounted) {
        final success = res['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ?? (success ? 'บันทึกคะแนนความประพฤติสำเร็จ' : 'เกิดข้อผิดพลาด'),
              style: GoogleFonts.prompt(),
            ),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
        );

        if (success) {
          _studentIdController.clear();
          _reasonController.clear();
          _fetchConductHistory();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e', style: GoogleFonts.prompt()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      setState(() {
        _isSavingConduct = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ข้อมูลผู้สอน & ความประพฤติ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teacher Profile Card
            _buildProfileCard(),

            const SizedBox(height: 20),

            // Conduct Recording Form (ฝ่ายปกครอง)
            const SizedBox(height: 30),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout),
                label: Text('ออกจากระบบ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryNavy,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              widget.teacher.name,
              style: GoogleFonts.prompt(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'รหัสครู: ${widget.teacher.teacherId}',
              style: GoogleFonts.prompt(
                fontSize: 13,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildProfileDetailRow(Icons.domain, 'กลุ่มสาระการเรียนรู้', widget.teacher.department ?? 'ทั่วไป'),
            const SizedBox(height: 8),
            _buildProfileDetailRow(Icons.phone, 'เบอร์โทรศัพท์', widget.teacher.phoneNumber ?? '-'),
            const SizedBox(height: 8),
            _buildProfileDetailRow(Icons.home, 'ที่อยู่', widget.teacher.address ?? '-'),
            const SizedBox(height: 8),
            _buildProfileDetailRow(Icons.bloodtype, 'หมู่เลือด', widget.teacher.bloodGroup ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: GoogleFonts.prompt(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

Widget _buildConductForm() {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel, color: AppColors.danger, size: 20),
              const SizedBox(width: 8),
              Text(
                'บันทึกคะแนนความประพฤตินักเรียน',
                style: GoogleFonts.prompt(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ถ้าไม่ใช่ฝ่ายปกครอง -> โชว์แค่ข้อความแจ้งเตือน แล้วจบ ไม่แสดงฟอร์มเลย
          if (!widget.teacher.isDisciplinary)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'เฉพาะครูฝ่ายปกครองเท่านั้นที่สามารถปรับเปลี่ยนคะแนนความประพฤติได้',
                      style: GoogleFonts.prompt(fontSize: 11, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // ฟอร์มทั้งหมดจะแสดงเฉพาะฝ่ายปกครองเท่านั้น
            TextField(
              controller: _studentIdController,
              decoration: InputDecoration(
                labelText: 'รหัสนักเรียน (เช่น S001)',
                labelStyle: GoogleFonts.prompt(fontSize: 13),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            Text('ระบุการปรับคะแนน (บวก/ลบ ทศนิยมได้ตามต้องการ):',
                style: GoogleFonts.prompt(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _scoreInputController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(
                hintText: 'เช่น -0.1, -1.5, -3, +10',
                hintStyle: GoogleFonts.prompt(fontSize: 13, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) {
                final parsed = num.tryParse(val);
                if (parsed != null) {
                  setState(() => _scoreChange = parsed);
                }
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildScoreChip(-0.1, '-0.1', AppColors.danger),
                _buildScoreChip(-1.5, '-1.5', AppColors.danger),
                _buildScoreChip(-3, '-3', AppColors.danger),
                _buildScoreChip(-5, '-5', AppColors.danger),
                _buildScoreChip(-10, '-10', AppColors.danger),
                _buildScoreChip(3, '+3', AppColors.success),
                _buildScoreChip(5, '+5', AppColors.success),
                _buildScoreChip(10, '+10', AppColors.success),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'สาเหตุ / รายละเอียด (เช่น แต่งกายผิดระเบียบ)',
                labelStyle: GoogleFonts.prompt(fontSize: 13),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isSavingConduct ? null : _saveConduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isSavingConduct
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send, color: Colors.white, size: 18),
                label: Text(
                  _isSavingConduct ? 'กำลังบันทึก...' : 'บันทึกคะแนนความประพฤติ',
                  style: GoogleFonts.prompt(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
  Widget _buildScoreChip(num value, String label, Color color) {
    final isSelected = _scoreChange == value;
    return ChoiceChip(
      label: Text(label, style: GoogleFonts.prompt(fontSize: 12, color: isSelected ? Colors.white : color)),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
      showCheckmark: false,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _scoreChange = value;
            _scoreInputController.text = value.toString();
          });
        }
      },
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ประวัติการบันทึกความประพฤติล่าสุด',
          style: GoogleFonts.prompt(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (_isLoadingHistory)
          const Center(child: CircularProgressIndicator())
        else if (_conductHistory.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('ยังไม่มีรายการบันทึกประวัติความประพฤติ', style: GoogleFonts.prompt(color: AppColors.textMuted)),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _conductHistory.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = _conductHistory[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.scoreChange < 0 ? AppColors.dangerBg : AppColors.successBg,
                    child: Icon(
                      item.scoreChange < 0 ? Icons.remove : Icons.add,
                      color: item.scoreChange < 0 ? AppColors.danger : AppColors.success,
                    ),
                  ),
                  title: Text(item.reason, style: GoogleFonts.prompt(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('วันที่: ${item.date}', style: GoogleFonts.prompt(fontSize: 11, color: AppColors.textMuted)),
                  trailing: Text(
                    '${item.scoreChange > 0 ? "+" : ""}${item.scoreChange}',
                    style: GoogleFonts.prompt(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: item.scoreChange < 0 ? AppColors.danger : AppColors.success,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
