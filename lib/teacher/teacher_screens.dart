import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../models/models.dart';
import '../services/api_service.dart';

/// Teacher Dashboard - Home screen for teacher mobile app
class TeacherDashboard extends StatefulWidget {
  final String? language;
  final Function(ClassModel)? onClassSelected;
  final String? teacherId;
  final String? teacherName;

  const TeacherDashboard({
    super.key,
    this.language = 'English (US)',
    this.onClassSelected,
    this.teacherId,
    this.teacherName,
  });

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  late Future<List<ClassModel>> _classes;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _classes = apiService.getClasses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'My Classes',
          style: TextStyle(
            color: Color(0xFF2D5BFF),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications')),
              );
            },
            icon: const Icon(Icons.notifications_none),
            color: const Color(0xFF2D5BFF),
          ),
        ],
      ),
      body: FutureBuilder<List<ClassModel>>(
        future: _classes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF2D5BFF),
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final classItem = snapshot.data![index];
              return _buildClassCard(context, classItem);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateClassDialog(context);
        },
        backgroundColor: const Color(0xFF2D5BFF),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.class_,
            size: 80,
            color: Color(0xFF2D5BFF),
          ),
          SizedBox(height: 16),
          Text(
            'No classes yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D5BFF),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your first class to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(BuildContext context, ClassModel classItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Status indicator
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEF5350),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                classItem.isLive ? 'LIVE' : 'UPCOMING',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  classItem.className,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D5BFF),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Code: ${classItem.classCode}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people,
                          size: 16,
                          color: Color(0xFF2D5BFF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${classItem.enrolledStudents} students',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2D5BFF),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _startSession(context, classItem);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5BFF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Start',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startSession(BuildContext context, ClassModel classItem) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(0xFF2D5BFF),
                ),
              ),
              SizedBox(height: 16),
              Text('Starting session...'),
            ],
          ),
        ),
      );

      // Start session via API
      final session = await apiService.startSession(
        classItem.classCode,
        classItem.className,
        widget.teacherName ?? 'Teacher',
        widget.teacherId ?? '0',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Navigate to SessionLobby
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionLobbyScreen(
            session: session,
            onEndSession: () => Navigator.pop(context),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting session: $e')),
        );
      }
    }
  }

  void _showCreateClassDialog(BuildContext context) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Class'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Class Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Class Code',
                border: OutlineInputBorder(),
                hintText: '6 characters',
              ),
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement class creation via API
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Class created successfully')),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

/// Teacher Live Session Management
class TeacherLiveSession extends StatefulWidget {
  final ClassModel classModel;
  final String? language;

  const TeacherLiveSession({
    super.key,
    required this.classModel,
    this.language,
  });

  @override
  State<TeacherLiveSession> createState() => _TeacherLiveSessionState();
}

class _TeacherLiveSessionState extends State<TeacherLiveSession> {
  bool _isScreenSharing = false;
  late Session _session;
  List<Question> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    final session = await apiService.getSessionDetails(widget.classModel.classCode);
    if (session != null) {
      setState(() {
        _session = session;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.classModel.className,
          style: const TextStyle(
            color: Color(0xFF2D5BFF),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF5350),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Session Stats
              _buildSessionStats(),
              const SizedBox(height: 24),
              
              // Screen Sharing Toggle
              _buildScreenShareToggle(),
              const SizedBox(height: 24),
              
              // Active Questions
              _buildQuestionsSection(),
              const SizedBox(height: 24),
              
              // Live Controls
              _buildLiveControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionStats() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Stats',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D5BFF),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Students', '28', Icons.people),
              _buildStatItem('Duration', '45m', Icons.timer),
              _buildStatItem('Feedback', '26', Icons.feedback),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2D5BFF), size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D5BFF),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildScreenShareToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Screen Sharing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D5BFF),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Share screen with students',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Switch(
            value: _isScreenSharing,
            onChanged: (value) {
              setState(() {
                _isScreenSharing = value;
              });
              final msg = value ? 'Screen sharing started' : 'Screen sharing stopped';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg)),
              );
            },
            activeColor: const Color(0xFF2D5BFF),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Questions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D5BFF),
          ),
        ),
        const SizedBox(height: 12),
        if (_questions.isEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: const Text(
              'No questions yet',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final question = _questions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${question.studentName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLiveControls() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Session paused')),
              );
            },
            icon: const Icon(Icons.pause),
            label: const Text('Pause'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFC107),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFF4CAF50),
                  title: const Text(
                    'Session Ended!',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  content: const Text(
                    'Session has been ended. Summary report generated.',
                    style: TextStyle(color: Colors.white),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.stop),
            label: const Text('End'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF5350),
            ),
          ),
        ),
      ],
    );
  }
}

/// Session Lobby Screen - Teacher pre-session screen with code, QR, and share options
class SessionLobbyScreen extends StatefulWidget {
  final Session session;
  final VoidCallback onEndSession;

  const SessionLobbyScreen({
    super.key,
    required this.session,
    required this.onEndSession,
  });

  @override
  State<SessionLobbyScreen> createState() => _SessionLobbyScreenState();
}

class _SessionLobbyScreenState extends State<SessionLobbyScreen> {
  late Session _session;
  int _studentCount = 0;
  Timer? _pollTimer;
  final ApiService _apiService = apiService;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _studentCount = widget.session.studentCount;
    
    // Start polling for student count updates every 2 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final updatedSession = await _apiService.getSessionByCode(_session.sessionCode);
      if (mounted && updatedSession != null) {
        if (_studentCount != updatedSession.studentCount) {
          print('?? Student count updated: $_studentCount ? ${updatedSession.studentCount}');
        }
        setState(() {
          _studentCount = updatedSession.studentCount;
        });
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _shareToWhatsApp() async {
    final message = 'Join my class on ClassPulse:\n${_session.joinLink}';
    
    try {
      await Share.share(message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: $e')),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(
      ClipboardData(text: _session.joinLink),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _startClass() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Start Class?'),
        content: Text(
          'Start class with $_studentCount student${_studentCount != 1 ? 's' : ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to live classroom with camera
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeacherLiveClassroom(
                    session: _session,
                    studentCount: _studentCount,
                  ),
                ),
              );
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _endSession() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEF5350),
        title: const Text(
          'End Session?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This will close the session and students won\'t be able to join.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onEndSession();
            },
            child: const Text(
              'End',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Session Lobby',
          style: TextStyle(
            color: Color(0xFF2D5BFF),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          onPressed: _endSession,
          icon: const Icon(Icons.close),
          color: const Color(0xFF2D5BFF),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Live Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF5350),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Session Ready',
                    style: TextStyle(
                      color: Color(0xFFEF5350),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Session Code (Large)
              Column(
                children: [
                  Text(
                    'Session Code',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF2D5BFF),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D5BFF).withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _session.sessionCode,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D5BFF),
                        letterSpacing: 8,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // QR Code
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _session.joinLink,
                  version: QrVersions.auto,
                  size: 240,
                  gapless: true,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.circle,
                    color: Color(0xFF2D5BFF),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: Color(0xFF2D5BFF),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Join Link with Copy Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join Link',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _session.joinLink,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D5BFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      color: const Color(0xFF2D5BFF),
                      tooltip: 'Copy link',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Students Joined Count
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5BFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF2D5BFF),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        '$_studentCount',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2D5BFF),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _studentCount == 1 ? 'Student Joined' : 'Students Joined',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Share Buttons
              Row(
                children: [
                  // WhatsApp Share
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _shareToWhatsApp,
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366), // WhatsApp green
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Copy Link
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyToClipboard,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2D5BFF),
                        side: const BorderSide(
                          color: Color(0xFF2D5BFF),
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Start Class Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _studentCount > 0 ? _startClass : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: const Text(
                        'Start Class',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (_studentCount == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFC107).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFFFC107),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFFFFC107),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Waiting for at least 1 student to join',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Teacher Live Classroom Screen - Camera, Screen Share, and Live Teaching
class TeacherLiveClassroom extends StatefulWidget {
  final Session session;
  final int studentCount;

  const TeacherLiveClassroom({
    super.key,
    required this.session,
    required this.studentCount,
  });

  @override
  State<TeacherLiveClassroom> createState() => _TeacherLiveClassroomState();
}

class _TeacherLiveClassroomState extends State<TeacherLiveClassroom> {
  bool _isCameraOn = true;
  bool _isMicOn = true;
  bool _isScreenSharing = false;
  bool _isEndingSession = false;

  // Live aggregate state
  int _gotIt = 0;
  int _sortOf = 0;
  int _lost = 0;
  int _total = 0;
  bool _alert = false;
  List<Question> _questions = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    // Poll aggregate + questions every 3 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final agg = await apiService.getAggregate(widget.session.sessionCode);
      if (mounted && agg != null) {
        setState(() {
          _gotIt = agg['got_it'] ?? 0;
          _sortOf = agg['sort_of'] ?? 0;
          _lost = agg['lost'] ?? 0;
          _total = agg['total'] ?? 0;
          _alert = agg['alert'] == true;
        });
      }

      final questions = await apiService.getQuestions(widget.session.sessionCode);
      if (mounted) {
        setState(() => _questions = questions);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _endClass() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Class?'),
        content: const Text(
          'Are you sure you want to end the class? All students will be disconnected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('End Class', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isEndingSession = true);
    _pollTimer?.cancel();

    final summary = await apiService.endSession(widget.session.sessionCode);

    if (!mounted) return;
    setState(() => _isEndingSession = false);

    // Show summary dialog then pop
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF4CAF50)),
            SizedBox(width: 8),
            Text('Session Ended!', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary != null) ...[
              _SummaryRow(icon: Icons.people, label: 'Students', value: '${summary['totalStudents'] ?? 0}'),
              _SummaryRow(icon: Icons.thumb_up, label: 'Got It', value: '${summary['gotItCount'] ?? 0}', color: const Color(0xFF4CAF50)),
              _SummaryRow(icon: Icons.remove_circle_outline, label: 'Sort Of', value: '${summary['sortOfCount'] ?? 0}', color: const Color(0xFFFFC107)),
              _SummaryRow(icon: Icons.cancel, label: 'Lost', value: '${summary['lostCount'] ?? 0}', color: const Color(0xFFEF5350)),
              _SummaryRow(icon: Icons.help_outline, label: 'Questions', value: '${summary['questionCount'] ?? 0}'),
              _SummaryRow(icon: Icons.timer, label: 'Duration', value: '${summary['durationMinutes'] ?? 0} min'),
            ] else
              const Text('Session ended successfully.'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5BFF)),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('End Class?'),
                content: const Text('Are you sure you want to end the class?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('End Class', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
        title: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFEF5350),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'LIVE',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Center(
              child: Text(
                '${widget.studentCount} Students',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview placeholder
          Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Alert banner
                  if (_alert)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ALERT: Many students are lost!',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),

                  // Live aggregate chips
                  if (_total > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _AggChip(label: 'Got It', count: _gotIt, color: const Color(0xFF4CAF50)),
                          _AggChip(label: 'Sort Of', count: _sortOf, color: const Color(0xFFFFC107)),
                          _AggChip(label: 'Lost', count: _lost, color: const Color(0xFFEF5350)),
                        ],
                      ),
                    ),

                  // Camera preview area
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.40,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      border: Border.all(color: const Color(0xFF2D5BFF), width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isCameraOn)
                          Icon(Icons.videocam, size: 60,
                              color: const Color(0xFF2D5BFF).withOpacity(0.6))
                        else
                          Icon(Icons.videocam_off, size: 60, color: Colors.red.withOpacity(0.6)),
                        const SizedBox(height: 12),
                        Text(
                          _isCameraOn ? 'Camera On' : 'Camera Off',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // Live questions section
                  if (_questions.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[700]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Questions (${_questions.where((q) => !q.isAnswered).length} unanswered)',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          ...(_questions.take(3).map((q) => _QuestionTile(
                                question: q,
                                onMarkAnswered: () async {
                                  await apiService.markAnswered(
                                    widget.session.sessionCode,
                                    q.id,
                                  );
                                  final qs = await apiService.getQuestions(widget.session.sessionCode);
                                  if (mounted) setState(() => _questions = qs);
                                },
                              ))),
                          if (_questions.length > 3)
                            Text(
                              '+${_questions.length - 3} more...',
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Control Panel at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.9),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[700]!,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Control Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Camera Button
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() => _isCameraOn = !_isCameraOn);
                            },
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isCameraOn
                                    ? const Color(0xFF4CAF50)
                                    : Colors.red,
                              ),
                              child: Icon(
                                _isCameraOn
                                    ? Icons.videocam
                                    : Icons.videocam_off,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isCameraOn ? 'Camera' : 'Camera Off',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      // Microphone Button
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() => _isMicOn = !_isMicOn);
                            },
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isMicOn
                                    ? const Color(0xFF4CAF50)
                                    : Colors.red,
                              ),
                              child: Icon(
                                _isMicOn ? Icons.mic : Icons.mic_off,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isMicOn ? 'Mic' : 'Mic Off',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      // Screen Share Button
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(
                                  () => _isScreenSharing = !_isScreenSharing);
                            },
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isScreenSharing
                                    ? const Color(0xFF4CAF50)
                                    : Colors.grey[700],
                              ),
                              child: Icon(
                                Icons.screen_share,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isScreenSharing
                                ? 'Sharing'
                                : 'Share Screen',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      // End Call Button
                      Column(
                        children: [
                          GestureDetector(
                            onTap: _isEndingSession ? null : _endClass,
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFEF5350),
                              ),
                              child: _isEndingSession
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.call_end, color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'End Class',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// --- Aggregate chip widget ---

class _AggChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _AggChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// --- Question tile widget ---

class _QuestionTile extends StatelessWidget {
  final Question question;
  final VoidCallback onMarkAnswered;

  const _QuestionTile({required this.question, required this.onMarkAnswered});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: question.isAnswered ? Colors.green.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: question.isAnswered ? Colors.green : Colors.grey[700]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              question.title,
              style: TextStyle(color: question.isAnswered ? Colors.green[300] : Colors.white, fontSize: 12),
            ),
          ),
          if (!question.isAnswered)
            GestureDetector(
              onTap: onMarkAnswered,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(6)),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              ),
            )
          else
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
        ],
      ),
    );
  }
}

// --- Summary row widget ---

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _SummaryRow({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF2D5BFF);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: c, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: c)),
        ],
      ),
    );
  }
}


