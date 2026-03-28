import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConfirmationPage extends StatelessWidget {
  final String subject;
  final String? sessionStart;
  final String? sessionEnd;

  const ConfirmationPage({
    super.key,
    required this.subject,
    this.sessionStart,
    this.sessionEnd,
  });

  @override
  Widget build(BuildContext context) {
    final hasSession =
        sessionStart != null &&
        sessionEnd != null &&
        sessionStart!.isNotEmpty &&
        sessionEnd!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEEDFD3), Color(0xFFFDF9F5)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.greenAccent,
                  size: 80,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'C\'est fait !',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Votre présence a été enregistrée avec succès.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF7F1A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEF7F1A).withValues(alpha: 0.24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Cours',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFFEF7F1A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subject,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (hasSession) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: Color(0xFFEF7F1A),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$sessionStart — $sessionEnd',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: Text(
                  'Retour',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
