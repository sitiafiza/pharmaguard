import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/local_storage.dart';
import '../../../../domain/models/medication.dart';
import '../shell/views/main_shell.dart';

class QuarantineScreen extends StatefulWidget {
  const QuarantineScreen({super.key});

  @override
  State<QuarantineScreen> createState() => _QuarantineScreenState();
}

class _QuarantineScreenState extends State<QuarantineScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode.value;

    return FloatingPhoneMockup(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Kotak Karantina Obat'),
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
          elevation: 0, scrolledUnderElevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20), onPressed: () => Navigator.of(context).pop()),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity, padding: const EdgeInsets.all(18), margin: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04), blurRadius: 14, offset: const Offset(0, 4))]),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: isDark ? const Color(0xFF3F1D1D) : Colors.white, shape: BoxShape.circle), child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFDC2626), size: 24)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total ${quarantinedMedicines.length} Obat Dikarantina', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B))),
                          const SizedBox(height: 2),
                          Text('Obat di bawah telah dipisahkan dari rak dan menunggu proses retur.', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: quarantinedMedicines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 56, color: Color(0xFF10B981)),
                            const SizedBox(height: 12),
                            Text('Kotak Karantina Kosong', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            Text('Tidak ada obat yang menunggu retur saat ini.', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: quarantinedMedicines.length,
                        itemBuilder: (context, index) {
                          final med = quarantinedMedicines[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04), blurRadius: 14, offset: const Offset(0, 4))]),
                            child: Row(
                              children: [
                                Container(width: 44, height: 44, decoration: BoxDecoration(color: isDark ? const Color(0xFF2A1515) : Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.archive_outlined, color: Color(0xFFDC2626), size: 22)),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${med.name} ${med.dose}', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                      const SizedBox(height: 3),
                                      Text('Batch: ${med.batch} • Stok: ${med.stock} ${med.unit}', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                                      const SizedBox(height: 2),
                                      Text('Kedaluwarsa: ${DateFormat('dd MMM yyyy', 'id_ID').format(med.expiryDate)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626))),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(color: isDark ? const Color(0xFF2A1515) : Colors.white, shape: BoxShape.circle),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete_rounded, color: Color(0xFFDC2626), size: 20),
                                    tooltip: 'Hapus Obat',
                                    onPressed: () async {
                                      final deletedName = med.name;
                                      setState(() => quarantinedMedicines.removeWhere((item) => item.id == med.id));
                                      activityLogs.add(ActivityLog(id: DateTime.now().millisecondsSinceEpoch.toString(), title: 'Retur Selesai / Dihapus', description: '$deletedName dihapus permanen dari sistem', timestamp: DateTime.now(), type: 'delete'));
                                      await saveData();
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Berhasil di Hapus'), backgroundColor: const Color(0xFFDC2626), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), duration: const Duration(seconds: 2)));
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}