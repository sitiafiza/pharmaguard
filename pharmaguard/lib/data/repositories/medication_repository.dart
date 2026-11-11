import 'package:flutter/foundation.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/medication.dart';
import '../../domain/models/medication_batch.dart';

class MedicationRepository extends ChangeNotifier {
  final List<Medication> _medications = [];

  MedicationRepository() {
    _initializeDefaultData();
  }

  List<Medication> get medications => List.unmodifiable(_medications);

  /// Returns medications that contain at least one critical batch (<= 5 days)
  List<Medication> get criticalMedications {
    return _medications.where((m) => m.hasCriticalBatch).toList();
  }

  /// Total count of all medicines
  int get totalCount => _medications.length;

  /// Total count of critical batches
  int get criticalCount {
    int count = 0;
    for (final med in _medications) {
      count += med.activeBatches.where((b) => b.urgency == ExpiryUrgency.critical).length;
    }
    return count;
  }

  Medication? getById(String id) {
    try {
      return _medications.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Medication> search({
    String query = '',
    MedicineCategory category = MedicineCategory.all,
  }) {
    return _medications.where((med) {
      final matchesQuery = query.isEmpty ||
          med.name.toLowerCase().contains(query.toLowerCase()) ||
          med.gtin.contains(query);

      final matchesCategory = switch (category) {
        MedicineCategory.all => true,
        MedicineCategory.critical => med.hasCriticalBatch,
        _ => med.category == category,
      };

      return matchesQuery && matchesCategory;
    }).toList();
  }

  /// Changes a batch status to quarantined (Alur 1 / Prompt 2)
  void quarantineBatch(String medicationId, String batchId) {
    final medIndex = _medications.indexWhere((m) => m.id == medicationId);
    if (medIndex == -1) return;

    final med = _medications[medIndex];
    final updatedBatches = med.batches.map((batch) {
      if (batch.id == batchId) {
        return batch.copyWith(status: BatchStatus.quarantined);
      }
      return batch;
    }).toList();

    _medications[medIndex] = med.copyWith(batches: updatedBatches);
    notifyListeners();
  }

  /// Adds a new medication with its initial batch (Alur 2 / Prompt 3)
  void addMedication({
    required String gtin,
    required String name,
    required MedicineCategory category,
    required String location,
    required String batchNumber,
    required DateTime expiryDate,
    required int quantity,
    required String unit,
  }) {
    final now = DateTime.now();
    final medId = 'med_${now.millisecondsSinceEpoch}';
    final batchId = 'batch_${now.millisecondsSinceEpoch}';

    final batch = MedicationBatch(
      id: batchId,
      medicationId: medId,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
      quantity: quantity,
      unit: unit,
      rackLocation: location,
      createdAt: now,
    );

    final med = Medication(
      id: medId,
      gtin: gtin,
      name: name,
      category: category,
      categoryDescription: '${category.label} • $unit',
      defaultLocation: location,
      batches: [batch],
    );

    _medications.insert(0, med);
    notifyListeners();
  }

  void _initializeDefaultData() {
    final now = DateTime.now();

    // 1. Amoxicillin Sirup 125mg (Sisa 3 Hari)
    final amoxExpiry = now.add(const Duration(days: 3));
    final amox = Medication(
      id: 'med_1',
      gtin: '8991234567890',
      name: 'Amoxicillin Sirup 125mg',
      category: MedicineCategory.syrup,
      categoryDescription: 'Sirup Anak / Botol',
      defaultLocation: 'Etalase Depan (Rak A-02)',
      batches: [
        MedicationBatch(
          id: 'b_101',
          medicationId: 'med_1',
          batchNumber: 'AMX-2024-09',
          expiryDate: amoxExpiry,
          quantity: 8,
          unit: 'Botol',
          rackLocation: 'Rak Sirup • Rak A-02',
          createdAt: now.subtract(const Duration(days: 360)),
        ),
      ],
    );

    // 2. Paracetamol Tablet 500mg (Sisa 5 Hari)
    final pctExpiry = now.add(const Duration(days: 5));
    final pct = Medication(
      id: 'med_2',
      gtin: '8992345678901',
      name: 'Paracetamol Tablet 500mg',
      category: MedicineCategory.tablet,
      categoryDescription: 'Tablet Dewasa / Strip',
      defaultLocation: 'Rak B-01',
      batches: [
        MedicationBatch(
          id: 'b_102',
          medicationId: 'med_2',
          batchNumber: 'PCT-2024-11',
          expiryDate: pctExpiry,
          quantity: 12,
          unit: 'Strip',
          rackLocation: 'Rak Tablet • Rak B-01',
          createdAt: now.subtract(const Duration(days: 350)),
        ),
      ],
    );

    // 3. Salep Betametason (Sisa 18 Hari)
    final betaExpiry = now.add(const Duration(days: 18));
    final beta = Medication(
      id: 'med_3',
      gtin: '8993456789012',
      name: 'Salep Betametason',
      category: MedicineCategory.ointment,
      categoryDescription: 'Salep Topikal / Tube',
      defaultLocation: 'Rak D-02',
      batches: [
        MedicationBatch(
          id: 'b_103',
          medicationId: 'med_3',
          batchNumber: 'BTM-2025-01',
          expiryDate: betaExpiry,
          quantity: 5,
          unit: 'Tube',
          rackLocation: 'Rak Salep • 5 Tube',
          createdAt: now.subtract(const Duration(days: 200)),
        ),
      ],
    );

    // 4. Cetirizine Drops 10ml (Sisa 22 Hari)
    final cetiExpiry = now.add(const Duration(days: 22));
    final ceti = Medication(
      id: 'med_4',
      gtin: '8994567890123',
      name: 'Cetirizine Drops 10ml',
      category: MedicineCategory.syrup,
      categoryDescription: 'Tetes Alergi / Botol',
      defaultLocation: 'Rak A-05',
      batches: [
        MedicationBatch(
          id: 'b_104',
          medicationId: 'med_4',
          batchNumber: 'CTZ-2025-03',
          expiryDate: cetiExpiry,
          quantity: 15,
          unit: 'Botol',
          rackLocation: 'Rak A-05 • 15 Botol',
          createdAt: now.subtract(const Duration(days: 180)),
        ),
      ],
    );

    // 5. Omeprazole 20mg (Aman 180 Hari)
    final omepExpiry = now.add(const Duration(days: 180));
    final omep = Medication(
      id: 'med_5',
      gtin: '8995678901234',
      name: 'Omeprazole 20mg',
      category: MedicineCategory.capsule,
      categoryDescription: 'Kapsul Lambung / Strip',
      defaultLocation: 'Rak C-03',
      batches: [
        MedicationBatch(
          id: 'b_105',
          medicationId: 'med_5',
          batchNumber: 'OMP-2025-08',
          expiryDate: omepExpiry,
          quantity: 40,
          unit: 'Strip',
          rackLocation: 'Rak C-03 • 40 Strip',
          createdAt: now.subtract(const Duration(days: 60)),
        ),
      ],
    );

    // 6. Bioplacenton Gel (Aman 240 Hari)
    final bioExpiry = now.add(const Duration(days: 240));
    final bio = Medication(
      id: 'med_6',
      gtin: '8996789012345',
      name: 'Bioplacenton Gel',
      category: MedicineCategory.ointment,
      categoryDescription: 'Gel Luka Bakar / Tube',
      defaultLocation: 'Rak D-01',
      batches: [
        MedicationBatch(
          id: 'b_106',
          medicationId: 'med_6',
          batchNumber: 'BIO-2025-10',
          expiryDate: bioExpiry,
          quantity: 25,
          unit: 'Tube',
          rackLocation: 'Rak D-01 • 25 Tube',
          createdAt: now.subtract(const Duration(days: 30)),
        ),
      ],
    );

    _medications.addAll([amox, pct, beta, ceti, omep, bio]);
  }
}
