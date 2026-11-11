import 'enums.dart';
import 'medication_batch.dart';

class Medication {
  final String id;
  final String gtin;
  final String name;
  final MedicineCategory category;
  final String categoryDescription;
  final String defaultLocation;
  final List<MedicationBatch> batches;

  const Medication({
    required this.id,
    required this.gtin,
    required this.name,
    required this.category,
    required this.categoryDescription,
    required this.defaultLocation,
    required this.batches,
  });

  List<MedicationBatch> get activeBatches =>
      batches.where((b) => b.status == BatchStatus.active).toList();

  bool get hasCriticalBatch =>
      activeBatches.any((b) => b.urgency == ExpiryUrgency.critical);

  MedicationBatch? get fefoBatch {
    if (activeBatches.isEmpty) return null;
    final sorted = List<MedicationBatch>.from(activeBatches)
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
    return sorted.first;
  }

  int get totalStock =>
      activeBatches.fold<int>(0, (sum, b) => sum + b.quantity);

  Medication copyWith({
    String? id,
    String? gtin,
    String? name,
    MedicineCategory? category,
    String? categoryDescription,
    String? defaultLocation,
    List<MedicationBatch>? batches,
  }) {
    return Medication(
      id: id ?? this.id,
      gtin: gtin ?? this.gtin,
      name: name ?? this.name,
      category: category ?? this.category,
      categoryDescription: categoryDescription ?? this.categoryDescription,
      defaultLocation: defaultLocation ?? this.defaultLocation,
      batches: batches ?? this.batches,
    );
  }
}

class Medicine {
  final String id;
  final String name;
  final String dose;
  final String type;
  final String location;
  int stock;
  final String unit;
  final String batch;
  final DateTime expiryDate;
  final double progress;

  Medicine({
    required this.id,
    required this.name,
    required this.dose,
    required this.type,
    required this.location,
    required this.stock,
    required this.unit,
    required this.batch,
    required this.expiryDate,
    required this.progress,
  });

  int get remainingDays => expiryDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dose': dose,
      'type': type,
      'location': location,
      'stock': stock,
      'unit': unit,
      'batch': batch,
      'expiryDate': expiryDate.toIso8601String(),
      'progress': progress,
    };
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      dose: json['dose'] as String? ?? '',
      type: json['type'] as String? ?? 'Tablet/Kapsul',
      location: json['location'] as String? ?? 'Rak Utama',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      unit: json['unit'] as String? ?? 'Pcs',
      batch: json['batch'] as String? ?? '',
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : DateTime.now(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ActivityLog {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String type; 

  ActivityLog({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
    };
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    return ActivityLog(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      type: json['type'] as String? ?? 'add',
    );
  }
}