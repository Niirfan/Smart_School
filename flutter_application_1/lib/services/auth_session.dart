import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

import '../models/teacher_model.dart';

class AuthSession {
  static const _roleKey = 'auth_role';
  static const _studentIdKey = 'auth_student_id';
  static const _teacherKey = 'auth_teacher';
  static const _biometricKey = 'auth_biometric_enabled';

  static final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static Future<bool> get biometricEnabled async =>
      await _preferences.getBool(_biometricKey) ?? false;

  static Future<bool> get canUseBiometrics async {
    try {
      return await _localAuth.isDeviceSupported() &&
          (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateBiometric() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'ยืนยันตัวตนเพื่อเข้าใช้งาน SmartSchool',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  static Future<void> setBiometricEnabled(bool enabled) =>
      _preferences.setBool(_biometricKey, enabled);

  static Future<void> saveStudent(String studentId) async {
    await _preferences.setString(_roleKey, 'student');
    await _preferences.setString(_studentIdKey, studentId);
    await _preferences.remove(_teacherKey);
    await _preferences.remove(_biometricKey);
  }

  static Future<void> saveTeacher(TeacherModel teacher) async {
    await _preferences.setString(_roleKey, 'teacher');
    await _preferences.setString(_teacherKey, jsonEncode(teacher.toJson()));
    await _preferences.remove(_studentIdKey);
    await _preferences.remove(_biometricKey);
  }

  static Future<Map<String, dynamic>?> read() async {
    final role = await _preferences.getString(_roleKey);
    if (role == 'student') {
      final studentId = await _preferences.getString(_studentIdKey);
      if (studentId == null || studentId.isEmpty) return null;
      return {'role': role, 'student_id': studentId};
    }

    if (role == 'teacher') {
      final teacherJson = await _preferences.getString(_teacherKey);
      if (teacherJson == null || teacherJson.isEmpty) return null;
      final teacher = jsonDecode(teacherJson);
      if (teacher is! Map<String, dynamic>) return null;
      return {'role': role, 'teacher': teacher};
    }

    return null;
  }

  static Future<void> clear() async {
    await _preferences.remove(_roleKey);
    await _preferences.remove(_studentIdKey);
    await _preferences.remove(_teacherKey);
    await _preferences.remove(_biometricKey);
  }
}
