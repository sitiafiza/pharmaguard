import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/medication.dart';
import '../../../../data/local_storage.dart';

// Helper Ikon Kategori Obat
IconData getCategoryIcon(String type) {
  switch (type) {
    case 'Cair/Sirup':
    case 'Drops/Tetes': return Icons.medication_liquid;
    case 'Alkes/P3K':
    case 'Injeksi/Infus': return Icons.medical_information;
    case 'Nutrisi/Perawatan': return Icons.child_care;
    case 'Suppositoria': return Icons.opacity;
    default: return Icons.medication;
  }
}

class DetailScreen extends StatelessWidget {
  final Medicine medicine;
  const DetailScreen({super.key, required this.medicine});

  @override
  Widget build(BuildContext context) {
    bool isCritical = medicine.remainingDays <= 7;
    bool isQuarantined = quarantinedMedicines.any((m) => m.id == medicine.id); 

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)), title: const Text('Rincian Obat', style: TextStyle(fontWeight: FontWeight.bold))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 90, height: 90, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)), child: Center(child: Icon(getCategoryIcon(medicine.type), size: 46, color: const Color(0xFF94A3B8)))), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(medicine.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))), const SizedBox(height: 10), Text('Sisa Stok: ${medicine.stock} Pcs', style: const TextStyle(fontSize: 14)), if (isQuarantined) Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)), child: const Text('Status: Di Karantina', style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold)))]))]),
            ),
            const SizedBox(height: 20),
            if (isCritical && !isQuarantined)
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Masa Kedaluwarsa Resmi:', style: TextStyle(color: Colors.white, fontSize: 14)), const SizedBox(height: 8), Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(DateFormat('dd MMM yyyy', 'id_ID').format(medicine.expiryDate), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: Text('SISA ${medicine.remainingDays} HARI', style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold)))])]))
            else if (!isQuarantined)
              Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(20)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Masa Kedaluwarsa Resmi:', style: TextStyle(color: Colors.white, fontSize: 14)), const SizedBox(height: 8), Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(DateFormat('dd MMM yyyy', 'id_ID').format(medicine.expiryDate), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)), const Spacer(), Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Text('AMAN', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)))])])),
            
            const SizedBox(height: 40),
            if (!isQuarantined) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0D9488), side: const BorderSide(color: Color(0xFF0D9488), width: 2), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        TextEditingController qtyController = TextEditingController();
                        return AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Keluarkan Obat', style: TextStyle(fontWeight: FontWeight.bold)),
                          content: TextField(controller: qtyController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Jumlah terjual', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
                              onPressed: () async {
                                int qty = int.tryParse(qtyController.text) ?? 0;
                                if (qty > 0) {
                                  medicine.stock -= qty;
                                  if (medicine.stock <= 0) mockMedicines.removeWhere((m) => m.id == medicine.id);
                                  
                                  // CATAT RIWAYAT KASIR
                                  activityLogs.insert(0, ActivityLog(id: DateTime.now().toString(), title: 'Stok Keluar (Terjual)', description: '${medicine.name} dikeluarkan sebanyak $qty Pcs', timestamp: DateTime.now(), type: 'sell'));
                                  
                                  await saveData();
                                  Navigator.pop(context); 
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stok dikurangi!'), backgroundColor: Color(0xFF0D9488)));
                                  Navigator.pop(context, true); 
                                }
                              },
                              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_bag_outlined), SizedBox(width: 10), Text('Keluarkan / Jual', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))]),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                  onPressed: () async {
                    mockMedicines.removeWhere((m) => m.id == medicine.id);
                    quarantinedMedicines.add(medicine);

                    // CATAT RIWAYAT KARANTINA
                    activityLogs.insert(0, ActivityLog(id: DateTime.now().toString(), title: 'Obat Dikarantina', description: '${medicine.name} ditarik dari etalase ke kotak karantina.', timestamp: DateTime.now(), type: 'quarantine'));

                    await saveData();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${medicine.name} ditarik!'), backgroundColor: const Color(0xFF0D9488)));
                    Navigator.pop(context, true); 
                  },
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.move_to_inbox), SizedBox(width: 10), Text('Tarik ke Karantina', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))]),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}