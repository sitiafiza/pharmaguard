import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/local_storage.dart';
import '../../../../domain/models/medication.dart';
import '../shell/views/main_shell.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode.value;
    final sortedLogs = List<ActivityLog>.from(activityLogs)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return FloatingPhoneMockup(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Riwayat Aktivitas'),
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
          elevation: 0, scrolledUnderElevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.of(context).pop()),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF0D9488).withValues(alpha: 0.2) : const Color(0xFFCCFBF1), borderRadius: BorderRadius.circular(16)),
                  child: Text('${activityLogs.length} Catatan', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0D9488))),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: sortedLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: isDark ? const Color(0xFF262626) : const Color(0xFFF1F5F9), shape: BoxShape.circle), child: Icon(Icons.history_rounded, size: 52, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                      const SizedBox(height: 16),
                      Text('Belum Ada Riwayat Aktivitas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      const SizedBox(height: 6),
                      Text('Setiap mutasi stok obat akan tercatat otomatis di sini.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: sortedLogs.length,
                  itemBuilder: (context, index) {
                    final log = sortedLogs[index];
                    final config = _getLogConfig(log.type, isDark);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04), blurRadius: 14, offset: const Offset(0, 4))]),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 44, height: 44, decoration: BoxDecoration(color: config.bgColor, borderRadius: BorderRadius.circular(14)), child: Icon(config.icon, color: config.iconColor, size: 22)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text(log.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)))),
                                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: config.bgColor, borderRadius: BorderRadius.circular(8)), child: Text(config.tagLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: config.iconColor))),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(log.description, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569), height: 1.3)),
                                const SizedBox(height: 8),
                                Row(children: [const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)), const SizedBox(width: 4), Text(DateFormat('HH:mm • dd MMM yyyy', 'id_ID').format(log.timestamp), style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontWeight: FontWeight.w600))]),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  _LogConfig _getLogConfig(String type, bool isDark) {
    switch (type) {
      case 'add': return _LogConfig(icon: Icons.add_circle_outline_rounded, iconColor: const Color(0xFF0D9488), bgColor: isDark ? const Color(0xFF0D9488).withValues(alpha: 0.25) : const Color(0xFFCCFBF1), tagLabel: 'TAMBAH');
      case 'sell': return _LogConfig(icon: Icons.point_of_sale_rounded, iconColor: const Color(0xFF0284C7), bgColor: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.25) : const Color(0xFFE0F2FE), tagLabel: 'JUAL');
      case 'quarantine': return _LogConfig(icon: Icons.archive_outlined, iconColor: const Color(0xFFDC2626), bgColor: isDark ? const Color(0xFFDC2626).withValues(alpha: 0.25) : const Color(0xFFFEF2F2), tagLabel: 'KARANTINA');
      case 'delete':
      default: return _LogConfig(icon: Icons.delete_outline_rounded, iconColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), bgColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), tagLabel: 'HAPUS');
    }
  }
}

class _LogConfig {
  final IconData icon; final Color iconColor; final Color bgColor; final String tagLabel;
  _LogConfig({required this.icon, required this.iconColor, required this.bgColor, required this.tagLabel});
}