import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/local_storage.dart';
import 'ui/features/auth/views/auth_screen.dart';
import 'ui/features/shell/views/main_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  try {
    await Supabase.initialize(
      url: 'https://rnxozjojpaalqukjgrvp.supabase.co',
      publishableKey: 'sb_publishable_zwubF11SFZ_BnecE0zMggQ_2CqUelXe',
    );
  } catch (e) {
    debugPrint('Supabase initialization error: $e');
  }

  await loadData();
  runApp(const PharmaGuardApp());
}

class PharmaGuardApp extends StatelessWidget {
  const PharmaGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isDarkMode,
      builder: (context, isDark, child) {
        return MaterialApp(
          title: 'PharmaGuard',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            primaryColor: const Color(0xFF0D9488),
            cardColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D9488),
              primary: const Color(0xFF0D9488),
              error: const Color(0xFFDC2626),
              surface: Colors.white,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF8FAFC),
              foregroundColor: Color(0xFF0F172A),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                fontFamily: 'Segoe UI',
              ),
            ),
            fontFamily: 'Segoe UI',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF0D9488),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0D9488),
              primary: const Color(0xFF0D9488),
              error: const Color(0xFFDC2626),
              surface: const Color(0xFF1E1E1E),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF121212),
              foregroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: false,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Segoe UI',
              ),
            ),
            fontFamily: 'Segoe UI',
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

// ==========================================
// PINTU GERBANG AUTENTIKASI (AUTH GATE)
// Memeriksa status sesi pengguna secara real-time via Supabase Auth
// ==========================================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    final client = supabaseClient;
    if (client != null) {
      _isAuthenticated = client.auth.currentSession != null;
      _authSubscription = client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        final hasSession = session != null;
        if (hasSession && !_isAuthenticated) {
          // Berhasil login: Muat ulang data terbaru dari Supabase
          await loadData();
        }
        if (mounted) {
          setState(() {
            _isAuthenticated = hasSession;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isAuthenticated ? const MainWrapper() : const AuthScreen();
  }
}
