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
      throw e.toString(); // Handle in UI
    }
  }

  // Mark attendance
  Future<void> markAttendance(String subject, String uid) async {
    try {
      final now = FieldValue.serverTimestamp();

      await _db
          .collection('attendance')
          .doc(subject)
          .collection('students')
          .doc(uid)
          .set({'present': true, 'subject': subject, 'timestamp': now});

      await _db.collection('attendance_logs').add({
        'uid': uid,
        'subject': subject,
        'timestamp': now,
      });
    } catch (e) {
      throw e.toString();
    }
  }

  // Get attended students stream
  Stream<QuerySnapshot> getAttendedStudentsStream(String subject) {
    return _db
        .collection('attendance')
        .doc(subject)
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
