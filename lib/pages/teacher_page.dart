import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'login_page.dart';
import 'teacher_history_page.dart';

class TeacherPage extends StatefulWidget {
  const TeacherPage({super.key});

  @override
  State<TeacherPage> createState() => _TeacherPageState();
}

class _TeacherPageState extends State<TeacherPage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 30);
  
  final List<String> _subjects = [
    'Algorithmique',
    'Développement Web',
    'Base de Données',
    'Réseaux & Sécurité',
    'Intelligence Artificielle',
    'Systèmes d\'Exploitation',
  ];

  final List<String> _classes = [
    'Bachelor',
    'GI1',
    'GI2',
    'GI3',
  ];

  String _selectedSubject = 'Algorithmique';
  String _selectedClass = 'GI1';
  bool _sessionActive = false;
  late String _currentDate;
  String _currentSessionToken = '';

  @override
  void initState() {
    super.initState();
    _currentDate = DateTime.now().toIso8601String().split('T')[0];
  }

  String _formatTime(TimeOfDay time) {
    final hr = time.hour.toString().padLeft(2, '0');
    final mn = time.minute.toString().padLeft(2, '0');
    return '$hr:$mn';
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
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
    if (picked != null) {
      if (mounted) {
        setState(() {
          if (isStart) {
            _startTime = picked;
          } else {
            _endTime = picked;
          }
        });
      }
    }
  }

  String get _qrData {
    final start = _formatTime(_startTime);
    final end = _formatTime(_endTime);
    return '$_selectedSubject|$_selectedClass|$_currentDate|$start|$end|$_currentSessionToken';
  }

  void _logout() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
    );
  }

  void _toggleSession() async {
    if (!_sessionActive) {
      // Starting session
      try {
        final start = _formatTime(_startTime);
        final end = _formatTime(_endTime);
        _currentSessionToken = DateTime.now().millisecondsSinceEpoch.toString();
        await _firestoreService.createSession(
          subject: _selectedSubject,
          className: _selectedClass,
          date: _currentDate,
          sessionStart: start,
          sessionEnd: end,
          teacherId: _authService.currentUser?.uid ?? 'unknown',
          sessionToken: _currentSessionToken,
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
        return;
      }
    }
    setState(() => _sessionActive = !_sessionActive);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      appBar: AppBar(
        title: Text(
          'Espace Professeur',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFFEF7F1A)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherHistoryPage(
                    subject: _selectedSubject,
                    className: _selectedClass,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _firestoreService.getUserInfo(
          _authService.currentUser?.uid ?? '',
        ),
        builder: (context, nameSnapshot) {
          final teacherName = nameSnapshot.data?['name'] ?? 'Professeur';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Teacher greeting
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            const Color(0xFFEF7F1A).withValues(alpha: 0.12),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 30,
                          color: Color(0xFFEF7F1A),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour,',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            teacherName,
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'Gestion de séance',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Session Setup Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject Target Dropdown
                        Text(
                          'Matière enseignée',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedSubject,
                          icon: const Icon(Icons.menu_book_rounded),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFFCF7F1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          items: _subjects.map((String subject) {
                            return DropdownMenuItem<String>(
                              value: subject,
                              child: Text(subject),
                            );
                          }).toList(),
                          onChanged: _sessionActive
                              ? null
                              : (String? newValue) {
                                  if (newValue != null) {
                                    setState(() => _selectedSubject = newValue);
                                  }
                                },
                        ),
                        
                        const SizedBox(height: 24),

                        // Class Target Dropdown
                        Text(
                          'Classe concernée',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedClass,
                          icon: const Icon(Icons.people_alt_rounded),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFFCF7F1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          items: _classes.map((String className) {
                            return DropdownMenuItem<String>(
                              value: className,
                              child: Text(className),
                            );
                          }).toList(),
                          onChanged: _sessionActive
                              ? null
                              : (String? newValue) {
                                  if (newValue != null) {
                                    setState(() => _selectedClass = newValue);
                                  }
                                },
                        ),
                        
                        const SizedBox(height: 24),

                        // Time Pickers
                        Text(
                          'Créneau de la séance',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _sessionActive ? null : () => _selectTime(context, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCF7F1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, color: Colors.grey, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Début: ${_formatTime(_startTime)}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.black87,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: _sessionActive ? null : () => _selectTime(context, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCF7F1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_filled_rounded, color: Colors.grey, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Fin: ${_formatTime(_endTime)}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.black87,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Start/Stop Session Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _toggleSession,
                            icon: Icon(
                              _sessionActive
                                  ? Icons.stop_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                            ),
                            label: Text(
                              _sessionActive
                                  ? 'Arrêter la séance'
                                  : 'Démarrer la séance',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _sessionActive
                                  ? Colors.redAccent
                                  : const Color(0xFF4CAF50),
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // QR Code and Student List (only when session is active)
                  if (_sessionActive) ...[
                    const SizedBox(height: 30),

                    // QR Code Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Séance en direct',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.green[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedSubject,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Classe: $_selectedClass  •  ${_formatTime(_startTime)} - ${_formatTime(_endTime)}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: QrImageView(
                              data: _qrData,
                              version: QrVersions.auto,
                              size: 200.0,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFFEF7F1A),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Students Present Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Étudiants Présents',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'En temps réel',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Students Stream
                    StreamBuilder<QuerySnapshot>(
                      stream: _firestoreService.getAttendedStudentsStream(
                        _selectedSubject,
                        sessionStart: _formatTime(_startTime),
                        sessionEnd: _formatTime(_endTime),
                        className: _selectedClass,
                        date: _currentDate,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'En l\'attente des étudiants...',
                                    style: GoogleFonts.poppins(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final doc = docs[index];
                            final uid = doc.id;
                            final timestamp = (doc['timestamp'] as Timestamp?)?.toDate();

                            return FutureBuilder<Map<String, String>>(
                              future: _firestoreService.getUserInfo(uid),
                              builder: (context, infoSnapshot) {
                                final info = infoSnapshot.data ??
                                    {'name': 'Chargement...', 'class': ''};
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: const Color(0xFFEF7F1A).withValues(alpha: 0.12),
                                      child: const Icon(
                                        Icons.person_outline,
                                        color: Color(0xFFEF7F1A),
                                      ),
                                    ),
                                    title: Text(
                                      info['name']!,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (info['class']!.isNotEmpty)
                                          Text(
                                            info['class']!,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: const Color(0xFFEF7F1A),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        Text(
                                          timestamp != null
                                              ? '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
                                              : 'À l\'instant',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.greenAccent,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
