import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({super.key});

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  final List<String> _availableClasses = ['Bachelor', 'GI1', 'GI2'];
  String? _selectedClass;

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final uid = _authService.currentUser?.uid;
    if (uid != null) {
      final info = await _firestoreService.getUserInfo(uid);
      if (mounted) {
        setState(() {
          _firstNameController.text = info['firstName'] ?? '';
          _lastNameController.text = info['lastName'] ?? '';
          final currentClass = info['class'] ?? '';
          _selectedClass = _availableClasses.contains(currentClass)
              ? currentClass
              : null;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _selectedClass == null) {
      _showError('Veuillez remplir tous les champs et choisir une classe');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uid = _authService.currentUser?.uid;
      if (uid != null) {
        await _firestoreService.updateStudentProfile(
          uid: uid,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          userClass: _selectedClass!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate update
        }
      }
    } catch (e) {
      _showError('Erreur lors de la mise à jour : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF9F2),
      appBar: AppBar(
        title: Text(
          'Mon Profil',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFEF7F1A)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF7F1A).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Color(0xFFEF7F1A),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Informations Personnelles',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _firstNameController,
                    label: 'Prénom',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _lastNameController,
                    label: 'Nom',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),
                  _buildClassDropdown(),
                  const SizedBox(height: 40),
                  _isSaving
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFEF7F1A),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _saveProfile,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                            backgroundColor: const Color(0xFFEF7F1A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Enregistrer les modifications',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.poppins(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: const Color(0xFFEF7F1A)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildClassDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedClass,
        style: GoogleFonts.poppins(color: Colors.black87, fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Classe',
          labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
          prefixIcon: const Icon(Icons.class_outlined, color: Color(0xFFEF7F1A)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(15),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFEF7F1A)),
        items: _availableClasses.map((String className) {
          return DropdownMenuItem<String>(
            value: className,
            child: Text(
              className,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          );
        }).toList(),
        onChanged: (String? newValue) {
          setState(() => _selectedClass = newValue);
        },
        hint: Text(
          'Choisir une classe',
          style: GoogleFonts.poppins(color: Colors.grey[400]),
        ),
      ),
    );
  }
}
