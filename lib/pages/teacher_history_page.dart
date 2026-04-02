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
  DateTime _selectedDate = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFEF7F1A),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      appBar: AppBar(
        title: Text(
          'Historique - ${widget.subject}${widget.className != null ? ' (${widget.className})' : ''}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Color(0xFFEF7F1A)),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Date Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date sélectionnée',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF7F1A),
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: Text('Changer', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF7F1A).withValues(alpha: 0.1),
                    foregroundColor: const Color(0xFFEF7F1A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: firestoreService.getTeacherSessionsHistory(AuthService().currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFEF7F1A)));
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

                // Filter locally by selected date and subject
                final targetDate = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
                
                final allDocs = snapshot.data?.docs ?? [];
                final docs = allDocs.where((doc) {
                  final data = doc.data();
                  if (data['subject'] != widget.subject) return false;
                  
                  if (widget.className != null && widget.className!.isNotEmpty) {
                    if (data['className'] != widget.className) return false;
                  }

                  return data['date'] == targetDate;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune séance enregistrée\nce jour-là.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            color: Colors.grey[500],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    return _buildSessionTile(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionTile(Map<String, dynamic> sessionData) {
    final className = sessionData['className'] ?? '';
    final subject = sessionData['subject'] ?? '';
    final start = sessionData['sessionStart'] ?? '';
    final end = sessionData['sessionEnd'] ?? '';
    final date = sessionData['date'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03), 
            blurRadius: 10, 
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$subject - $className', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('Créneau : $start - $end', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFEF7F1A).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.school_rounded, color: Color(0xFFEF7F1A), size: 24),
        ),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
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
                if (studentsSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Color(0xFFEF7F1A))));
                }
                final sDocs = studentsSnap.data?.docs ?? [];
                if (sDocs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(child: Text('Aucun participant', style: GoogleFonts.poppins(color: Colors.grey))),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sDocs.length,
                  itemBuilder: (context, idx) {
                    final doc = sDocs[idx];
                    final uid = doc.id;
                    final ts = (doc['timestamp'] as Timestamp?)?.toDate();
                    return FutureBuilder<Map<String, String>>(
                      future: firestoreService.getUserInfo(uid),
                      builder: (context, infoSnap) {
                        final info = infoSnap.data ?? {'name': 'Chargement...', 'class': ''};
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.white, 
                            child: Icon(Icons.person, color: Colors.grey),
                          ),
                          title: Text(info['name']!, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                          trailing: Text(
                            ts != null ? '${ts.hour.toString().padLeft(2,'0')}:${ts.minute.toString().padLeft(2,'0')}' : '--:--',
                            style: GoogleFonts.poppins(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
