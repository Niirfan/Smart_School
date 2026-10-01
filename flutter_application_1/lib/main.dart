import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/teacher_model.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/teacher/teacher_navigation.dart';
import 'services/auth_session.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th', null);
  runApp(const SmartSchoolApp());
}

class SmartSchoolApp extends StatelessWidget {
  const SmartSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartSchool TH',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _SessionGate(),
    );
  }
}

class _SessionGate extends StatefulWidget {
  const _SessionGate();

  @override
  State<_SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<_SessionGate> {
  late final Future<Widget> _initialScreen = _restoreSession();

  Future<Widget> _restoreSession() async {
    try {
      final session = await AuthSession.read();
      if (session != null && await AuthSession.biometricEnabled) {
        final authenticated = await AuthSession.authenticateBiometric();
        if (!authenticated) return const LoginScreen();
      }
      if (session?['role'] == 'student') {
        return MainNavigationScreen(studentId: session!['student_id'] as String);
      }
      if (session?['role'] == 'teacher') {
        final teacherData = Map<String, dynamic>.from(session!['teacher'] as Map);
        return TeacherNavigation(teacher: TeacherModel.fromJson(teacherData));
      }
    } catch (_) {
      await AuthSession.clear();
    }
    return const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialScreen,
      builder: (context, snapshot) {
        if (snapshot.hasData) return snapshot.data!;
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}
