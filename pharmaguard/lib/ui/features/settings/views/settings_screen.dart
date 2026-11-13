import 'package:flutter/material.dart';
import '../../../../data/local_storage.dart';
import '../../auth/views/auth_screen.dart';
import '../../quarantine/quarantine_screen.dart';
import '../../history/history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isNotifEnabled = true;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode.value;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Pengaturan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        children: [
          // ==========================================
          // HEADER PROFIL
          // ==========================================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt, color: Color(0xFF0D9488)),
                                title: Text(
                                  'Ganti Foto Profil',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                onTap: () async {
                                  setState(() {
                                    userProfileImageUrl = 'https://i.pravatar.cc/150?img=47';
                                  });
                                  await saveData();
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.delete_outline, color: Colors.red),
                                title: const Text(
                                  'Hapus Foto Profil',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () async {
                                  setState(() {
                                    userProfileImageUrl = null;
                                  });
                                  await saveData();
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0xFFCCFBF1),
                        backgroundImage: userProfileImageUrl != null
                            ? NetworkImage(userProfileImageUrl!)
                            : null,
                        child: userProfileImageUrl == null
                            ? const Text(
                                'P',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D9488),
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF0D9488),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Apoteker Pija',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Apotek Sehat Medika',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==========================================
          // GRUP 1 - MANAJEMEN APOTEK
          // ==========================================
          _buildSectionHeader('MANAJEMEN APOTEK'),
          _buildGroupContainer(
            isDark: isDark,
            children: [
              _buildTile(
                icon: Icons.move_to_inbox_outlined,
                title: 'Kotak Karantina',
                subtitle: 'Obat kedaluwarsa & ditarik',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QuarantineScreen()),
                ),
              ),
              _buildDivider(isDark),
              _buildTile(
                icon: Icons.history_rounded,
                title: 'Riwayat Aktivitas',
                subtitle: 'Log mutasi & tindakan petugas',
                isDark: isDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                ),
              ),
            ],
          ),

          // ==========================================
          // GRUP 2 - PREFERENSI APLIKASI
          // ==========================================
          _buildSectionHeader('PREFERENSI APLIKASI'),
          _buildGroupContainer(
            isDark: isDark,
            children: [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFF0D9488),
                    size: 22,
                  ),
                ),
                title: Text(
                  'Notifikasi Kedaluwarsa',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  'Peringatan dini H-7 obat kritis',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                activeColor: const Color(0xFF0D9488),
                value: _isNotifEnabled,
                onChanged: (val) => setState(() => _isNotifEnabled = val),
              ),
              _buildDivider(isDark),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.dark_mode_outlined,
                    color: Color(0xFF0D9488),
                    size: 22,
                  ),
                ),
                title: Text(
                  'Mode Gelap',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  'Tema gelap untuk kenyamanan mata',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                activeColor: const Color(0xFF0D9488),
                value: isDark,
                onChanged: (val) async {
                  isDarkMode.value = val;
                  await saveData();
                  if (!mounted) return;
                  setState(() {});
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ==========================================
          // TOMBOL KELUAR AKUN
          // ==========================================
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: isDark
                    ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
                    : const Color(0xFFFEE2E2),
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              ),
              icon: const Icon(Icons.logout, color: Color(0xFFDC2626)),
              label: const Text(
                'Keluar Akun',
                style: TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 8, top: 22),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: Color(0xFF0D9488),
        ),
      ),
    );
  }

  Widget _buildGroupContainer({required List<Widget> children, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF0D9488), size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
      indent: 58,
      endIndent: 16,
    );
  }
}
