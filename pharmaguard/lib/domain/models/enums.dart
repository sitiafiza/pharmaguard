import 'package:flutter/material.dart';

enum ExpiryUrgency {
  critical, // <= 7 days (Merah Coral)
  warning,  // <= 30 days (Kuning)
  attention,// <= 90 days (Kuning-Oranye)
  safe,     // > 90 days (Hijau)
}

enum BatchStatus {
  active,
  quarantined,
  discarded,
}

enum MedicineCategory {
  all,
  critical,
  syrup,
  tablet,
  ointment,
  capsule,
}

extension MedicineCategoryExt on MedicineCategory {
  String get label {
    switch (this) {
      case MedicineCategory.all:
        return 'Semua';
      case MedicineCategory.critical:
        return 'Kritis H-7';
      case MedicineCategory.syrup:
        return 'Sirup';
      case MedicineCategory.tablet:
        return 'Tablet';
      case MedicineCategory.ointment:
        return 'Salep';
      case MedicineCategory.capsule:
        return 'Kapsul';
    }
  }

  IconData get icon {
    switch (this) {
      case MedicineCategory.all:
        return Icons.medical_services_outlined;
      case MedicineCategory.critical:
        return Icons.warning_amber_rounded;
      case MedicineCategory.syrup:
        return Icons.medication_liquid_outlined;
      case MedicineCategory.tablet:
        return Icons.medication_outlined;
      case MedicineCategory.ointment:
        return Icons.sanitizer_outlined;
      case MedicineCategory.capsule:
        return Icons.grain_outlined;
    }
  }
}
