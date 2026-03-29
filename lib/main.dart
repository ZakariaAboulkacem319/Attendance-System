import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'pages/login_page.dart';
import 'pages/student_page.dart';
import 'pages/teacher_page.dart';
import 'pages/admin_page.dart';
import 'pages/role_selection_page.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  static const Color _primary = Color(0xFFEF7F1A);
  static const Color _secondary = Color(0xFFF4B000);
  static const Color _surfaceTint = Color(0xFFDFA15D);
  static const Color _onPrimary = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF2F231E);
  static const Color _textSecondary = Color(0xFF775B4B);
  static const Color _border = Color(0xFFE5D3C5);

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        primary: _primary,
        secondary: _secondary,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: _surfaceTint,
    );

    return MaterialApp(
      title: 'Attendance System',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
          bodyMedium: GoogleFonts.poppins(color: _textPrimary),
          titleMedium: GoogleFonts.poppins(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: _textPrimary,
          centerTitle: true,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: _border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(color: _textSecondary),
          prefixIconColor: _primary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _primary, width: 1.8),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _secondary,
            foregroundColor: _onPrimary,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 54),
            side: const BorderSide(color: _border),
            foregroundColor: _textPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: _textPrimary,
          contentTextStyle: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  User? _user;
  String? _role;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService.authStateChanges.listen((user) async {
      if (!mounted) return;
      if (user != null) {
        setState(() {
          _user = user;
          _isLoading = true;
        });
        final role = await _firestoreService.getUserRole(user.uid);
        if (mounted) {
          setState(() {
            _role = role;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _user = null;
          _role = null;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFFEF7F1A))),
      );
    }

    if (_user == null) {
      return const WelcomePage();
    }

    if (_role == 'student') {
      return const StudentPage();
    } else if (_role == 'teacher') {
      return const TeacherPage();
    } else if (_role == 'admin') {
      return const AdminPage();
    } else {
      return const RoleSelectionPage();
    }
  }
}
