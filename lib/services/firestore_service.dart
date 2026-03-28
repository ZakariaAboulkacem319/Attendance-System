import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return (doc.data() as Map<String, dynamic>)['role'] as String?;
      }
      return null;
    } catch (e) {
      throw e.toString();
    }
  }

  // Check if student already marked attendance for this session
  Future<bool> checkAlreadyMarked({
    required String subject,
    required String uid,
    required String sessionStart,
    required String sessionEnd,
  }) async {
    try {
      final query = await _db
          .collection('attendance_logs')
          .where('uid', isEqualTo: uid)
          .where('subject', isEqualTo: subject)
          .where('sessionStart', isEqualTo: sessionStart)
          .where('sessionEnd', isEqualTo: sessionEnd)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Mark attendance (session-aware)
  Future<void> markAttendance(
    String subject,
    String uid, {
    String? sessionStart,
    String? sessionEnd,
  }) async {
    try {
      final now = FieldValue.serverTimestamp();

      final sessionId = '${subject}_${sessionStart ?? "none"}_${sessionEnd ?? "none"}';

      await _db
          .collection('attendance')
          .doc(sessionId)
          .collection('students')
          .doc(uid)
          .set({
        'present': true,
        'subject': subject,
        'timestamp': now,
        'sessionStart': sessionStart ?? '',
        'sessionEnd': sessionEnd ?? '',
      });

      await _db.collection('attendance_logs').add({
        'uid': uid,
        'subject': subject,
        'timestamp': now,
        'sessionStart': sessionStart ?? '',
        'sessionEnd': sessionEnd ?? '',
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // Get attended students stream (session-aware)
  Stream<QuerySnapshot> getAttendedStudentsStream(
    String subject, {
    String? sessionStart,
    String? sessionEnd,
  }) {
    final sessionId = '${subject}_${sessionStart ?? "none"}_${sessionEnd ?? "none"}';
    return _db
        .collection('attendance')
        .doc(sessionId)
        .collection('students')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getStudentAttendanceHistory(
    String uid,
  ) {
    return _db
        .collection('attendance_logs')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSubjectAttendanceHistory(
    String subject,
  ) {
    return _db
        .collection('attendance_logs')
        .where('subject', isEqualTo: subject)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get student stats
  Future<Map<String, dynamic>> getStudentStats(String uid) async {
    try {
      final query = await _db
          .collection('attendance_logs')
          .where('uid', isEqualTo: uid)
          .orderBy('timestamp', descending: true)
          .get();

      if (query.docs.isEmpty) {
        return {'totalSessions': 0, 'lastSubject': '', 'lastDate': null};
      }

      final lastDoc = query.docs.first.data();
      final lastTimestamp = (lastDoc['timestamp'] as Timestamp?)?.toDate();

      return {
        'totalSessions': query.docs.length,
        'lastSubject': lastDoc['subject'] ?? '',
        'lastDate': lastTimestamp,
      };
    } catch (e) {
      return {'totalSessions': 0, 'lastSubject': '', 'lastDate': null};
    }
  }

  // Create user document
  Future<void> createUserDocument({
    required String uid,
    required String email,
    required String role,
    String? firstName,
    String? lastName,
    String? userClass,
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'email': email,
        'role': role,
        'firstName': firstName ?? '',
        'lastName': lastName ?? '',
        'userClass': userClass ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // Get user info (name and class)
  Future<Map<String, String>> getUserInfo(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        final firstName = data['firstName'] ?? '';
        final lastName = data['lastName'] ?? '';
        final userClass = data['userClass'] ?? '';
        final email = data['email'] ?? '';

        String name = '$firstName $lastName'.trim();
        if (name.isEmpty) name = email;

        return {'name': name, 'class': userClass};
      }
    } catch (e) {
      // ignore
    }
    return {'name': 'Inconnu', 'class': ''};
  }
}
