import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../data/local_storage.dart';
import '../../shell/views/main_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _obs = true;
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _translateAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') || lower.contains('invalid_credentials')) {
      return 'Email atau kata sandi yang Anda masukkan salah.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Silakan periksa kotak masuk email Anda.';
    }
    if (lower.contains('user already registered') || lower.contains('already exists')) {
      return 'Email ini sudah terdaftar. Silakan masuk menggunakan email ini.';
    }
    if (lower.contains('password should be at least') || lower.contains('weak_password')) {
      return 'Kata sandi minimal harus 6 karakter.';
    }
    if (lower.contains('invalid email') || lower.contains('valid email')) {
      return 'Format email tidak valid. Masukkan format email yang benar.';
    }
    if (lower.contains('rate limit')) {
      return 'Terlalu banyak percobaan. Harap tunggu beberapa saat.';
    }
    return message;
  }

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Email dan kata sandi wajib diisi.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = supabaseClient;
      if (client == null) {
        throw 'Koneksi ke Supabase belum siap. Periksa koneksi internet Anda.';
      }

      if (_isLogin) {
        // Proses Login ke Supabase Auth
        await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } else {
        // Proses Registrasi Petugas Baru
        final fullName = _nameController.text.trim();
        final res = await client.auth.signUp(
          email: email,
          password: password,
          data: fullName.isNotEmpty ? {'full_name': fullName} : null,
        );
        if (res.session == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pendaftaran berhasil! Silakan periksa email untuk konfirmasi akun atau langsung masuk.'),
              backgroundColor: Color(0xFF0D9488),
            ),
          );
          setState(() {
            _isLogin = true;
            _isLoading = false;
          });
          return;
        }
      }

      // Berhasil masuk! Muat ulang data online dari Supabase
      await loadData();

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainWrapper()),
      );
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _translateAuthError(e.message);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode.value;

    return FloatingPhoneMockup(
      maxWidth: 480,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: _isLogin
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  onPressed: () {
                    setState(() {
                      _isLogin = true;
                      _errorMessage = null;
                    });
                  },
                ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.health_and_safety,
                  size: 80,
                  color: Color(0xFF0D9488),
                ),
                const SizedBox(height: 24),
                Text(
                  'PharmaGuard',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin ? 'Masuk ke Akun Apoteker' : 'Daftar Akun Petugas Baru',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 32),

                // Kotak Pesan Error (Berbahasa Indonesia)
                if (_errorMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Kolom Nama Lengkap (Hanya saat mode Daftar)
                if (!_isLogin) ...[
                  TextField(
                    controller: _nameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap',
                      labelStyle: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      prefixIcon: const Icon(Icons.badge, color: Color(0xFF0D9488)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF0D9488),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Kolom Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Alamat Email',
                    labelStyle: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    prefixIcon: const Icon(Icons.mail_outline, color: Color(0xFF0D9488)),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF0D9488),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Kolom Sandi
                TextField(
                  controller: _passwordController,
                  obscureText: _obs,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    labelStyle: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0D9488)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obs ? Icons.visibility_off : Icons.visibility,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      onPressed: () => setState(() => _obs = !_obs),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: Color(0xFF0D9488),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol Utama (Masuk / Daftar) dengan Indikator Loading
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                    ),
                    onPressed: _isLoading ? null : _handleAuth,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isLogin ? 'Masuk' : 'Daftar',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Tombol Alih Mode (Toggle Login/Register)
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _isLogin = !_isLogin;
                            _errorMessage = null;
                          }),
                  child: Text(
                    _isLogin
                        ? 'Belum punya akun? Daftar di sini'
                        : 'Sudah punya akun? Masuk di sini',
                    style: const TextStyle(
                      color: Color(0xFF0D9488),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
