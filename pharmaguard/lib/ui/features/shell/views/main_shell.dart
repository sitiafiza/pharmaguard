import 'package:flutter/material.dart';
import '../../../../data/local_storage.dart';
import '../../dashboard/views/dashboard_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../../scan/views/scan_screen.dart';

// ==========================================
// WIDGET BINGKAI HP MELAYANG (MOCKUP)
// Catatan: Efek bingkai dinonaktifkan agar aplikasi berjalan Full-Screen.
// ==========================================
class FloatingPhoneMockup extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const FloatingPhoneMockup({super.key, required this.child, this.maxWidth = 420});

  static bool isInMockup(BuildContext context) {
    return context.findAncestorWidgetOfExactType<FloatingPhoneMockup>() != null;
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

// ==========================================
// KONTROL NAVIGASI BAWAH (BOTTOM BAR)
// ==========================================
class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});
  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode.value;

    // KUNCI PERBAIKAN: Memberikan ValueKey agar Beranda dipaksa Refresh saat jumlah obat bertambah!
    final List<Widget> pages = [
      HomeScreen(key: ValueKey('${mockMedicines.length}_${quarantinedMedicines.length}_$userProfileImageUrl')), 
      const SettingsScreen()
    ];
    
    return FloatingPhoneMockup(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
        body: pages[_currentIndex],
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF0D9488),
          onPressed: () async {
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanScreen()));
            // Jika hasil dari Scan adalah true (berhasil simpan), paksa refresh UI Navigasi!
            if (result == true) {
              setState(() {});
            }
          },
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
          child: const Icon(Icons.qr_code_scanner, color: Colors.white, size: 28),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10.0,
          elevation: 10,
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, 'Beranda', isDark), 
                const SizedBox(width: 40), 
                _buildNavItem(1, Icons.settings, 'Pengaturan', isDark)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? const Color(0xFF0D9488)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(icon, color: color, size: 26), 
            const SizedBox(height: 4), 
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
