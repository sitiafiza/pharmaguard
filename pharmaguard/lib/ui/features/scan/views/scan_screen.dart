import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../domain/models/medication.dart';
import '../../../../data/local_storage.dart';
import '../../shell/views/main_shell.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _batchController = TextEditingController();
  String _selectedType = 'Tablet/Kapsul';
  int _quantity = 10;
  late DateTime _expiryDate;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _expiryDate = DateTime.now().add(const Duration(days: 5));
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _doseController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  void _saveMedicine() async {
    final barcodeText = _barcodeController.text.trim();
    final nameText = _nameController.text.trim();
    final doseText = _doseController.text.trim();
    final batchText = _batchController.text.trim();

    final id = barcodeText.isNotEmpty
        ? barcodeText
        : '899${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    final name = nameText.isNotEmpty ? nameText : 'Obat Baru Terpindai';
    final dose = doseText.isNotEmpty ? doseText : 'Standar';
    final batch = batchText.isNotEmpty
        ? batchText
        : '#BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    final stock = _quantity > 0 ? _quantity : 1;

    final newMedicine = Medicine(
      id: id,
      name: name,
      dose: dose,
      type: _selectedType,
      location: 'Rak Utama',
      stock: stock,
      unit: 'Pcs',
      batch: batch,
      expiryDate: _expiryDate,
      progress: 0.85,
    );

    mockMedicines.add(newMedicine);
    activityLogs.insert(0, ActivityLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Obat Baru Ditambahkan',
        description: '$name sebanyak $stock ditambahkan ke sistem',
        timestamp: DateTime.now(),
        type: 'add',
      ),
    );
    await saveData();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Obat "$name" berhasil disimpan! Total stok bertambah.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );

    Navigator.pop(context, true);
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Widget _buildFloatingInput({required Widget child, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode.value;

    return FloatingPhoneMockup(
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Scan & Input Obat'),
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Viewfinder Kamera Melayang
              Container(
                height: 150,
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 6)),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_isScanning)
                      MobileScanner(
                        onDetect: (capture) {
                          final barcode = capture.barcodes.first;
                          if (barcode.rawValue != null) {
                            setState(() {
                              _barcodeController.text = barcode.rawValue!;
                              _isScanning = false;
                            });
                          }
                        }
                      )
                    else
                      const Text(
                        'Barcode Tersimpan!',
                        style: TextStyle(color: Color(0xFF10B981), fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    if (_isScanning)
                      Container(
                        width: 220,
                        height: 90,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF0D9488), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    if (_isScanning)
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 32),
                          SizedBox(height: 6),
                          Text(
                            'Arahkan Barcode GS1 DataMatrix',
                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Form Input Lengkap Melayang
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFloatingInput(
                        isDark: isDark,
                        child: TextField(
                          controller: _barcodeController,
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            labelText: 'Kode Barcode / GTIN',
                            labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13),
                            hintText: 'Contoh: 8991234567890',
                            hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
                            prefixIcon: const Icon(Icons.qr_code_rounded, color: Color(0xFF0D9488)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildFloatingInput(
                        isDark: isDark,
                        child: TextField(
                          controller: _nameController,
                          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            labelText: 'Nama Obat',
                            labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13),
                            hintText: 'Contoh: Paracetamol Sirup',
                            hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
                            prefixIcon: const Icon(Icons.medication_rounded, color: Color(0xFF0D9488)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFloatingInput(
                              isDark: isDark,
                              child: TextField(
                                controller: _doseController,
                                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  labelText: 'Dosis',
                                  labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13),
                                  hintText: 'Contoh: 125mg',
                                  hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
                                  prefixIcon: const Icon(Icons.scale_rounded, color: Color(0xFF0D9488)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFloatingInput(
                              isDark: isDark,
                              child: TextField(
                                controller: _batchController,
                                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                decoration: InputDecoration(
                                  labelText: 'Nomor Batch',
                                  labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13),
                                  hintText: 'Contoh: #BATCH',
                                  hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8), fontSize: 13),
                                  prefixIcon: const Icon(Icons.numbers_rounded, color: Color(0xFF0D9488)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildFloatingInput(
                        isDark: isDark,
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          isExpanded: true,
                          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          decoration: InputDecoration(
                            labelText: 'Kategori / Bentuk Sediaan',
                            labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13),
                            prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFF0D9488)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          items: const [
                            'Tablet/Kapsul', 'Cair/Sirup', 'Salep/Krim', 'Drops/Tetes', 'Injeksi/Infus', 'Suppositoria', 'Alkes/P3K', 'Nutrisi/Perawatan',
                          ].map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedType = val);
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Stepper Jumlah Numerik & Date Picker
                      Row(
                        children: [
                          Expanded(
                            child: _buildFloatingInput(
                              isDark: isDark,
                              child: Container(
                                height: 54,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF0D9488)),
                                      onPressed: () {
                                        if (_quantity > 0) setState(() => _quantity--);
                                      },
                                    ),
                                    Text(
                                      '$_quantity',
                                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0D9488)),
                                      onPressed: () => setState(() => _quantity++),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildFloatingInput(
                              isDark: isDark,
                              child: InkWell(
                                onTap: _pickExpiryDate,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  height: 54,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF0D9488)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat('dd/MM/yyyy').format(_expiryDate),
                                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                            ),
                                            const Text('(Uji Kritis H-7)', style: TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w700)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Tombol Simpan
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05), blurRadius: 16, offset: const Offset(0, -4)),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF0D9488).withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text(
                      'Simpan Data Obat',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    onPressed: _saveMedicine,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}