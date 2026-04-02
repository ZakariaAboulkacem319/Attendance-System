import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'login_page.dart';
import 'student_page.dart';
import 'student_profile_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  Map<String, String>? _userInfo;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      final info = await _firestoreService.getUserInfo(uid);
      if (mounted) {
        setState(() {
          _userInfo = info;
        });
      }
    }
  }

  void _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
    );
  }

  void _scanPresence() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userInfo == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF9F2),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFEF7F1A)),
        ),
      );
    }

    final String userClass = _userInfo!['class'] ?? '';
    final String uid = _authService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _userInfo!['name'] ?? 'Étudiant',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (userClass.isNotEmpty)
              Text(
                userClass,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFFEF7F1A),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFFEF7F1A)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentProfilePage()),
              );
              if (result == true) {
                _loadUserInfo();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: userClass.isEmpty
          ? Center(
              child: Text(
                'Votre classe n\'est pas définie.\nVeuillez contacter l\'administration.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _firestoreService.getAllClassSessions(userClass),
              builder: (context, globalSnapshot) {
                if (globalSnapshot.hasError) {
                  return Center(
                    child: Text('Erreur Globale: ${globalSnapshot.error}',
                        style: const TextStyle(color: Colors.redAccent)),
                  );
                }
                if (globalSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFEF7F1A)));
                }

                final globalSessions = globalSnapshot.data?.docs ?? [];
                
                // Sort locally by creation date descending
                globalSessions.sort((a, b) {
                  final tsA = (a.data()['createdAt'] as Timestamp?)?.toDate();
                  final tsB = (b.data()['createdAt'] as Timestamp?)?.toDate();
                  if (tsA == null) return 1;
                  if (tsB == null) return -1;
                  return tsB.compareTo(tsA);
                });

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestoreService.getStudentAttendanceHistory(uid),
                  builder: (context, attendanceSnapshot) {
                    if (attendanceSnapshot.hasError) {
                      return Center(
                        child: Text('Erreur Présence: ${attendanceSnapshot.error}',
                            style: const TextStyle(color: Colors.redAccent)),
                      );
                    }
                    if (attendanceSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFEF7F1A)));
                    }

                    final attendances = attendanceSnapshot.data?.docs ?? [];

                    // Categorize sessions
                    final List<Map<String, dynamic>> presentSessions = [];
                    final List<Map<String, dynamic>> absentSessions = [];
                    final Set<String> matchedAttendanceDocIds = {};

                    // 1. Check current Global Sessions mapped to Attendance
                    for (var gDoc in globalSessions) {
                      final gData = gDoc.data();
                      final gSubj = (gData['subject'] ?? '').toString().trim();
                      final gDate = (gData['date'] ?? '').toString().trim();
                      final gStart = (gData['sessionStart'] ?? '').toString().trim();
                      final gToken = (gData['sessionToken'] ?? '').toString().trim();

                      bool isPresent = false;
                      for (var logDoc in attendances) {
                        final data = logDoc.data();
                        final pSubj = (data['subject'] ?? '').toString().trim();
                        final pDate = (data['date'] ?? '').toString().trim();
                        final pStart = (data['sessionStart'] ?? '').toString().trim();
                        final pToken = (data['sessionToken'] ?? '').toString().trim();

                        if (pSubj == gSubj && pDate == gDate && pStart == gStart && gDate.isNotEmpty) {
                          // If the global session has a token, the attendance MUST have the exact same token.
                          if (gToken.isEmpty || pToken == gToken) {
                            isPresent = true;
                            matchedAttendanceDocIds.add(logDoc.id);
                            break;
                          }
                        }
                      }

                      if (isPresent) {
                        presentSessions.add(gData);
                      } else {
                        absentSessions.add(gData);
                      }
                    }

                    // 2. Add Historical Attendances (before global sessions existed)
                    for (var logDoc in attendances) {
                      if (!matchedAttendanceDocIds.contains(logDoc.id)) {
                        final data = logDoc.data();
                        // Make sure we only show them if they pertain to the student's current class context
                        final pClass = (data['className'] ?? '').toString().trim();
                        if (pClass == userClass || pClass.isEmpty) {
                          presentSessions.add(data);
                        }
                      }
                    }

                    // Sort everything by date natively
                    int sortByDate(Map<String, dynamic> a, Map<String, dynamic> b) {
                      final dateA = (a['date'] ?? '').toString();
                      final dateB = (b['date'] ?? '').toString();
                      return dateB.compareTo(dateA); // Descending
                    }
                    presentSessions.sort(sortByDate);
                    absentSessions.sort(sortByDate);

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tableau de Bord',
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildStatCard(
                                        title: 'Présences',
                                        count: presentSessions.length,
                                        icon: Icons.check_circle_rounded,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildStatCard(
                                        title: 'Absences',
                                        count: absentSessions.length,
                                        icon: Icons.cancel_rounded,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: DefaultTabController(
                            length: 2,
                            child: Column(
                              children: [
                                TabBar(
                                  indicatorColor: const Color(0xFFEF7F1A),
                                  labelColor: const Color(0xFFEF7F1A),
                                  unselectedLabelColor: Colors.grey[500],
                                  labelStyle: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold),
                                  tabs: const [
                                    Tab(text: "Présences"),
                                    Tab(text: "Absences"),
                                  ],
                                ),
                                SizedBox(
                                  height: 400, // Fixed height for tabs
                                  child: TabBarView(
                                    children: [
                                      _buildSessionList(
                                          presentSessions, true),
                                      _buildSessionList(
                                          absentSessions, false),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanPresence,
        backgroundColor: const Color(0xFFEF7F1A),
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: Text(
          'Scanner ma présence',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionList(List<Map<String, dynamic>> sessions, bool isPresent) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Aucune séance correspondante',
              style: GoogleFonts.poppins(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final subject = session['subject'] ?? 'Matière';
        final date = session['date'] ?? '';
        final start = session['sessionStart'] ?? '';
        final end = session['sessionEnd'] ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isPresent
                  ? Colors.green.withOpacity(0.2)
                  : Colors.redAccent.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPresent
                      ? Colors.green.withOpacity(0.1)
                      : Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isPresent ? Icons.check_rounded : Icons.close_rounded,
                  color: isPresent ? Colors.green : Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$date • $start - $end',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
