import 'package:flutter/material.dart';
import '../../../../data/local_storage.dart';
import '../../dashboard/views/dashboard_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../../scan/views/scan_screen.dart';

// ==========================================
// WIDGET BINGKAI HP MELAYANG (MOCKUP)
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
    if (isInMockup(context)) return child;
    final isDark = isDarkMode.value;

    return Container(
      width: double.infinity, height: double.infinity,
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: isDark ? const [Color(0xFF0F172A), Color(0xFF1E293B)] : const [Color(0xFFE0F2FE), Color(0xFFCCFBF1)])),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            width: double.infinity, height: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.15), blurRadius: 40, offset: const Offset(0, 15))],
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ),
    );
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
    // KUNCI PERBAIKAN: Memberikan ValueKey agar Beranda dipaksa Refresh saat jumlah obat bertambah!
    final List<Widget> pages = [
      HomeScreen(key: ValueKey('${mockMedicines.length}_${quarantinedMedicines.length}_$userProfileImageUrl')), 
      const SettingsScreen()
    ];
    
    return FloatingPhoneMockup(
      child: Scaffold(
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
          color: Colors.white,
          shape: const CircularNotchedRectangle(),
          notchMargin: 10.0,
          elevation: 10,
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_filled, 'Beranda'), 
                const SizedBox(width: 40), 
                _buildNavItem(1, Icons.settings, 'Pengaturan')
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? const Color(0xFF0D9488) : const Color(0xFF64748B);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Icon(icon, color: color, size: 26), 
            const SizedBox(height: 4), 
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal))
          ]
        ),
      ),
    );
  }
}