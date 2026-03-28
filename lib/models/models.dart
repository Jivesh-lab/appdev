// User Model
class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' or 'teacher'
  final String? profilePicture;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profilePicture,
  });
}

// Class Model
class ClassModel {
  final String id;
  final String classCode;
  final String className;
  final String subject;
  final String teacherName;
  final String scheduleTime;
  final int enrolledStudents;
  final bool isLive;
  
  ClassModel({
    required this.id,
    required this.classCode,
    required this.className,
    required this.subject,
    required this.teacherName,
    required this.scheduleTime,
    required this.enrolledStudents,
    required this.isLive,
  });
}

// Session Model
class Session {
  final String id;
  final String classCode;
  final String className;
  final String teacherName;
  final String sessionCode; // 4-digit code for joining
  final String joinLink; // Full join URL
  final DateTime startTime;
  final DateTime? endTime;
  final int studentCount;
  final bool isActive;
  final String topic;
  final bool isLobbyPhase; // True if in lobby, false if live with students
  
  Session({
    required this.id,
    required this.classCode,
    required this.className,
    required this.teacherName,
    required this.sessionCode,
    required this.joinLink,
    required this.startTime,
    this.endTime,
    required this.studentCount,
    required this.isActive,
    required this.topic,
    required this.isLobbyPhase,
  });
}

// Feedback Model
class Feedback {
  final String id;
  final String sessionId;
  final String studentId;
  final String feedbackType; // 'got_it', 'sort_of', 'lost'
  final DateTime timestamp;
  
  Feedback({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.feedbackType,
    required this.timestamp,
  });
}

// Question Model
class Question {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String title;
  final String description;
  final DateTime timestamp;
  final bool isAnswered;
  
  Question({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.isAnswered,
  });
}

// Attendance Model
class Attendance {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final DateTime joinTime;
  final DateTime? leaveTime;
  final Duration duration;
  
  Attendance({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.joinTime,
    this.leaveTime,
    required this.duration,
  });
}
