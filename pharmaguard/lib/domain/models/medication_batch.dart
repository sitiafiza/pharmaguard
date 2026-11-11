import 'package:intl/intl.dart';
import 'enums.dart';

class MedicationBatch {
  final String id;
  final String medicationId;
  final String batchNumber;
  final DateTime expiryDate;
  final int quantity;
  final String unit;
  final String rackLocation;
  final BatchStatus status;
  final DateTime createdAt;

  const MedicationBatch({
    required this.id,
    required this.medicationId,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.unit,
    required this.rackLocation,
    this.status = BatchStatus.active,
    required this.createdAt,
  });

  int get remainingDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return target.difference(today).inDays;
  }

  ExpiryUrgency get urgency {
    final days = remainingDays;
    if (days <= 7) return ExpiryUrgency.critical;
    if (days <= 30) return ExpiryUrgency.warning;
    if (days <= 90) return ExpiryUrgency.attention;
    return ExpiryUrgency.safe;
  }

  String get formattedExpiryDate {
    return DateFormat('d MMMM yyyy', 'id_ID').format(expiryDate);
  }

  String get urgencyBadgeText {
    final days = remainingDays;
    if (days < 0) return 'Kedaluwarsa';
    if (days == 0) return 'Hari Ini';
    if (days <= 7) return 'Sisa $days Hari';
    if (days <= 30) return 'Sisa $days Hari';
    return 'Aman ($days Hari)';
  }

  MedicationBatch copyWith({
    String? id,
    String? medicationId,
    String? batchNumber,
    DateTime? expiryDate,
    int? quantity,
    String? unit,
    String? rackLocation,
    BatchStatus? status,
    DateTime? createdAt,
  }) {
    return MedicationBatch(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      batchNumber: batchNumber ?? this.batchNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      rackLocation: rackLocation ?? this.rackLocation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
