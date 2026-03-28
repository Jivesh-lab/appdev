import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// API Service for ClassPulse backend communication
class ApiService {
  static const String baseUrl = 'http://localhost:8000/api'; 
  
  // Store active sessions (for demo - replace with database)
  final Set<String> _activeSessions = {};
  
  // Generate unique 4-digit session code
  String _generateSessionCode() {
    String code;
    do {
      code = (1000 + Random().nextInt(9000)).toString();
    } while (_activeSessions.contains(code));
    _activeSessions.add(code);
    return code;
  }
  
  // Generate join link for session code - uses current app URL for web, production URL for deployment
  String _generateJoinLink(String sessionCode) {
    if (kIsWeb) {
      // On web, use the current document's URL (e.g., http://localhost:52345/)
      // This ensures the link opens in the same browser instance
      try {
        // Get the current origin (protocol + host)
        final uri = Uri.base;
        final baseUrl = '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
        return '$baseUrl?code=$sessionCode';
      } catch (e) {
        // Fallback if web URL parsing fails
        return 'http://localhost:54330?code=$sessionCode';
      }
    } else {
      // For non-web (mobile/desktop), use production domain
      return 'https://classpulse.app?code=$sessionCode';
    }
  }
  
  /// Start a new session - generates code, link, and returns session object
  Future<Session> startSession(String classCode, String className, String teacherName, String teacherId) async {
    try {
      final sessionCode = _generateSessionCode();
      final joinLink = _generateJoinLink(sessionCode);
      
      print('🚀 Creating session: $sessionCode');
      print('📊 Sending data: classCode=$classCode, className=$className, teacherId=$teacherId');
      
      // Call backend to create session
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'classCode': classCode,
          'className': className,
          'teacherId': teacherId,
          'sessionCode': sessionCode,
          'joinLink': joinLink,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}');
      print('📨 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        print('✅ Session created successfully: $sessionCode');
        return Session(
          id: responseData['session']['id'],
          classCode: classCode,
          className: className,
          teacherName: teacherName,
          sessionCode: sessionCode,
          joinLink: joinLink,
          startTime: DateTime.now(),
          studentCount: 0,
          isActive: true,
          topic: 'Live Session',
          isLobbyPhase: true,
        );
      } else {
        print('❌ Backend error (${response.statusCode}): ${response.body}');
        throw Exception('Failed to create session: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error starting session: $e');
      rethrow;
    }
  }
  
  /// End session and clean up
  Future<void> endSession(String sessionCode) async {
    try {
      _activeSessions.remove(sessionCode);
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      print('Error ending session: $e');
    }
  }
  
  /// Get session by code (for joining)
  Future<Session?> getSessionByCode(String sessionCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sessions/$sessionCode'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final sessionData = responseData['session'];
        print('📊 Session status - Code: $sessionCode, Students: ${sessionData['studentCount']}');
        
        // Handle isActive as either boolean or integer (SQLite returns 0/1)
        bool isActive = true;
        if (sessionData['isActive'] is int) {
          isActive = sessionData['isActive'] == 1;
        } else if (sessionData['isActive'] is bool) {
          isActive = sessionData['isActive'];
        }
        
        return Session(
          id: sessionData['id'],
          classCode: 'DEFAULT',
          className: sessionData['className'],
          teacherName: 'Teacher',
          sessionCode: sessionCode,
          joinLink: sessionData['joinLink'],
          startTime: DateTime.now(),
          studentCount: sessionData['studentCount'] ?? 0,
          isActive: isActive,
          topic: 'Live Session',
          isLobbyPhase: true,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error getting session: $e');
      return null;
    }
  }
  
  /// Student joins a session
  Future<int?> joinSessionAsStudent(String sessionCode, {String? studentName, String? studentEmail}) async {
    try {
      print('🚀 Attempting to join session: $sessionCode');
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/$sessionCode/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'studentName': studentName ?? 'Anonymous',
          'studentEmail': studentEmail,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Join response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final studentCount = responseData['studentCount'];
        print('✅ Student joined! Count: $studentCount');
        return studentCount;
      } else {
        print('❌ Join failed: ${response.body}');
      }
      return null;
    } catch (e) {
      print('❌ Error joining session: $e');
      return null;
    }
  }
  
  // Simulate API responses with delays (replace with real HTTP calls)
  
  /// Join Class - Send class code and get session details
  Future<Session?> joinClass(String classCode) async {
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      // Mock response - replace with real HTTP request
      if (classCode.isNotEmpty && classCode.length == 6) {
        return Session(
          id: 'session_${classCode}_1',
          classCode: classCode,
          className: 'Advanced Physics',
          teacherName: 'Dr. Smith',
          sessionCode: '4821', // Mock code
          joinLink: _generateJoinLink('4821'),
          startTime: DateTime.now(),
          studentCount: 28,
          isActive: true,
          topic: 'Quantum Mechanics Basics',
          isLobbyPhase: false,
        );
      }
      return null;
    } catch (e) {
      print('Error joining class: $e');
      return null;
    }
  }
  
  /// Get class sessions/history
  Future<List<ClassModel>> getClasses() async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock data - replace with real API call
      return [
        ClassModel(
          id: '1',
          classCode: 'PHY101',
          className: 'Physics 101',
          subject: 'Physics',
          teacherName: 'Dr. Smith',
          scheduleTime: 'Mon & Wed 10:00 AM',
          enrolledStudents: 45,
          isLive: true,
        ),
        ClassModel(
          id: '2',
          classCode: 'MATH201',
          className: 'Calculus II',
          subject: 'Mathematics',
          teacherName: 'Prof. Johnson',
          scheduleTime: 'Tue & Thu 2:00 PM',
          enrolledStudents: 38,
          isLive: false,
        ),
      ];
    } catch (e) {
      print('Error fetching classes: $e');
      return [];
    }
  }
  
  /// Submit feedback during session
  Future<bool> submitFeedback(
    String sessionId,
    String studentId,
    String feedbackType,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock submission - replace with real API call
      print('Feedback submitted: $feedbackType for session $sessionId');
      return true;
    } catch (e) {
      print('Error submitting feedback: $e');
      return false;
    }
  }
  
  /// Ask a question during session
  Future<Question?> askQuestion(
    String sessionId,
    String studentId,
    String studentName,
    String title,
    String description,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock question creation - replace with real API call
      return Question(
        id: 'q_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        studentId: studentId,
        studentName: studentName,
        title: title,
        description: description,
        timestamp: DateTime.now(),
        isAnswered: false,
      );
    } catch (e) {
      print('Error asking question: $e');
      return null;
    }
  }
  
  /// Get live session details
  Future<Session?> getSessionDetails(String classCode) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      // Mock response
      final code = _activeSessions.isNotEmpty ? _activeSessions.first : 'XXXX';
      return Session(
        id: 'session_${code}_1',
        classCode: classCode,
        className: 'Advanced Physics',
        teacherName: 'Dr. Smith',
        sessionCode: code,
        joinLink: _generateJoinLink(code),
        startTime: DateTime.now(),
        studentCount: 28,
        isActive: true,
        topic: 'Quantum Mechanics',
        isLobbyPhase: false,
      );
    } catch (e) {
      print('Error fetching session details: $e');
      return null;
    }
  }
  
  /// Authenticate user with email and password
  Future<User?> authenticateUser(
    String email,
    String password, {
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final userData = jsonResponse['user'];
          return User(
            id: userData['id'].toString(),
            name: userData['name'],
            email: userData['email'],
            role: userData['role'],
          );
        }
      }
      return null;
    } catch (e) {
      print('Error authenticating user: $e');
      return null;
    }
  }
  
  /// Register new user
  Future<User?> registerUser(
    String name,
    String email,
    String password, {
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          final userData = jsonResponse['user'];
          return User(
            id: userData['id'].toString(),
            name: userData['name'],
            email: userData['email'],
            role: userData['role'],
          );
        }
      } else if (response.statusCode == 400) {
        final jsonResponse = jsonDecode(response.body);
        print('Registration error: ${jsonResponse['message']}');
      }
      return null;
    } catch (e) {
      print('Error registering user: $e');
      return null;
    }
  }
}

/// Singleton instance
final apiService = ApiService();
