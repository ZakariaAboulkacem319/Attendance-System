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
            // Parse QR data: "subject|className|date|startTime|endTime"
            final parts = code.split('|');
            final subject = parts[0].trim();
            final qrClassName = parts.length > 1 ? parts[1].trim() : '';
            final qrDate = parts.length > 2 ? parts[2].trim() : '';
            final sessionStart = parts.length > 3 ? parts[3].trim() : '';
            final sessionEnd = parts.length > 4 ? parts[4].trim() : '';

            // 1) Verify student's class matches the session's class
            final userInfo = await _firestoreService.getUserInfo(user.uid);
            final userClass = userInfo['class'] ?? '';

            if (qrClassName.isNotEmpty && userClass != qrClassName) {
              if (!mounted) return;
              _showWrongClassDialog(subject, qrClassName, userClass);
              return;
            }

            // 2) Check for duplicate scan
            if (sessionStart.isNotEmpty && sessionEnd.isNotEmpty) {
              final alreadyMarked = await _firestoreService.checkAlreadyMarked(
                subject: subject,
                className: qrClassName,
                uid: user.uid,
                date: qrDate,
                sessionStart: sessionStart,
                sessionEnd: sessionEnd,
              );

              if (alreadyMarked) {
                if (!mounted) return;
                _showAlreadyMarkedDialog(subject);
                return;
              }
            }

            // 3) Mark attendance
            await _firestoreService.markAttendance(
              subject,
              qrClassName,
              qrDate,
              user.uid,
              sessionStart: sessionStart.isNotEmpty ? sessionStart : null,
              sessionEnd: sessionEnd.isNotEmpty ? sessionEnd : null,
            );
            if (!mounted) return;
            Navigator.pop(context); // Return to Dashboard
          }
        } catch (e) {
          setState(() => _isProcessing = false);
          _scannerController.start();
        }
      }
    }
  }

  void _showWrongClassDialog(
      String subject, String targetClass, String userClass) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.gpp_bad_rounded,
            color: Colors.redAccent,
            size: 40,
          ),
        ),
        title: Text(
          'Action non autorisée',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Cette séance de "$subject" est réservée à la classe "$targetClass".\n(Votre classe: "${userClass.isEmpty ? "Non définie" : userClass}")',
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
              'Fermer',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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
        title: Text(
          'Scanner un code QR',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
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
