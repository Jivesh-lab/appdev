import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Singleton pattern (optional but recommended)
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ------------------------------------------------------------
  // 🔵 1. CREATE SESSION
  // ------------------------------------------------------------
  Future<String> createSession(String teacherId) async {
    final sessionRef = _db.collection('sessions').doc();

    await sessionRef.set({
      "session_id": sessionRef.id,
      "teacher_id": teacherId,
      "status": "active",
      "created_at": FieldValue.serverTimestamp(),
      "ended_at": null,
      "total_students": 0,
      "threshold": 0.4,
      "alert_triggered": false,
      "counts": {
        "got_it": 0,
        "sort_of": 0,
        "lost": 0,
      }
    });

    return sessionRef.id;
  }

  // ------------------------------------------------------------
  // 🔵 2. ADD STUDENT RESPONSE
  // ------------------------------------------------------------
  Future<void> submitResponse({
    required String sessionId,
    required String userId,
    required String type,
  }) async {
    final sessionRef = _db.collection("sessions").doc(sessionId);
    final responseRef = sessionRef.collection("responses").doc(userId);

    await responseRef.set({
      "user_id": userId,
      "session_id": sessionId,
      "type": type,
      "previous_type": null,
      "joined_at": FieldValue.serverTimestamp(),
      "updated_at": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ------------------------------------------------------------
  // 🔵 3. ADD QUESTION
  // ------------------------------------------------------------
  Future<void> addQuestion(String sessionId, String question) async {
    final qRef = _db
        .collection("sessions")
        .doc(sessionId)
        .collection("questions")
        .doc();

    await qRef.set({
      "question": question,
      "created_at": FieldValue.serverTimestamp(),
      "status": "active",
      "upvotes": 0,
    });
  }

  // ------------------------------------------------------------
  // 🔵 4. CREATE POLL
  // ------------------------------------------------------------
  Future<void> createPoll(String sessionId, String question, List<String> options) async {
    final pollRef = _db
        .collection("sessions")
        .doc(sessionId)
        .collection("polls")
        .doc();

    await pollRef.set({
      "question": question,
      "options": options,
      "votes": {
        for (int i = 0; i < options.length; i++) "option_${i + 1}": 0
      },
      "created_at": FieldValue.serverTimestamp(),
      "is_active": true,
    });
  }

  // ------------------------------------------------------------
  // 🔵 5. ADD ANALYTICS LOG
  // ------------------------------------------------------------
  Future<void> addAnalyticsLog(
    String sessionId, {
    required int gotIt,
    required int sortOf,
    required int lost,
  }) async {
    final logRef = _db
        .collection("sessions")
        .doc(sessionId)
        .collection("analytics")
        .doc();

    await logRef.set({
      "timestamp": FieldValue.serverTimestamp(),
      "counts": {
        "got_it": gotIt,
        "sort_of": sortOf,
        "lost": lost,
      }
    });
  }

  // ------------------------------------------------------------
  // 🔵 6. TEACHER WEEKLY STATS
  // ------------------------------------------------------------
  Future<void> setWeeklyStats({
    required String teacherId,
    required String week,
    required int sessions,
    required double avgConfusion,
    required String worstTopic,
    required String worstTimeSlot,
  }) async {
    final statsRef = _db.collection("teacher_stats").doc(teacherId);

    await statsRef.set({
      "week": week,
      "sessions": sessions,
      "avg_confusion": avgConfusion,
      "worst_topic": worstTopic,
      "worst_time_slot": worstTimeSlot,
    });
  }
}