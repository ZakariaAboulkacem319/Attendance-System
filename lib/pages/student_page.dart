import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'login_page.dart';
import 'confirmation_page.dart';
import 'student_history_page.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  late MobileScannerController _scannerController;

  bool _isProcessing = false;
  bool _hasPermission = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final status = await Permission.camera.request();
      if (mounted) {
        setState(() {
          _hasPermission = status.isGranted;
          _permissionChecked = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _permissionChecked = true;
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

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() => _isProcessing = true);
        _scannerController.stop();

        try {
          final user = _authService.currentUser;
          if (user != null) {
            // Parse QR data: "subject|startTime|endTime"
            final parts = code.split('|');
            final subject = parts[0];
            final sessionStart = parts.length > 1 ? parts[1] : '';
            final sessionEnd = parts.length > 2 ? parts[2] : '';

            // Check for duplicate scan
            if (sessionStart.isNotEmpty && sessionEnd.isNotEmpty) {
              final alreadyMarked = await _firestoreService.checkAlreadyMarked(
                subject: subject,
                uid: user.uid,
                sessionStart: sessionStart,
                sessionEnd: sessionEnd,
              );

              if (alreadyMarked) {
                if (!mounted) return;
                _showAlreadyMarkedDialog(subject);
                return;
              }
            }

            await _firestoreService.markAttendance(
              subject,
              user.uid,
              sessionStart: sessionStart.isNotEmpty ? sessionStart : null,
              sessionEnd: sessionEnd.isNotEmpty ? sessionEnd : null,
            );
            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ConfirmationPage(
                  subject: subject,
                  sessionStart: sessionStart.isNotEmpty ? sessionStart : null,
                  sessionEnd: sessionEnd.isNotEmpty ? sessionEnd : null,
                ),
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur : $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() => _isProcessing = false);
          _scannerController.start();
        }
      }
    }
  }

  void _showAlreadyMarkedDialog(String subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFEF7F1A),
            size: 40,
          ),
        ),
        title: Text(
          'Déjà enregistré !',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Vous avez déjà marqué votre présence pour cette séance de "$subject".',
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _isProcessing = false);
              _scannerController.start();
            },
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                color: const Color(0xFFEF7F1A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      appBar: AppBar(
        title: FutureBuilder<Map<String, String>>(
          future: _firestoreService.getUserInfo(uid),
          builder: (context, snapshot) {
            final name =
                snapshot.data?['name'] ??
                _authService.currentUser?.email ??
                'Étudiant';
            final userClass = snapshot.data?['class'] ?? '';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
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
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Color(0xFFEF7F1A)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StudentHistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Card
          FutureBuilder<Map<String, dynamic>>(
            future: _firestoreService.getStudentStats(uid),
            builder: (context, snapshot) {
              final stats = snapshot.data;
              final total = stats?['totalSessions'] ?? 0;
              final lastSubject = stats?['lastSubject'] ?? '';
              final lastDate = stats?['lastDate'] as DateTime?;

              return Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF7F1A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xFFEF7F1A),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$total présence${total > 1 ? 's' : ''}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          if (lastSubject.isNotEmpty)
                            Text(
                              'Dernière : $lastSubject${lastDate != null ? ' • ${lastDate.day.toString().padLeft(2, '0')}/${lastDate.month.toString().padLeft(2, '0')}' : ''}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          if (lastSubject.isEmpty)
                            Text(
                              'Aucune présence enregistrée',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
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

          // Scanner Area
          Expanded(
            child: !_permissionChecked
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFEF7F1A),
                    ),
                  )
                : !_hasPermission
                    ? _buildPermissionDenied()
                    : _buildScanner(),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_outlined,
                size: 60,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Accès caméra requis',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'L\'application a besoin d\'accéder à votre caméra pour scanner les codes QR de présence.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _permissionChecked = false);
                _scannerController = MobileScannerController();
                _initCamera();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Réessayer',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(controller: _scannerController, onDetect: _onDetect),
        Container(color: Colors.black.withValues(alpha: 0.28)),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: const Color(0xFFEF7F1A),
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.white, width: 4),
                            left: BorderSide(color: Colors.white, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      right: 20,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.white, width: 4),
                            right: BorderSide(color: Colors.white, width: 4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10),
                  ],
                ),
                child: Text(
                  'Scannez le code du prof',
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isProcessing)
          Container(
            color: Colors.white.withValues(alpha: 0.8),
            child: const Center(
              child: CircularProgressIndicator(color: Color(0xFFEF7F1A)),
            ),
          ),
      ],
    );
  }
}
