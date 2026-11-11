import 'package:flutter/material.dart';
import '../../../../domain/models/medication.dart';
import '../../../../data/local_storage.dart';
import '../../detail/views/detail_screen.dart';

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

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _selectedFilter = 'Semua';
  final List<String> _filters = ['Semua', 'Kritis', 'Tablet/Kapsul', 'Cair/Sirup', 'Salep/Krim', 'Drops/Tetes', 'Injeksi/Infus', 'Suppositoria', 'Alkes/P3K', 'Nutrisi/Perawatan'];

  @override
  Widget build(BuildContext context) {
    List<Medicine> displayedMeds = mockMedicines;
    if (_selectedFilter == 'Kritis') {
      displayedMeds = mockMedicines.where((m) => m.remainingDays <= 7).toList();
    } else if (_selectedFilter != 'Semua') {
      displayedMeds = mockMedicines.where((m) => m.type == _selectedFilter).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context, true)), title: const Text('Daftar Obat Aktif', style: TextStyle(fontWeight: FontWeight.bold))),
      body: Column(
        children: [
          Container(
            color: Colors.white, padding: const EdgeInsets.only(bottom: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: _filters.map((f) => Padding(padding: const EdgeInsets.only(right: 12), child: ChoiceChip(label: Text(f), selected: _selectedFilter == f, onSelected: (s) => setState(() => _selectedFilter = f), selectedColor: const Color(0xFF0D9488), backgroundColor: const Color(0xFFF1F5F9), labelStyle: TextStyle(color: _selectedFilter == f ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold)))).toList()),
            ),
          ),
          Expanded(
            child: displayedMeds.isEmpty ? const Center(child: Text("Tidak ada obat.", style: TextStyle(color: Colors.grey))) : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), itemCount: displayedMeds.length,
              itemBuilder: (context, index) {
                final med = displayedMeds[index];
                bool isCritical = med.remainingDays <= 7;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16), elevation: 6, shadowColor: Colors.black.withOpacity(0.1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(medicine: med))); if (result == true) setState(() {}); },
                    child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)), child: Icon(getCategoryIcon(med.type), color: const Color(0xFF94A3B8), size: 28)), const SizedBox(width: 20), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isCritical ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)), child: Text('Sisa ${med.remainingDays} Hari', style: TextStyle(color: isCritical ? const Color(0xFFDC2626) : const Color(0xFFD97706), fontSize: 11, fontWeight: FontWeight.bold)))]))])),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}