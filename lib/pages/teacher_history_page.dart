import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class TeacherHistoryPage extends StatefulWidget {
  final String subject;
  final String? className;

  const TeacherHistoryPage({super.key, required this.subject, this.className});

  @override
  State<TeacherHistoryPage> createState() => _TeacherHistoryPageState();
}

class _TeacherHistoryPageState extends State<TeacherHistoryPage> {
  final firestoreService = FirestoreService();
  String? _filterSubject; // null = tous les modules

  @override
  Widget build(BuildContext context) {
    final uid = AuthService().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      appBar: AppBar(
        title: Text(
          'Historique des séances',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: firestoreService.getTeacherSessionsHistory(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFEF7F1A)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Erreur: ${snapshot.error}',
                  style: GoogleFonts.poppins(color: Colors.red),
                ),
              ),
            );
          }

          final allDocs = snapshot.data?.docs ?? [];

          // Sort locally by date descending
          allDocs.sort((a, b) {
            final tsA = (a.data()['createdAt'] as Timestamp?)?.toDate();
            final tsB = (b.data()['createdAt'] as Timestamp?)?.toDate();
            if (tsA == null) return 1;
            if (tsB == null) return -1;
            return tsB.compareTo(tsA);
          });

          // Extract unique subjects for filter chips
          final allSubjects = allDocs
              .map((d) => d.data()['subject']?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          // Apply subject filter
          final docs = _filterSubject == null
              ? allDocs
              : allDocs
                  .where((d) => d.data()['subject'] == _filterSubject)
                  .toList();

          return Column(
            children: [
              // Stats banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildStatBadge(
                      icon: Icons.event_note_rounded,
                      label: 'Total séances',
                      value: allDocs.length.toString(),
                      color: const Color(0xFFEF7F1A),
                    ),
                    const SizedBox(width: 16),
                    _buildStatBadge(
                      icon: Icons.menu_book_rounded,
                      label: 'Modules',
                      value: allSubjects.length.toString(),
                      color: Colors.blueAccent,
                    ),
                  ],
                ),
              ),

              // Filter chips by subject
              if (allSubjects.isNotEmpty)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // "Tous" chip
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(
                              'Tous',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: _filterSubject == null
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                            selected: _filterSubject == null,
                            selectedColor: const Color(0xFFEF7F1A),
                            backgroundColor: Colors.grey[100],
                            checkmarkColor: Colors.white,
                            onSelected: (_) =>
                                setState(() => _filterSubject = null),
                          ),
                        ),
                        ...allSubjects.map((subject) {
                          final isSelected = _filterSubject == subject;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(
                                subject,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: const Color(0xFFEF7F1A),
                              backgroundColor: Colors.grey[100],
                              checkmarkColor: Colors.white,
                              onSelected: (_) =>
                                  setState(() => _filterSubject = subject),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

              // Sessions list
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_rounded,
                                size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune séance trouvée.',
                              style: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final data = docs[index].data();
                          return _buildSessionTile(data);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionTile(Map<String, dynamic> sessionData) {
    final className = sessionData['className'] ?? '';
    final subject = sessionData['subject'] ?? '';
    final start = sessionData['sessionStart'] ?? '';
    final end = sessionData['sessionEnd'] ?? '';
    final date = sessionData['date'] ?? '';

    // Format date dd/MM/yyyy
    String formattedDate = date;
    try {
      final parts = date.split('-');
      if (parts.length == 3) {
        formattedDate = '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (_) {}

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEF7F1A).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.school_rounded,
              color: Color(0xFFEF7F1A), size: 24),
        ),
        title: Text(
          subject,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Classe : $className',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[600]),
            ),
            Text(
              '$formattedDate  •  $start - $end',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: const Color(0xFFEF7F1A)),
            ),
          ],
        ),
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getAttendedStudentsStream(
                subject,
                className: className,
                date: date,
                sessionStart: start,
                sessionEnd: end,
              ),
              builder: (context, studentsSnap) {
                if (studentsSnap.connectionState ==
                    ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFEF7F1A)),
                    ),
                  );
                }
                final sDocs = studentsSnap.data?.docs ?? [];

                if (sDocs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              color: Colors.grey[400], size: 20),
                          const SizedBox(width: 8),
                          Text('Aucun étudiant présent',
                              style: GoogleFonts.poppins(
                                  color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.people_rounded,
                              color: Colors.green, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${sDocs.length} étudiant(s) présent(s)',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Colors.green[700],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sDocs.length,
                      itemBuilder: (context, idx) {
                        final doc = sDocs[idx];
                        final uid = doc.id;
                        final ts =
                            (doc['timestamp'] as Timestamp?)?.toDate();
                        return FutureBuilder<Map<String, String>>(
                          future: firestoreService.getUserInfo(uid),
                          builder: (context, infoSnap) {
                            final info = infoSnap.data ??
                                {
                                  'name': 'Chargement...',
                                  'class': ''
                                };
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: const Color(0xFFEF7F1A)
                                    .withOpacity(0.1),
                                child: const Icon(Icons.person,
                                    color: Color(0xFFEF7F1A), size: 18),
                              ),
                              title: Text(
                                info['name']!,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                              subtitle: info['class']!.isNotEmpty
                                  ? Text(
                                      info['class']!,
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color:
                                              Colors.grey[500]),
                                    )
                                  : null,
                              trailing: Text(
                                ts != null
                                    ? '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}'
                                    : '--:--',
                                style: GoogleFonts.poppins(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
