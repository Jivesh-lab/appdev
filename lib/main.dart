import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'student/student_screens.dart';
import 'student/localization.dart';
import 'teacher/teacher_screens.dart';
import 'auth/auth_screens.dart';
import 'models/models.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _theme = 'light';
  User? _currentUser;
  String? _userRole; // 'student' or 'teacher'

  void _updateTheme(String theme) {
    setState(() {
      _theme = theme;
    });
  }

  void _handleLogin(User user, String role) {
    setState(() {
      _currentUser = user;
      _userRole = role;
    });
  }

  void _handleLogout() {
    setState(() {
      _currentUser = null;
      _userRole = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine brightness based on theme setting
    Brightness brightness = _theme == 'dark' 
        ? Brightness.dark 
        : _theme == 'system'
            ? MediaQuery.of(context).platformBrightness
            : Brightness.light;

    return MaterialApp(
      title: 'ClassPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5BFF),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F7FE),
        fontFamily: 'Poppins',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5BFF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        fontFamily: 'Poppins',
      ),
      themeMode: brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: _currentUser == null
          ? AuthScreen(onLoginSuccess: _handleLogin)
          : appRouter(context, _currentUser!, _userRole!),
    );
  }
}

/// Platform-aware router
Widget appRouter(BuildContext context, User user, String userRole) {
  // Show teacher dashboard for teachers on all platforms (web & mobile)
  return ClassPulseApp(
    onThemeChanged: (_) {},
    currentTheme: 'light',
    currentUser: user,
    isTeacher: userRole == 'teacher',
  );
}

class ClassPulseApp extends StatefulWidget {
  final Function(String) onThemeChanged;
  final String currentTheme;
  final bool isTeacher;
  final User? currentUser;
  final VoidCallback? onLogoutRequest;

  const ClassPulseApp({
    super.key,
    required this.onThemeChanged,
    required this.currentTheme,
    this.isTeacher = false,
    this.currentUser,
    this.onLogoutRequest,
  });

  @override
  State<ClassPulseApp> createState() => _ClassPulseAppState();
}

class _ClassPulseAppState extends State<ClassPulseApp> {
  // Student Mode State
  bool _hasJoined = false;
  bool _isSignedUp = false;
  String _classCode = '';
  int _selectedIndex = 0;
  bool _notificationsEnabled = true;
  String _language = 'English (US)';
  bool _twoFactorEnabled = false;
  double _storageUsed = 2.5; // GB

  // Teacher Mode State
  ClassModel? _selectedClass;

  void _joinClass(String code) {
    setState(() {
      _hasJoined = true;
      _classCode = code;
      _selectedIndex = 0;
    });
  }

  void _leaveSession() {
    setState(() {
      _hasJoined = false;
      _classCode = '';
      _selectedIndex = 0;
    });
  }

  void _toggleNotifications(bool value) {
    setState(() {
      _notificationsEnabled = value;
    });
  }

  void _toggleTwoFactor(bool value) {
    setState(() {
      _twoFactorEnabled = value;
    });
  }

  void _updateLanguage(String lang) {
    setState(() {
      _language = lang;
    });
  }

  void _clearStorage() {
    setState(() {
      _storageUsed = 0.5;
    });
  }

<<<<<<< HEAD
  void _completeSignup() {
    setState(() {
      _isSignedUp = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSignedUp) {
      return StudentSignupScreen(
        onSignupSuccess: _completeSignup,
        onNavigateToLogin: _completeSignup, // For now, login just skips signup
      );
    }

=======
  void _selectTeacherClass(ClassModel classModel) {
    setState(() {
      _selectedClass = classModel;
    });
  }

  void _closeTeacherSession() {
    setState(() {
      _selectedClass = null;
    });
  }

  void _handleLogout() {
    // Navigate up to MyApp and call logout there
    Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    // Teacher Mobile UI
    if (widget.isTeacher) {
      if (_selectedClass != null) {
        return TeacherLiveSession(
          classModel: _selectedClass!,
          language: _language,
        );
      }
      return TeacherDashboard(
        language: _language,
        onClassSelected: _selectTeacherClass,
        teacherId: widget.currentUser?.id.toString(),
        teacherName: widget.currentUser?.name,
      );
    }

    // Student Web/Mobile UI
>>>>>>> a7e0543 (added teacher module, services, models and fixes)
    if (!_hasJoined) {
      return JoinClassScreen(onJoin: _joinClass, language: _language);
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          LiveSessionScreen(classCode: _classCode, onLeave: _leaveSession, language: _language),
          StudentProfileScreen(onBack: () => setState(() => _selectedIndex = 0), language: _language),
          AskQuestionScreen(language: _language),
          SettingsScreen(
            onBack: () => setState(() => _selectedIndex = 0),
            theme: widget.currentTheme,
            onThemeChanged: widget.onThemeChanged,
            onLogout: _leaveSession,
            notificationsEnabled: _notificationsEnabled,
            onNotificationsChanged: _toggleNotifications,
            language: _language,
            onLanguageChanged: _updateLanguage,
            twoFactorEnabled: _twoFactorEnabled,
            onTwoFactorChanged: _toggleTwoFactor,
            storageUsed: _storageUsed,
            onClearStorage: _clearStorage,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        elevation: 10,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppStrings.get(_language, 'session'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppStrings.get(_language, 'profile'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.edit_note),
            label: AppStrings.get(_language, 'ask'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            label: AppStrings.get(_language, 'settings'),
          ),
        ],
        selectedItemColor: const Color(0xFF2D5BFF),
        unselectedItemColor: const Color(0xFFBDBDBD),
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }
}

// ==================== JOIN CLASS SCREEN ====================

