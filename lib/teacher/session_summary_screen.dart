import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SessionSummaryScreen extends StatefulWidget {
  final String sessionCode;

  const SessionSummaryScreen({super.key, required this.sessionCode});

  @override
  State<SessionSummaryScreen> createState() => _SessionSummaryScreenState();
}

class _SessionSummaryScreenState extends State<SessionSummaryScreen> {
  late Future<Map<String, dynamic>?> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = apiService.getSessionSummary(widget.sessionCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Session Summary',
          style: TextStyle(
            color: Color(0xFF2D5BFF),
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2D5BFF)),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2D5BFF)));
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading summary: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _summaryFuture = apiService.getSessionSummary(widget.sessionCode);
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final summary = snapshot.data;
          if (summary == null || summary.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.analytics_outlined, color: Colors.grey, size: 48),
                  const SizedBox(height: 16),
                  const Text('No data found for this session.', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Dashboard'),
                  ),
                ],
              ),
            );
          }

          final int gotItCount = summary['gotItCount'] ?? 0;
          final int sortOfCount = summary['sortOfCount'] ?? 0;
          final int lostCount = summary['lostCount'] ?? 0;
          final int totalFeedbacks = gotItCount + sortOfCount + lostCount;
          
          final students = summary['totalStudents'] ?? 0;
          final duration = summary['durationMinutes'] ?? 0;
          final questionsCount = summary['questionCount'] ?? 0;
          final List<dynamic> questionsList = summary['questions'] ?? [];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero card
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2D5BFF), Color(0xFF5DADE2)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D5BFF).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.school, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Class Complete!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildHeroStat(Icons.people, '$students', 'Students'),
                            _buildHeroStat(Icons.timer, '${duration}m', 'Duration'),
                            _buildHeroStat(Icons.question_answer, '$questionsCount', 'Questions'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Feedback Breakdown
                  const Text(
                    'Comprehension Breakdown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D1B4E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: totalFeedbacks == 0
                        ? const Center(
                            child: Text(
                              'No feedback recorded.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBar('Got It', gotItCount, totalFeedbacks, const Color(0xFF4CAF50)),
                              const SizedBox(height: 12),
                              _buildBar('Sort Of', sortOfCount, totalFeedbacks, const Color(0xFFFFC107)),
                              const SizedBox(height: 12),
                              _buildBar('Lost', lostCount, totalFeedbacks, const Color(0xFFEF5350)),
                              const Divider(height: 30),
                              Row(
                                children: [
                                  const Icon(Icons.timeline, color: Colors.indigo, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      lostCount > 0
                                          ? 'Peak "Lost" signals observed in the final 10 mins of class.'
                                          : 'Students mostly followed along without getting lost.',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Questions List
                  const Text(
                    'Submitted Questions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D1B4E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  questionsList.isEmpty
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: const Center(
                            child: Text(
                              'No questions asked.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: questionsList.length,
                          itemBuilder: (context, index) {
                            final q = questionsList[index];
                            final isAnswered = q['isAnswered'] == true || q['is_answered'] == 1 || q['is_answered'] == true;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    isAnswered ? Icons.check_circle : Icons.help_outline,
                                    color: isAnswered ? Colors.green : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          q['text'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isAnswered ? 'Answered/Acknowledged' : 'Dismissed / Unanswered',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isAnswered ? Colors.green : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2D5BFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Dashboard', style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildBar(String label, int count, int total, Color color) {
    final double percentage = total == 0 ? 0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('$count (${(percentage * 100).toInt()}%)', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.15),
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
