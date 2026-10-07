import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/teacher_model.dart';
import '../../services/auth_session.dart';
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
  Future<void> _callPhone(String? phone) async {
    final number = (phone ?? '').replaceAll(RegExp(r'[^0-9+]'), '');
    if (number.isEmpty) return;
    await launchUrl(
      Uri(scheme: 'tel', path: number),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('ข้อมูลผู้สอน', style: GoogleFonts.prompt(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Teacher Profile Card
            _buildProfileCard(),

            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await AuthSession.clear();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
            _buildProfileDetailRow(Icons.phone, 'เบอร์โทรศัพท์', widget.teacher.phoneNumber ?? '-', isPhone: true),
            const SizedBox(height: 8),
            _buildProfileDetailRow(Icons.home, 'ที่อยู่', widget.teacher.address ?? '-'),
            const SizedBox(height: 8),
            _buildProfileDetailRow(Icons.bloodtype, 'หมู่เลือด', widget.teacher.bloodGroup ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value, {bool isPhone = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.prompt(fontSize: 11, color: AppColors.textSecondary)),
              Text(
                value,
                style: GoogleFonts.prompt(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                maxLines: isPhone ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isPhone && value.trim().isNotEmpty && value != '-')
          IconButton(
            tooltip: 'โทรออก',
            onPressed: () => _callPhone(value),
            icon: const Icon(Icons.call, color: AppColors.primaryBlue),
          ),
      ],
    );
  }
}
