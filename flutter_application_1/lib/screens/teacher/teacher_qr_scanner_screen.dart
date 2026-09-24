import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/teacher_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class TeacherQrScannerScreen extends StatefulWidget {
  final TeacherModel teacher;

  const TeacherQrScannerScreen({
    super.key,
    required this.teacher,
  });

  @override
  State<TeacherQrScannerScreen> createState() => _TeacherQrScannerScreenState();
}

class _TeacherQrScannerScreenState extends State<TeacherQrScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  final TextEditingController _manualIdController = TextEditingController();

  String _scanType = 'in'; // 'in' หรือ 'out'
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    _manualIdController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        _handleStudentScan(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _handleStudentScan(String rawCode) async {
    String studentId = rawCode.trim();
    if (studentId.contains('S') || studentId.contains('s')) {
      final match = RegExp(r'S\d+').firstMatch(studentId);
      if (match != null) {
        studentId = match.group(0)!;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    final now = DateTime.now();
    final clientCurrentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    try {
      final res = await ApiService.saveQrAttendance(
        studentId: studentId,
        teacherId: widget.teacher.teacherId,
        scanType: _scanType,
        status: 'มาเรียน',
        time: clientCurrentTime,
      );

      _manualIdController.clear();

      if (mounted) {
        _showScanResultDialog(res, studentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เกิดข้อผิดพลาดในการบันทึก: $e',
              style: GoogleFonts.prompt(),
            ),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showScanResultDialog(Map<String, dynamic> res, String studentId) {
    final isSuccess = res['success'] == true;
    final message = res['message'] ?? (isSuccess ? 'บันทึกสำเร็จ' : 'เกิดข้อผิดพลาด');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSuccess ? AppColors.successBg : AppColors.dangerBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.error,
                  color: isSuccess ? AppColors.success : AppColors.danger,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isSuccess ? 'สแกนสำเร็จ!' : 'สแกนไม่สำเร็จ',
                style: GoogleFonts.prompt(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'รหัสนักเรียน: $studentId',
                style: GoogleFonts.prompt(
                  fontSize: 16,
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: GoogleFonts.prompt(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSuccess ? AppColors.primaryBlue : AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'สแกนต่อ',
                    style: GoogleFonts.prompt(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('สแกน QR Code เช็กชื่อ', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.amber),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Mode selector (Check-In / Check-Out)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _scanType = 'in'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _scanType == 'in' ? AppColors.primaryNavy : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.login,
                              size: 18,
                              color: _scanType == 'in' ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'เช็กชื่อเข้าโรงเรียน',
                              style: GoogleFonts.prompt(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _scanType == 'in' ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _scanType = 'out'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _scanType == 'out' ? AppColors.warning : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout,
                              size: 18,
                              color: _scanType == 'out' ? Colors.white : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'เช็กชื่อออกโรงเรียน',
                              style: GoogleFonts.prompt(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: _scanType == 'out' ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Camera View
            Container(
              height: 280,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _scannerController,
                    onDetect: _onDetect,
                  ),
                  // Overlay frame
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primaryBlue, width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  if (_isProcessing)
                    Container(
                      color: Colors.black45,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Manual Input Section (กรณีสแกนบัตรไม่ได้ หรือกล้องมีปัญหา)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.edit_note, size: 20, color: AppColors.primaryNavy),
                          const SizedBox(width: 8),
                          Text(
                            'กรอกรหัสนักเรียนแทน (กรณีสแกนบัตรไม่ได้)',
                            style: GoogleFonts.prompt(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '⏱️ บันทึกตามเวลาที่กดทันที (สายเกิน 08:00 น. ตัดนาทีละ 0.1 คะแนนอัตโนมัติ)',
                        style: GoogleFonts.prompt(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _manualIdController,
                        decoration: InputDecoration(
                          labelText: 'รหัสนักเรียน',
                          labelStyle: GoogleFonts.prompt(fontSize: 13),
                          hintText: 'เช่น S001 หรือ 6620310131',
                          hintStyle: GoogleFonts.prompt(color: AppColors.textMuted, fontSize: 13),
                          prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.primaryBlue),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onSubmitted: (value) {
                          final text = value.trim();
                          if (text.isNotEmpty && !_isProcessing) {
                            _handleStudentScan(text);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  final text = _manualIdController.text.trim();
                                  if (text.isNotEmpty) {
                                    _handleStudentScan(text);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryNavy,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.send, size: 16, color: Colors.white),
                          label: Text(
                            'บันทึกเช็กชื่อ',
                            style: GoogleFonts.prompt(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
