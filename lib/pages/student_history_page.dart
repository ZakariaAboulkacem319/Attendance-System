import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class StudentHistoryPage extends StatelessWidget {
  const StudentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final uid = authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon historique')),
      body: uid == null
          ? const Center(child: Text('Utilisateur non connecté.'))
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firestoreService.getStudentAttendanceHistory(uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SelectableText(
                        'Erreur: ${snapshot.error}',
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Aucune présence enregistrée pour le moment.',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final subject =
                        (data['subject'] as String?) ?? 'Matière inconnue';
                    final timestamp = (data['timestamp'] as Timestamp?)
                        ?.toDate();
                    final dateText = timestamp == null
                        ? 'Date indisponible'
                        : '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} '
                              '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF4CAF50),
                        ),
                        title: Text(
                          subject,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          dateText,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
