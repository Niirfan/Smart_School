import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _studentIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isTeacher = false;
  bool _loading = false;
  String? _errorMsg;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _studentIdCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final result = await ApiService.register(
        studentId: _studentIdCtrl.text.trim().toUpperCase(),
        password: _passwordCtrl.text,
        accountType: _isTeacher ? 'teacher' : 'student',
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMsg = result['message'] ?? 'ไม่สามารถสมัครสมาชิกได้';
        });
      }
    } catch (e) {
      setState(() {
        final errStr = e.toString().replaceFirst('Exception: ', '');
        _errorMsg = errStr.contains('SocketException') || errStr.contains('Timeout')
            ? 'ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้ กรุณาตรวจสอบอินเทอร์เน็ต'
            : errStr;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  color: Color(0xFF16A34A), size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'ลงทะเบียนสำเร็จ!',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'บัญชีของคุณพร้อมใช้งานแล้ว\nสามารถเข้าสู่ระบบได้เลย',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 20),
        actions: [
          SizedBox(
            width: 200,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // back to login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryNavy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('เข้าสู่ระบบ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2C59),
      body: Stack(
        children: [
          // Background decoration circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1D58D8).withValues(alpha: 0.2),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'ลงทะเบียน',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          children: [
                            // Icon + Title
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.5),
                              ),
                              child: const Icon(Icons.person_add_rounded,
                                  color: Colors.white, size: 36),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'สร้างบัญชีใหม่',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'กรอกข้อมูลเพื่อลงทะเบียน',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Form card
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── รหัสนักเรียน ──────────────
                                    SegmentedButton<bool>(
                                      segments: const [
                                        ButtonSegment(value: false, label: Text('นักเรียน'), icon: Icon(Icons.school_outlined)),
                                        ButtonSegment(value: true, label: Text('ครู'), icon: Icon(Icons.person_outline)),
                                      ],
                                      selected: {_isTeacher},
                                      onSelectionChanged: (value) => setState(() => _isTeacher = value.first),
                                      showSelectedIcon: false,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildLabel(_isTeacher ? 'รหัสครู' : 'รหัสนักเรียน'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _studentIdCtrl,
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      decoration: _inputDecoration(
                                        hint: _isTeacher ? 'เช่น T001' : 'เช่น S001',
                                        icon: Icons.badge_outlined,
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'กรุณากรอกรหัสประจำตัว'
                                              : null,
                                    ),
                                    const SizedBox(height: 20),

                                    // ── รหัสผ่าน ──────────────────
                                    _buildLabel('รหัสผ่าน'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordCtrl,
                                      obscureText: _obscurePass,
                                      decoration: _inputDecoration(
                                        hint: 'ตั้งรหัสผ่าน (อย่างน้อย 6 ตัว)',
                                        icon: Icons.lock_outline_rounded,
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePass
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscurePass = !_obscurePass),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'กรุณากรอกรหัสผ่าน';
                                        }
                                        if (v.length < 6) {
                                          return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // ── ยืนยันรหัสผ่าน ───────────
                                    _buildLabel('ยืนยันรหัสผ่าน'),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _confirmCtrl,
                                      obscureText: _obscureConfirm,
                                      decoration: _inputDecoration(
                                        hint: 'กรอกรหัสผ่านอีกครั้ง',
                                        icon: Icons.lock_outline_rounded,
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirm
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: AppColors.textSecondary,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() =>
                                              _obscureConfirm =
                                                  !_obscureConfirm),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'กรุณายืนยันรหัสผ่าน';
                                        }
                                        if (v != _passwordCtrl.text) {
                                          return 'รหัสผ่านไม่ตรงกัน';
                                        }
                                        return null;
                                      },
                                    ),

                                    // Error banner
                                    if (_errorMsg != null) ...[
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF1F2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                              color: const Color(0xFFFECDD3)),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.error_outline,
                                                color: Color(0xFFE11D48),
                                                size: 18),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMsg!,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFFBE123C),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    const SizedBox(height: 28),

                                    // Submit button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: ElevatedButton(
                                        onPressed: _loading ? null : _register,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.primaryNavy,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          disabledBackgroundColor: AppColors
                                              .primaryNavy
                                              .withValues(alpha: 0.6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: _loading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'ลงทะเบียน',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Back to login link
                                    Center(
                                      child: TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: RichText(
                                          text: TextSpan(
                                            style: const TextStyle(
                                                fontSize: 13),
                                            children: [
                                              TextSpan(
                                                text: 'มีบัญชีอยู่แล้ว? ',
                                                style: TextStyle(
                                                    color: AppColors
                                                        .textSecondary),
                                              ),
                                              const TextSpan(
                                                text: 'เข้าสู่ระบบ',
                                                style: TextStyle(
                                                  color: AppColors.primaryBlue,
                                                  fontWeight: FontWeight.bold,
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(
      {required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}
