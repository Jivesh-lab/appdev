import 'package:flutter/material.dart';
import 'student/student_screens.dart';
import 'student/student_signup_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClassPulse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2D5BFF),
          brightness: Brightness.light,
        ),
        fontFamily: 'Poppins',
      ),
      home: const ClassPulseApp(),
    );
  }
}

class ClassPulseApp extends StatefulWidget {
  const ClassPulseApp({super.key});

  @override
  State<ClassPulseApp> createState() => _ClassPulseAppState();
}

class _ClassPulseAppState extends State<ClassPulseApp> {
  bool _hasJoined = false;
  bool _isSignedUp = false;
  String _classCode = '';
  int _selectedIndex = 0;
  String _theme = 'light';
  bool _notificationsEnabled = true;
  String _language = 'English (US)';
  bool _twoFactorEnabled = false;
  double _storageUsed = 2.5; // GB

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

  void _updateTheme(String theme) {
    setState(() {
      _theme = theme;
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

    if (!_hasJoined) {
      return JoinClassScreen(onJoin: _joinClass);
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          LiveSessionScreen(classCode: _classCode, onLeave: _leaveSession),
          StudentProfileScreen(onBack: () => setState(() => _selectedIndex = 0)),
          AskQuestionScreen(),
          SettingsScreen(
            onBack: () => setState(() => _selectedIndex = 0),
            theme: _theme,
            onThemeChanged: _updateTheme,
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Session',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: 'Ask',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
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

