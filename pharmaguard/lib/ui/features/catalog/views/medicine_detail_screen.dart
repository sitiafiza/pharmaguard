import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/repositories/medication_repository.dart';
import '../../../../domain/models/enums.dart';
import '../../../core/app_colors.dart';

class MedicineDetailScreen extends StatelessWidget {
  final String medicationId;

  const MedicineDetailScreen({
    super.key,
    required this.medicationId,
  });

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<MedicationRepository>();
    final med = repo.getById(medicationId);

    if (med == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rincian Obat')),
        body: const Center(child: Text('Data obat tidak ditemukan')),
      );
    }

    final fefoBatch = med.fefoBatch;
    final isCritical = med.hasCriticalBatch;
    final isQuarantined = fefoBatch == null && med.batches.any((b) => b.status == BatchStatus.quarantined);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rincian Obat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Card: Clean white card with soft shadow
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x06000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTealLight,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              med.category.icon,
                              size: 36,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            med.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            med.categoryDescription,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  med.defaultLocation,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Status Section: High-contrast alert container
                    if (isQuarantined)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Row(
                              children: [
                                Icon(Icons.archive_outlined, color: Color(0xFF475569)),
                                SizedBox(width: 8),
                                Text(
                                  'Status: Karantina Fisik',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Obat telah ditarik dari rak etalase. Siap untuk proses retur PBF atau pemusnahan resmi.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    else if (fefoBatch != null)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isCritical
                              ? AppColors.coralRedContainer
                              : fefoBatch.urgency == ExpiryUrgency.warning
                                  ? AppColors.warningYellowContainer
                                  : AppColors.safeGreenContainer,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCritical
                                ? AppColors.coralRedDark.withValues(alpha: 0.3)
                                : fefoBatch.urgency == ExpiryUrgency.warning
                                    ? AppColors.warningYellowDark.withValues(alpha: 0.3)
                                    : AppColors.safeGreenDark.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCritical ? Icons.warning_rounded : Icons.calendar_today_rounded,
                                  size: 20,
                                  color: isCritical
                                      ? AppColors.coralRedDark
                                      : fefoBatch.urgency == ExpiryUrgency.warning
                                          ? AppColors.warningYellowDark
                                          : AppColors.safeGreenDark,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Masa Kedaluwarsa Terdekat (FEFO)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isCritical
                                          ? AppColors.coralRedDark
                                          : fefoBatch.urgency == ExpiryUrgency.warning
                                              ? AppColors.warningYellowDark
                                              : AppColors.safeGreenDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${fefoBatch.formattedExpiryDate} (${fefoBatch.urgencyBadgeText})',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isCritical
                                    ? AppColors.coralRedDark
                                    : fefoBatch.urgency == ExpiryUrgency.warning
                                        ? AppColors.warningYellowDark
                                        : AppColors.safeGreenDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(height: 1, color: Colors.black12),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Sisa Stok di Rak:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${fefoBatch.quantity} ${fefoBatch.unit}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Nomor Batch: ${fefoBatch.batchNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Action Area (Two clear buttons)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                children: [
                  if (!isQuarantined && fefoBatch != null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coralRed,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        repo.quarantineBatch(med.id, fefoBatch.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.textPrimary,
                            content: Text(
                              '${med.name} (Batch: ${fefoBatch.batchNumber}) telah berhasil dipindahkan ke Karantina!',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.archive_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Tarik Obat dari Rak (Karantina)'),
                        ],
                      ),
                    ),
                  if (!isQuarantined && fefoBatch != null) const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mode edit data obat diaktifkan.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Edit Data Obat'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
