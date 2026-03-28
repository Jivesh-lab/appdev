import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  ApiService._internal();

  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  static const _tokenStorageKey = 'classpulse_jwt';
  static const _requestTimeout = Duration(seconds: 12);

  SharedPreferences? _prefs;
  String? _jwtToken;
  String? _studentToken;
  String? _currentSessionCode;

  String? get jwtToken => _jwtToken;
  String? get studentToken => _studentToken;
  String? get currentSessionCode => _currentSessionCode;

  String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api'
        : 'http://localhost:3000/api';
  }

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    _jwtToken = _prefs?.getString(_tokenStorageKey);
  }

  Future<void> setJwtToken(String token) async {
    _jwtToken = token;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_tokenStorageKey, token);
  }

  Future<void> clearJwtToken() async {
    _jwtToken = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_tokenStorageKey);
  }

  void setStudentToken(String token, String sessionCode) {
    _studentToken = token;
    _currentSessionCode = sessionCode;
  }

  void clearStudentToken() {
    _studentToken = null;
    _currentSessionCode = null;
  }

  Map<String, String> _headers({bool authRequired = false}) {
    return {
      'Content-Type': 'application/json',
      if (authRequired && _jwtToken != null) 'Authorization': 'Bearer $_jwtToken',
    };
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    http.Response response;

    try {
      switch (method) {
        case 'GET':
          response = await http
              .get(uri, headers: _headers(authRequired: authRequired))
              .timeout(_requestTimeout);
          break;
        case 'POST':
          response = await http
              .post(
                uri,
                headers: _headers(authRequired: authRequired),
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_requestTimeout);
          break;
        case 'PATCH':
          response = await http
              .patch(
                uri,
                headers: _headers(authRequired: authRequired),
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_requestTimeout);
          break;
        default:
          throw const ApiException('Unsupported request method');
      }
    } on TimeoutException {
      throw const ApiException('The request timed out. Please try again.');
    } catch (_) {
      throw const ApiException(
        'Could not reach the ClassPulse server. Check that the backend is running.',
      );
    }

    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : (jsonDecode(response.body) as Map<String, dynamic>);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message =
        decoded['message'] as String? ?? 'Request failed with status ${response.statusCode}.';
    throw ApiException(message, statusCode: response.statusCode);
  }

  String _generateJoinLink(String sessionCode) {
    if (kIsWeb) {
      final uri = Uri.base;
      final port = (uri.hasPort && uri.port != 80 && uri.port != 443) ? ':${uri.port}' : '';
      return '${uri.scheme}://${uri.host}$port?code=$sessionCode';
    }
    return 'classpulse://join/$sessionCode';
  }

  Future<User?> authenticateUser(
    String email,
    String password, {
    required String role,
  }) async {
    final data = await _send(
      'POST',
      '/auth/login',
      body: {'email': email, 'password': password},
    );

    final token = data['token'] as String?;
    final userData = data['user'] as Map<String, dynamic>?;
    if (token == null || userData == null) {
      throw const ApiException('The login response was incomplete.');
    }

    await setJwtToken(token);
    return User(
      id: userData['id'].toString(),
      name: userData['name'] as String? ?? 'Teacher',
      email: userData['email'] as String? ?? email,
      role: userData['role'] as String? ?? role,
    );
  }

  Future<User?> registerUser(
    String name,
    String email,
    String password, {
    required String role,
  }) async {
    final data = await _send(
      'POST',
      '/auth/signup',
      body: {'name': name, 'email': email, 'password': password, 'role': role},
    );
    final userData = data['user'] as Map<String, dynamic>?;
    if (userData == null) {
      throw const ApiException('The signup response was incomplete.');
    }

    return User(
      id: userData['id'].toString(),
      name: userData['name'] as String? ?? name,
      email: userData['email'] as String? ?? email,
      role: userData['role'] as String? ?? role,
    );
  }

  Future<Session> startSession(
    String classCode,
    String className,
    String teacherName,
    String teacherId,
  ) async {
    final data = await _send(
      'POST',
      '/sessions/create',
      authRequired: true,
      body: {'classCode': classCode, 'className': className},
    );
    final session = data['session'] as Map<String, dynamic>?;
    if (session == null) {
      throw const ApiException('The session could not be created.');
    }

    final sessionCode = session['sessionCode'] as String? ?? session['code'] as String? ?? '';
    return Session(
      id: session['id'] as String? ?? '',
      classCode: classCode,
      className: className,
      teacherName: teacherName,
      sessionCode: sessionCode,
      joinLink: session['joinLink'] as String? ?? _generateJoinLink(sessionCode),
      startTime: DateTime.now(),
      studentCount: (session['studentCount'] as num?)?.toInt() ?? 0,
      isActive: true,
      topic: className,
      isLobbyPhase: true,
    );
  }

  Future<Map<String, dynamic>?> endSession(String sessionCode) async {
    final data = await _send(
      'POST',
      '/sessions/$sessionCode/end',
      authRequired: true,
    );
    return data['summary'] as Map<String, dynamic>?;
  }

  Future<Session?> getSessionByCode(String sessionCode) async {
    final data = await _send('GET', '/sessions/$sessionCode');
    final session = data['session'] as Map<String, dynamic>?;
    if (session == null) {
      return null;
    }

    final isActiveValue = session['isActive'];
    final isActive = isActiveValue is bool
        ? isActiveValue
        : (isActiveValue is num ? isActiveValue == 1 : session['status'] != 'ended');

    return Session(
      id: session['id'] as String? ?? '',
      classCode: session['classCode'] as String? ?? sessionCode,
      className: session['className'] as String? ?? 'Class Session',
      teacherName: session['teacherName'] as String? ?? 'Teacher',
      sessionCode: session['sessionCode'] as String? ?? sessionCode,
      joinLink: session['joinLink'] as String? ?? _generateJoinLink(sessionCode),
      startTime: DateTime.now(),
      studentCount: (session['studentCount'] as num?)?.toInt() ?? 0,
      isActive: isActive,
      topic: session['className'] as String? ?? 'Live Session',
      isLobbyPhase: true,
    );
  }

  Future<Map<String, dynamic>?> getSessionSummary(String sessionCode) async {
    final data = await _send(
      'GET',
      '/sessions/$sessionCode/summary',
      authRequired: true,
    );
    return data['summary'] as Map<String, dynamic>?;
  }

  Future<int?> joinSessionAsStudent(
    String sessionCode, {
    String? studentName,
    String? studentEmail,
  }) async {
    final normalizedCode = sessionCode.trim().toUpperCase();
    final data = await _send(
      'POST',
      '/sessions/$normalizedCode/join',
      body: {
        'studentName': studentName ?? 'Anonymous Student',
        'studentEmail': studentEmail,
      },
    );

    final token = data['anonymous_student_token'] as String?;
    if (token == null) {
      throw const ApiException('The join response did not include a student token.');
    }
    setStudentToken(token, normalizedCode);
    return (data['studentCount'] as num?)?.toInt();
  }

  Future<bool> submitFeedback(
    String sessionCode,
    String studentId,
    String signal, {
    String? studentToken,
  }) async {
    final token = studentToken ?? _studentToken;
    if (token == null) {
      throw const ApiException('Join the session before sending feedback.');
    }

    await _send(
      'POST',
      '/sessions/$sessionCode/feedback',
      body: {'signal': signal, 'student_token': token},
    );
    return true;
  }

  Future<Map<String, dynamic>?> getAggregate(String sessionCode) async {
    return _send(
      'GET',
      '/sessions/$sessionCode/feedback/aggregate',
      authRequired: true,
    );
  }

  Future<bool> updateThreshold(String sessionCode, int threshold) async {
    await _send(
      'PATCH',
      '/sessions/$sessionCode/threshold',
      authRequired: true,
      body: {'threshold': threshold},
    );
    return true;
  }

  Future<Question?> askQuestion(
    String sessionCode,
    String text, {
    String? studentTokenOverride,
    String? studentId,
    String? studentName,
    String? sessionId,
    String? title,
    String? description,
  }) async {
    final token = studentTokenOverride ?? _studentToken;
    if (token == null) {
      throw const ApiException('Join the session before sending a question.');
    }

    final questionText = text.trim().isNotEmpty
        ? text.trim()
        : [title, description].whereType<String>().where((value) => value.trim().isNotEmpty).join(' ');

    final data = await _send(
      'POST',
      '/sessions/$sessionCode/questions',
      body: {'text': questionText, 'student_token': token},
    );
    final question = data['question'] as Map<String, dynamic>?;
    if (question == null) {
      throw const ApiException('The question was submitted, but no question payload was returned.');
    }

    return Question(
      id: question['id'].toString(),
      sessionId: sessionCode,
      studentId: token,
      studentName: studentName ?? 'Anonymous',
      title: question['text'] as String? ?? questionText,
      description: '',
      timestamp: DateTime.tryParse(question['timestamp'] as String? ?? '') ?? DateTime.now(),
      isAnswered: false,
    );
  }

  Future<List<Question>> getQuestions(String sessionCode) async {
    final data = await _send(
      'GET',
      '/sessions/$sessionCode/questions',
      authRequired: true,
    );
    final questions = (data['questions'] as List<dynamic>? ?? <dynamic>[]);
    return questions.map((item) {
      final question = item as Map<String, dynamic>;
      final isAnsweredValue = question['is_answered'] ?? question['isAnswered'];
      return Question(
        id: question['id'].toString(),
        sessionId: sessionCode,
        studentId: 'anonymous',
        studentName: 'Anonymous',
        title: question['text'] as String? ?? '',
        description: '',
        timestamp: DateTime.tryParse(question['timestamp'] as String? ?? '') ?? DateTime.now(),
        isAnswered: isAnsweredValue == true || isAnsweredValue == 1,
      );
    }).toList();
  }

  Future<bool> markAnswered(String sessionCode, String questionId) async {
    await _send(
      'PATCH',
      '/sessions/$sessionCode/questions/$questionId/answer',
      authRequired: true,
    );
    return true;
  }

  Future<Session?> joinClass(String classCode) => getSessionByCode(classCode);

  Future<List<ClassModel>> getClasses() async => [];

  Future<Session?> getSessionDetails(String classCode) => getSessionByCode(classCode);
}

final apiService = ApiService();
