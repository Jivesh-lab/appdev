import 'package:flutter/material.dart';
import 'localization.dart';
import '../services/api_service.dart';

class JoinClassScreen extends StatefulWidget {
  final Function(String) onJoin;
  final String language;

  const JoinClassScreen({super.key, required this.onJoin, this.language = 'English (US)'});

  @override
  State<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends State<JoinClassScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _joinClass() {
    if (_codeController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter a class code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Call API to join session
    apiService.joinSessionAsStudent(
      _codeController.text,
      studentName: 'Student',
    ).then((studentCount) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        if (studentCount != null) {
          // Successfully joined
          widget.onJoin(_codeController.text);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Joined! ($studentCount students in session)'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        } else {
          setState(() => _errorMessage = 'Invalid or expired class code');
        }
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to join: ${error.toString()}';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 80),

              // Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D5BFF), Color(0xFF4A90E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D5BFF).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.school_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              const Text(
                'ClassPulse',
                style: TextStyle(
                  color: Color(0xFF2D5BFF),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Interactive Learning Platform',
                style: TextStyle(
                  color: const Color(0xFF7A8BA3),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 60),

              // Instruction
              const Text(
                'Enter Class Code',
                style: TextStyle(
                  color: Color(0xFF2D5BFF),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Ask your teacher for the class code to join',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF7A8BA3),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 32),

              // Code Input Field
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _codeController,
                  enabled: !_isLoading,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: Color(0xFF2D5BFF),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter Code',
                    hintStyle: TextStyle(
                      color: const Color(0xFFA6B5C5),
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Color(0xFFE0E6F0),
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Color(0xFFE0E6F0),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: Color(0xFF2D5BFF),
                        width: 2.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEF5350),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFEF5350),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Color(0xFFEF5350),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Join Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5BFF),
                    elevation: 8,
                    shadowColor: const Color(0xFF2D5BFF).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isLoading ? null : _joinClass,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Join Class',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== QUICK JOIN SCREEN (From QR/Link) ====================

class QuickJoinScreen extends StatefulWidget {
  final String sessionCode;
  final Function(String) onJoin;
  final String language;

  const QuickJoinScreen({
    super.key,
    required this.sessionCode,
    required this.onJoin,
    this.language = 'English (US)',
  });

  @override
  State<QuickJoinScreen> createState() => _QuickJoinScreenState();
}

class _QuickJoinScreenState extends State<QuickJoinScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  String? _sessionName;

  @override
  void initState() {
    super.initState();
    _loadSessionInfo();
  }

  void _loadSessionInfo() async {
    try {
      final session = await apiService.getSessionByCode(widget.sessionCode);
      if (mounted && session != null) {
        setState(() {
          _sessionName = session.className;
        });
      }
    } catch (e) {
      print('Error loading session: $e');
    }
  }

  void _quickJoin() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Direct join without asking for details
    apiService.joinSessionAsStudent(
      widget.sessionCode,
      studentName: 'Student',
    ).then((studentCount) {
      if (mounted) {
        setState(() => _isLoading = false);

        if (studentCount != null) {
          widget.onJoin(widget.sessionCode);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Joined! ($studentCount in class)'),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );
        } else {
          setState(() => _errorMessage = 'Session not found or expired');
        }
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Connection error. Try again.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1F1F47),
            const Color(0xFF2D1B4E),
            const Color(0xFF1A1A3A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2D5BFF), Color(0xFF4A90E2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2D5BFF).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.school_rounded,
                  size: 50,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'ClassPulse',
                style: TextStyle(
                  color: Color(0xFF2D5BFF),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 40),

              // Session Code Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5BFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2D5BFF),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Session Code',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.sessionCode,
                      style: const TextStyle(
                        color: Color(0xFF2D5BFF),
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                      ),
                    ),
                  ],
                ),
              ),

              if (_sessionName != null) ...[
                const SizedBox(height: 24),
                Text(
                  _sessionName!,
                  style: const TextStyle(
                    color: Color(0xFF2D5BFF),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFEF5350),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFEF5350),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Color(0xFFEF5350),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),

              // Join Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    elevation: 8,
                    shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  onPressed: _isLoading ? null : _quickJoin,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Join Session',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class LiveSessionScreen extends StatefulWidget {
  final String classCode;
  final VoidCallback onLeave;
  final String language;

  const LiveSessionScreen({
    super.key,
    required this.classCode,
    required this.onLeave,
    this.language = 'English (US)',
  });

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen>
    with SingleTickerProviderStateMixin {
  String? selectedFeedback;
  String? previousFeedback;
  bool isMicOn = true;
  bool isCameraOn = true;
  bool isHandRaised = false;
  late AnimationController _animationController;

  late ScrollController _scrollController;

  // Camera window state
  Offset _cameraPosition = const Offset(10, 10);
  Size _cameraSize = const Size(280, 210);
  bool _isCameraMinimized = false;

  final String studentName = "Jimmy Kumar";
  final String studentEmail = "jimmy.kumar@school.edu";
  final String studentId = "EMS-2024-25";
  final String subjectName = "DBMS";
  final String attendanceStatus = "Present";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _submitFeedback(String type) {
    setState(() {
      previousFeedback = selectedFeedback;
      selectedFeedback = type;
    });

    _animationController.forward(from: 0.0);

    // ✅ Send real feedback signal to backend
    apiService.submitFeedback(
      widget.classCode,
      apiService.studentToken ?? studentId,
      type,
    ).then((success) {
      if (success) {
        print('✅ Feedback sent to backend: $type');
      } else {
        print('⚠️ Feedback sent locally only (no student_token yet)');
      }
    });

    // Snackbar message based on type
    String message = '';
    if (type == 'got_it') {
      message = 'Great! Moving ahead 🚀';
    } else if (type == 'sort_of') {
      message = 'Continuing with next topic ⏳';
    } else {
      message = "Let's revisit this 📘";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2D5BFF),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Scaffold
        Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header AppBar
          SliverAppBar(
            expandedHeight: 0,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
            title: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ClassPulse - ${widget.classCode}',
                      style: const TextStyle(
                        color: Color(0xFF2D5BFF),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF5350),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Live',
                      style: TextStyle(
                        color: Color(0xFFEF5350),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No new notifications'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none),
                color: const Color(0xFF2D5BFF),
              ),
            ],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Live Lecture Video Area
                Container(
                  margin: const EdgeInsets.all(16),
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2D5BFF).withOpacity(0.15),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF5DADE2),
                                Color(0xFF85C1E2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        // Pattern overlay
                        Positioned(
                          right: -30,
                          top: -30,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        // Content
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.videocam_outlined,
                              size: 64,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Live session ongoing…',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Teacher is sharing screen',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Feedback Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How well did you understand?',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF2D5BFF),
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...[
                        _buildFeedbackOption(
                          context,
                          'got_it',
                          'Got It!',
                          'Understood completely',
                          const Color(0xFFE3F2FD),
                          const Color(0xFF2196F3),
                          Icons.check_circle_outline,
                        ),
                        _buildFeedbackOption(
                          context,
                          'sort_of',
                          'Sort Of',
                          'Partially understood',
                          const Color(0xFFFFF8E1),
                          const Color(0xFFFFC107),
                          Icons.help_outline,
                        ),
                        _buildFeedbackOption(
                          context,
                          'lost',
                          'Lost',
                          'Need more clarity',
                          const Color(0xFFECEFF1),
                          const Color(0xFF607D8B),
                          Icons.close_outlined,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),

      // Bottom Controls
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mic Toggle
            _buildControl(
              icon: isMicOn ? Icons.mic : Icons.mic_off,
              label: isMicOn ? 'Mic' : 'Mute',
              color: const Color(0xFF2D5BFF),
              onTap: () {
                setState(() => isMicOn = !isMicOn);
              },
            ),
            const SizedBox(width: 16),

            // Camera Toggle
            _buildControl(
              icon: isCameraOn ? Icons.videocam : Icons.videocam_off,
              label: isCameraOn ? 'Camera' : 'Off',
              color: const Color(0xFF2D5BFF),
              onTap: () {
                setState(() => isCameraOn = !isCameraOn);
              },
            ),
            const SizedBox(width: 16),

            // Raise Hand
            _buildControl(
              icon: Icons.pan_tool,
              label: isHandRaised ? 'Hand ✓' : 'Hand',
              color: isHandRaised
                  ? const Color(0xFFFFC107)
                  : const Color(0xFF2D5BFF),
              onTap: () {
                setState(() => isHandRaised = !isHandRaised);
                final msg = isHandRaised ? 'Hand raised ✋' : 'Hand lowered';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(msg)),
                );
              },
            ),
            const SizedBox(width: 16),

            // Leave Class
            _buildControl(
              icon: Icons.call_end,
              label: 'Leave',
              color: const Color(0xFFEF5350),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Leave Class?'),
                    content: const Text(
                      'Are you sure you want to leave the class?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Show Thank You message
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFF4CAF50),
                              title: const Text(
                                'Thank You!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                              ),
                              content: const Text(
                                'Thanks for joining the class. See you next time!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    widget.onLeave();
                                  },
                                  child: const Text(
                                    'Exit',
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
                        child: const Text('Leave'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
        
        // Floating Camera Window
        if (isCameraOn)
          Positioned(
            left: _cameraPosition.dx,
            top: _cameraPosition.dy,
            child: _buildFloatingCameraWindow(context),
          ),
      ],
    );
  }

  Widget _buildFloatingCameraWindow(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _cameraPosition = Offset(
            _cameraPosition.dx + details.delta.dx,
            _cameraPosition.dy + details.delta.dy,
          );
        });
      },
      child: Container(
        width: _isCameraMinimized ? 200 : _cameraSize.width,
        height: _isCameraMinimized ? 50 : _cameraSize.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2D5BFF), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Camera feed background
              Container(
                color: Colors.black87,
                child: _isCameraMinimized
                    ? null
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2D5BFF).withOpacity(0.2),
                            ),
                            child: const Icon(
                              Icons.videocam,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Camera',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
              // Controls header
              Container(
                color: Colors.black54,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Your Camera',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        // Minimize/Maximize button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isCameraMinimized = !_isCameraMinimized;
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              _isCameraMinimized
                                  ? Icons.unfold_more
                                  : Icons.unfold_less,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        // Close button
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              isCameraOn = false;
                            });
                          },
                          child: Container(
                            color: Colors.transparent,
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
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
        ),
      ),
    );
  }

  Widget _buildControl({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackOption(
    BuildContext context,
    String type,
    String title,
    String subtitle,
    Color backgroundColor,
    Color fillColor,
    IconData icon,
  ) {
    final isSelected = selectedFeedback == type;
    final isPrevious = previousFeedback == type;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _submitFeedback(type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? fillColor : Colors.transparent,
              width: isSelected ? 2.5 : 0,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: fillColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: fillColor.withOpacity(isSelected ? 1 : 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : fillColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF2D5BFF),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF7A8BA3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: fillColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                )
              else if (isPrevious)
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFBDBDBD),
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== STUDENT PROFILE SCREEN ====================

class StudentProfileScreen extends StatelessWidget {
  final VoidCallback onBack;
  final String language;

  const StudentProfileScreen({super.key, required this.onBack, this.language = 'English (US)'});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Enhanced Gradient Header with Profile
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF2D5BFF),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                      Color(0xFF5DADE2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Profile Content - Centered and balanced
                    Align(
                      alignment: Alignment.topCenter,
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar with User Initials
                                Container(
                                  width: 88,
                                  height: 88,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.28),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4A90E2),
                                        Color(0xFF2D5BFF),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'JK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Larger details card with glass look
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.20),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.35),
                                      width: 1.4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Jimmy Kumar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'FY BTech | Div A | Roll No. 23',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.93),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Student ID: EMS-2024-25',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.85),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
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
            ),
          ),

          // Content Sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // My Classes Section
                  _buildSectionHeader('My Subjects', onViewAll: () {}),
                  const SizedBox(height: 12),
                  _buildClassCard(
                    'English',
                    'Period 1',
                    '88%',
                    Colors.blue,
                    Colors.lightBlue,
                    '7 A',
                    'Hard',
                  ),
                  const SizedBox(height: 12),
                  _buildClassCard(
                    'Mathematics',
                    'Period 3',
                    '98%',
                    Colors.orange,
                    Colors.orangeAccent,
                    '7 A',
                    'Hard',
                  ),
                  const SizedBox(height: 12),
                  _buildClassCard(
                    'Science',
                    'Period 5',
                    '85%',
                    Colors.green,
                    Colors.lightGreen,
                    '7 A',
                    'Medium',
                  ),

                  const SizedBox(height: 24),

                  // Performance Overview
                  _buildSectionHeader('Performance Overview', onViewAll: () {}),
                  const SizedBox(height: 12),
                  _buildPerformanceCard(),

                  const SizedBox(height: 24),

                  // Learning Stats
                  _buildSectionHeader('Session Insights', onViewAll: () {}),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatisticCard(
                          'Got It',
                          '12',
                          const Color(0xFF4CAF50),
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatisticCard(
                          'Sort Of',
                          '4',
                          const Color(0xFFFFC107),
                          Icons.help_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatisticCard(
                          'Lost',
                          '8',
                          const Color(0xFFEF5350),
                          Icons.cancel,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Your Questions
                  _buildSectionHeader('Your Questions', onViewAll: () {}, count: 2),
                  const SizedBox(height: 12),
                  _buildQuestionCard('Can you explain that again?'),
                  const SizedBox(height: 10),
                  _buildQuestionCard('What does this topic mean?'),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title,
      {required VoidCallback onViewAll, int? count}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2D5BFF),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2D5BFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Color(0xFF2D5BFF),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          )
        else
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'View all',
              style: TextStyle(
                color: Color(0xFF667EEA),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildClassCard(
    String subject,
    String period,
    String completion,
    Color primaryColor,
    Color secondaryColor,
    String grade,
    String difficulty,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.book,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject,
                        style: const TextStyle(
                          color: Color(0xFF2D5BFF),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        period,
                        style: const TextStyle(
                          color: Color(0xFF7A8BA3),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                completion,
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: double.parse(completion.replaceAll('%', '')) / 100,
                    backgroundColor: const Color(0xFFECEFF1),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                grade,
                style: const TextStyle(
                  color: Color(0xFF7A8BA3),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  difficulty,
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confidence Score',
                    style: TextStyle(
                      color: Color(0xFF2D5BFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Moderate Confidence',
                    style: TextStyle(
                      color: Color(0xFF7A8BA3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFECEFF1),
                    width: 8,
                  ),
                  gradient: const SweepGradient(
                    colors: [
                      Color(0xFFEF5350),
                      Color(0xFFFFC107),
                      Color(0xFF4CAF50),
                    ],
                  ),
                ),
                child: const Center(
                  child: Text(
                    '67%',
                    style: TextStyle(
                      color: Color(0xFF2D5BFF),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFC107).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '💡 You seem confused frequently. Try asking questions!',
              style: TextStyle(
                color: Color(0xFF7A8BA3),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String question) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2D5BFF).withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D5BFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.help_outline,
                    size: 18,
                    color: Color(0xFF2D5BFF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      color: Color(0xFF2D5BFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 12,
            color: Color(0xFF2D5BFF),
          ),
        ],
      ),
    );
  }
}

// ==================== ASK QUESTION SCREEN ====================

class AskQuestionScreen extends StatefulWidget {
  final String language;

  const AskQuestionScreen({super.key, this.language = 'English (US)'});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final TextEditingController _questionController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _submitQuestion() async {
    final text = _questionController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final sessionCode = apiService.currentSessionCode;
      if (sessionCode == null) {
        // No active session found — show local success anyway
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question submitted!'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _questionController.clear();
        return;
      }

      final question = await apiService.askQuestion(sessionCode, text);

      if (!mounted) return;

      if (question != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question submitted to teacher! ✅'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _questionController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not submit — join a session first'),
            backgroundColor: Color(0xFFEF5350),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFEF5350),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2D5BFF),
        elevation: 0,
        centerTitle: true,
        title: Text(
          AppStrings.get(widget.language, 'ask_question'),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'What would you like to ask?',
                style: TextStyle(
                  color: Color(0xFF2D5BFF),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _questionController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Type your question here...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E6F0),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E6F0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF2D5BFF),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5BFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitQuestion,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Submit Question',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== SETTINGS SCREEN ====================

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;
  final String theme;
  final Function(String) onThemeChanged;
  final VoidCallback onLogout;
  final bool notificationsEnabled;
  final Function(bool) onNotificationsChanged;
  final String language;
  final Function(String) onLanguageChanged;
  final bool twoFactorEnabled;
  final Function(bool) onTwoFactorChanged;
  final double storageUsed;
  final VoidCallback onClearStorage;

  const SettingsScreen({
    super.key,
    required this.onBack,
    required this.theme,
    required this.onThemeChanged,
    required this.onLogout,
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.language,
    required this.onLanguageChanged,
    required this.twoFactorEnabled,
    required this.onTwoFactorChanged,
    required this.storageUsed,
    required this.onClearStorage,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _passwordController;
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _nameController = TextEditingController(text: 'Jimmy Kumar');
    _emailController = TextEditingController(text: 'jimmy.kumar@school.edu');
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: Color(0xFF2D5BFF)),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF5DADE2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        child: const Icon(Icons.settings, size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(AppStrings.get(widget.language, 'settings'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(AppStrings.get(widget.language, 'app_settings')),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    icon: Icons.brightness_7,
                    title: AppStrings.get(widget.language, 'theme'),
                    subtitle: (widget.theme ?? 'light')[0].toUpperCase() + (widget.theme ?? 'light').substring(1),
                    onTap: () => _showThemeBottomSheet(context),
                  ),
                  _buildToggleTile(
                    icon: Icons.notifications,
                    title: AppStrings.get(widget.language, 'notifications'),
                    subtitle: widget.notificationsEnabled ? 'Enabled' : 'Disabled',
                    value: widget.notificationsEnabled,
                    onChanged: widget.onNotificationsChanged,
                  ),
                  _buildSettingsTile(
                    icon: Icons.language,
                    title: AppStrings.get(widget.language, 'language'),
                    subtitle: widget.language ?? 'English (US)',
                    onTap: () => _showLanguageBottomSheet(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(AppStrings.get(widget.language, 'account_settings')),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    icon: Icons.person,
                    title: AppStrings.get(widget.language, 'profile_information'),
                    subtitle: AppStrings.get(widget.language, 'edit_profile_details'),
                    onTap: () => _showProfileDialog(context),
                  ),
                  _buildSettingsTile(
                    icon: Icons.lock,
                    title: AppStrings.get(widget.language, 'change_password'),
                    subtitle: AppStrings.get(widget.language, 'update_password'),
                    onTap: () => _showPasswordDialog(context),
                  ),
                  _buildToggleTile(
                    icon: Icons.security,
                    title: AppStrings.get(widget.language, 'two_factor'),
                    subtitle: widget.twoFactorEnabled ? AppStrings.get(widget.language, 'enabled') : AppStrings.get(widget.language, 'disabled'),
                    value: widget.twoFactorEnabled,
                    onChanged: widget.onTwoFactorChanged,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Learning Preferences'),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    icon: Icons.download,
                    title: 'Download Folder',
                    subtitle: 'Manage downloaded materials',
                    onTap: () => _showDownloadDialog(context),
                  ),
                  _buildSettingsTile(
                    icon: Icons.storage,
                    title: 'Storage Management',
                    subtitle: '${widget.storageUsed.toStringAsFixed(1)} GB used',
                    onTap: () => _showStorageDialog(context),
                  ),
                  _buildSettingsTile(
                    icon: Icons.privacy_tip,
                    title: 'Data & Privacy',
                    subtitle: 'Manage your data and privacy',
                    onTap: () => _showDataPrivacyDialog(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('About'),
                  const SizedBox(height: 12),
                  _buildSettingsTile(
                    icon: Icons.info,
                    title: 'About ClassPulse',
                    subtitle: 'Version 1.0.0',
                    onTap: () => _showAboutDialog(context),
                  ),
                  _buildSettingsTile(
                    icon: Icons.feedback,
                    title: 'Send Feedback',
                    subtitle: 'Help us improve the app',
                    onTap: () => _showFeedbackDialog(context),
                  ),
                  _buildSettingsTile(
                    icon: Icons.description,
                    title: 'Terms & Conditions',
                    subtitle: 'Read our policies',
                    onTap: () => _showTermsDialog(context),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Danger Zone', isDanger: true),
                  const SizedBox(height: 12),
                  _buildDangerTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out from your account',
                    onTap: () => _showLogoutDialog(context),
                  ),
                  _buildDangerTile(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    subtitle: 'Permanently delete your account',
                    onTap: () => _showDeleteDialog(context),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {bool isDanger = false}) =>
      Text(title,
          style: TextStyle(
              color: isDanger ? const Color(0xFFEF5350) : const Color(0xFF2D5BFF),
              fontSize: 16,
              fontWeight: FontWeight.w700));

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2))
                          ]),
                      child: Row(children: [
                        Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                color: const Color(0xFF2D5BFF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(icon,
                                color: const Color(0xFF2D5BFF), size: 24)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(title,
                                  style: const TextStyle(
                                      color: Color(0xFF2D5BFF),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(subtitle,
                                  style: const TextStyle(
                                      color: Color(0xFF7A8BA3), fontSize: 12))
                            ])),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Color(0xFF7A8BA3))
                      ])))));

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) =>
      Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ]),
          child: Row(children: [
            Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                    color: const Color(0xFF2D5BFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: const Color(0xFF2D5BFF), size: 24)),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: const TextStyle(
                          color: Color(0xFF2D5BFF),
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: Color(0xFF7A8BA3), fontSize: 12))
                ])),
            Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF2D5BFF))
          ]));

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: const Color(0xFFEF5350).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFEF5350).withOpacity(0.2))),
                      child: Row(children: [
                        Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                                color: const Color(0xFFEF5350).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12)),
                            child: Icon(icon,
                                color: const Color(0xFFEF5350), size: 24)),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(title,
                                  style: const TextStyle(
                                      color: Color(0xFFEF5350),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(subtitle,
                                  style: TextStyle(
                                      color: const Color(0xFFEF5350)
                                          .withOpacity(0.7),
                                      fontSize: 12))
                            ])),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Color(0xFFEF5350))
                      ])))));

  void _showThemeBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.get(widget.language, 'choose_theme'),
                      style: const TextStyle(
                          color: Color(0xFF2D5BFF), fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  _themeOption(context, 'Light', 'light'),
                  _themeOption(context, 'Dark', 'dark'),
                  _themeOption(context, 'System', 'system'),
                  const SizedBox(height: 16),
                ])));
  }

  Widget _themeOption(BuildContext context, String label, String value) =>
      Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: () {
                    widget.onThemeChanged(value);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Theme changed to $label')));
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                          color: widget.theme == value
                              ? const Color(0xFF2D5BFF).withOpacity(0.1)
                              : Colors.white,
                          border: Border.all(
                              color: widget.theme == value
                                  ? const Color(0xFF2D5BFF)
                                  : const Color(0xFFECEFF1)),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(label,
                                style: const TextStyle(
                                    color: Color(0xFF2D5BFF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            if (widget.theme == value)
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF2D5BFF))
                          ])))));

  void _showLanguageBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (context) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24))),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppStrings.get(widget.language, 'choose_language'),
                      style: const TextStyle(
                          color: Color(0xFF2D5BFF), fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  _languageOption(context, 'English (US)', 'English (US)'),
                  _languageOption(context, 'Spanish', 'Spanish'),
                  _languageOption(context, 'French', 'French'),
                  _languageOption(context, 'Hindi', 'Hindi'),
                  const SizedBox(height: 16),
                ])));
  }

  Widget _languageOption(BuildContext context, String label, String value) =>
      Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: () {
                    widget.onLanguageChanged(value);
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Language changed to $label')));
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                          color: widget.language == value
                              ? const Color(0xFF2D5BFF).withOpacity(0.1)
                              : Colors.white,
                          border: Border.all(
                              color: widget.language == value
                                  ? const Color(0xFF2D5BFF)
                                  : const Color(0xFFECEFF1)),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(label,
                                style: const TextStyle(
                                    color: Color(0xFF2D5BFF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                            if (widget.language == value)
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF2D5BFF))
                          ])))));

  void _showProfileDialog(BuildContext context) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Profile'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person))),
                const SizedBox(height: 16),
                TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.email)))
              ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Profile updated successfully'),
                      backgroundColor: Color(0xFF4CAF50)));
                  Navigator.pop(context);
                },
                child: const Text('Save'))
          ]));

  void _showPasswordDialog(BuildContext context) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    decoration: InputDecoration(
                        labelText: 'Current Password',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.lock)),
                    obscureText: true),
                const SizedBox(height: 16),
                TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.lock)),
                    obscureText: true),
                const SizedBox(height: 16),
                TextField(
                    decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.lock)),
                    obscureText: true)
              ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: Color(0xFF4CAF50)));
                  Navigator.pop(context);
                },
                child: const Text('Update'))
          ]));

  void _showDownloadDialog(BuildContext context) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Download Manager'),
          content: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _downloadItem('Lecture Slides - Week 1', '45 MB'),
                    _downloadItem('Assignment PDF', '2.3 MB'),
                    _downloadItem('Sample Questions', '8.5 MB')
                  ])),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
          ]));

  Widget _downloadItem(String name, String size) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFF2D5BFF).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12)),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(name,
                      style: const TextStyle(
                          color: Color(0xFF2D5BFF), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(size,
                      style: const TextStyle(
                          color: Color(0xFF7A8BA3), fontSize: 12))
                ])),
            IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {},
                color: const Color(0xFFEF5350))
          ]));

  void _showStorageDialog(BuildContext context) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Storage Management'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                        minHeight: 12,
                        value: widget.storageUsed / 5,
                        backgroundColor: const Color(0xFFECEFF1),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF2D5BFF)))),
                const SizedBox(height: 12),
                Text('${widget.storageUsed.toStringAsFixed(1)} GB of 5 GB used',
                    style: const TextStyle(
                        color: Color(0xFF2D5BFF), fontWeight: FontWeight.w600)),
                const SizedBox(height: 20),
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFC107).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Text(
                        '💾 Cache: 245 MB\n📚 Downloaded: 1.2 GB\n🎥 Videos: 1 GB',
                        style: TextStyle(color: Color(0xFF7A8BA3), fontSize: 12)))
              ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  widget.onClearStorage();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Cache cleared successfully'),
                      backgroundColor: Color(0xFF4CAF50)));
                },
                child: const Text('Clear Cache', style: TextStyle(color: Color(0xFFEF5350))))
          ]));

  void _showDataPrivacyDialog(BuildContext context) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Data & Privacy'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _privacyItem('Share Analytics', true),
                _privacyItem('Share Learning Data', false),
                _privacyItem('Marketing Communications', false)
              ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))
          ]));

  Widget _privacyItem(String label, bool value) => Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Color(0xFF2D5BFF), fontSize: 13)),
            Switch(
                value: value,
                onChanged: (val) {},
                activeColor: const Color(0xFF2D5BFF))
          ]));

  void _showAboutDialog(BuildContext context) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('About ClassPulse'),
          content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF2D5BFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ClassPulse',
                              style: TextStyle(
                                  color: Color(0xFF2D5BFF),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 8),
                          Text(
                              'Version: 1.0.0\nDeveloped with ❤️ for students\n© 2026 ClassPulse. All rights reserved.',
                              style: TextStyle(
                                  color: Color(0xFF7A8BA3), fontSize: 12))
                        ]))
              ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
          ]));

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Send Feedback'),
            content: TextField(
                controller: feedbackController,
                maxLines: 4,
                decoration: InputDecoration(
                    hintText: 'Tell us what you think...',
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    feedbackController.dispose();
                  },
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Thank you for your feedback!'),
                        backgroundColor: Color(0xFF4CAF50)));
                    feedbackController.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('Send'))
            ]));
  }

  void _showTermsDialog(BuildContext context) =>
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Terms & Conditions'),
              content: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                            '1. User Agreement\nBy using ClassPulse, you agree to our terms and conditions.\n\n2. Educational Use\nThis platform is intended for educational purposes only.\n\n3. Privacy\nYour data is encrypted and secured.\n\n4. Intellectual Property\nAll content belongs to ClassPulse.',
                            style: TextStyle(
                                color: Color(0xFF7A8BA3), fontSize: 12, height: 1.6))
                      ])),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('I Agree'))
              ]));

  void _showLogoutDialog(BuildContext context) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully')));
                  Navigator.pop(context);
                  widget.onLogout();
                },
                child: const Text('Logout',
                    style: TextStyle(color: Color(0xFFEF5350))))
          ]));

  void _showDeleteDialog(BuildContext context) => showDialog(
      context: context,
      builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Delete Account'),
          content: const Text(
              'Are you sure you want to permanently delete your account? This action cannot be undone.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Account deleted successfully'),
                      backgroundColor: Color(0xFFEF5350)));
                  Navigator.pop(context);
                  widget.onLogout();
                },
                child: const Text('Delete', style: TextStyle(color: Color(0xFFEF5350))))
          ]));
}

