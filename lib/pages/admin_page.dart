import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';
import '../services/auth_service.dart';
import 'login_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  final List<String> _subjects = [
    'Algorithmique',
    'Développement Web',
    'Base de Données',
    'Réseaux & Sécurité',
    'Intelligence Artificielle',
    'Systèmes d\'Exploitation',
  ];
  String _selectedSubject = 'Algorithmique';
  bool _isLoading = false;

  void _logout() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
    );
  }

  Future<void> _createTeacher() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() => _isLoading = true);
    FirebaseApp? secondaryApp;

    try {
      // Create a secondary app to avoid signing out the admin
      secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user?.uid;
      if (uid != null) {
        // Save to the MAIN auth's firestore database
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'role': 'teacher',
          'email': _emailController.text.trim(),
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'assignedSubject': _selectedSubject,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Professeur créé avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          _emailController.clear();
          _passwordController.clear();
          _firstNameController.clear();
          _lastNameController.clear();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      // Clean up secondary app
      if (secondaryApp != null) {
        await secondaryApp.delete();
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      appBar: AppBar(
        title: Text(
          'Espace Administrateur',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFEF7F1A).withValues(alpha: 0.12),
                  child: const Icon(
                    Icons.admin_panel_settings_rounded,
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
                      'Administrateur',
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
              'Créer un Professeur',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
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
                children: [
                  _buildTextField(
                    controller: _firstNameController,
                    label: 'Prénom',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Nom',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Mot de passe',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Matière enseignée',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedSubject,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
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
                      fontSize: 14,
                    ),
                    items: _subjects.map((String subject) {
                      return DropdownMenuItem<String>(
                        value: subject,
                        child: Text(subject),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => _selectedSubject = newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFEF7F1A),
                          ),
                        )
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _createTeacher,
                            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
                            label: Text(
                              'Créer le compte',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEF7F1A),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: GoogleFonts.poppins(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: const Color(0xFFEF7F1A), size: 20),
        filled: true,
        fillColor: const Color(0xFFFCF7F1),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
