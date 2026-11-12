import 'package:flutter/material.dart';
import '../../../../domain/models/medication.dart';
import '../../../../data/local_storage.dart';
import '../../detail/views/detail_screen.dart';
import '../../shell/views/main_shell.dart';

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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'Semua';
  final List<String> _filters = [
    'Semua',
    'Kritis',
    'Tablet/Kapsul',
    'Cair/Sirup',
    'Salep/Krim',
    'Drops/Tetes',
    'Injeksi/Infus',
    'Suppositoria',
    'Alkes/P3K',
    'Nutrisi/Perawatan',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode.value;
    final query = _searchQuery.trim().toLowerCase();

    // Logika Filter Ganda: Nama Obat (Search Bar) & Kategori
    List<Medicine> displayedMeds = mockMedicines.where((med) {
      final matchesSearch = query.isEmpty || med.name.toLowerCase().contains(query);
      bool matchesCategory = true;
      if (_selectedFilter == 'Kritis') {
        matchesCategory = med.remainingDays <= 7;
      } else if (_selectedFilter != 'Semua') {
        matchesCategory = med.type == _selectedFilter;
      }
      return matchesSearch && matchesCategory;
    }).toList();

    return FloatingPhoneMockup(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF1F5F9),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context, true),
          ),
          title: Text(
            'Daftar Obat Aktif',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        body: Column(
          children: [
            // Container Header: Search Bar & Filter Kategori
            Container(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                children: [
                  // 1. Kolom Pencarian Obat (Search Bar)
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Cari nama obat...',
                      hintStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF0D9488)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: isDark ? Colors.white70 : Colors.grey),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Deretan Tombol Filter Kategori (ChoiceChip)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filters.map((f) {
                        final isSelected = _selectedFilter == f;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: isSelected,
                            onSelected: (s) => setState(() => _selectedFilter = f),
                            selectedColor: const Color(0xFF0D9488),
                            backgroundColor: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              fontWeight: FontWeight.bold,
                            ),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Daftar Obat / Hasil Filter
            Expanded(
              child: displayedMeds.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'Obat "$_searchQuery" tidak ditemukan.'
                            : 'Tidak ada obat.',
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: displayedMeds.length,
                      itemBuilder: (context, index) {
                        final med = displayedMeds[index];
                        bool isCritical = med.remainingDays <= 7;
                        return Card(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: isDark ? 2 : 6,
                          shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => DetailScreen(medicine: med)),
                              );
                              if (result == true) setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF2D3748) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      getCategoryIcon(med.type),
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          med.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isCritical
                                                ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
                                                : (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7)),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Sisa ${med.remainingDays} Hari',
                                            style: TextStyle(
                                              color: isCritical
                                                  ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
                                                  : (isDark ? const Color(0xFFFDE68A) : const Color(0xFFD97706)),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
