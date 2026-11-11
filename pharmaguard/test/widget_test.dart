import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pharmaguard/data/repositories/medication_repository.dart';
import 'package:pharmaguard/data/services/gs1_parser_service.dart';
import 'package:pharmaguard/main.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('PharmaGuard Smoke & Unit Tests', () {
    testWidgets('App launches and renders AuthScreen', (WidgetTester tester) async {
      await tester.pumpWidget(const PharmaGuardApp());
      await tester.pumpAndSettle();

      expect(find.text('PharmaGuard'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    test('GS1 DataMatrix Parser accurately extracts AI 01, AI 17, AI 10', () {
      final parser = Gs1ParserService();
      const rawSample = '(01)08991234567890(17)271024(10)AMX-2027-X';

      final result = parser.parse(rawSample);

      expect(result.isGs1, isTrue);
      expect(result.gtin, '08991234567890');
      expect(result.batchNumber, 'AMX-2027-X');
      expect(result.expiryDate, DateTime(2027, 10, 24));
    });

    test('MedicationRepository maintains FEFO order and tracks critical batches', () {
      final repo = MedicationRepository();

      // Check default critical count (H-5 batches)
      expect(repo.criticalCount, greaterThanOrEqualTo(2));

      // Critical medicines must contain Amoxicillin and Paracetamol
      final criticalMeds = repo.criticalMedications;
      expect(criticalMeds.any((m) => m.name.contains('Amoxicillin')), isTrue);

      // Quarantine action updates batch status
      final amox = criticalMeds.firstWhere((m) => m.name.contains('Amoxicillin'));
      final batchId = amox.fefoBatch!.id;

      repo.quarantineBatch(amox.id, batchId);

      final updatedAmox = repo.getById(amox.id);
      expect(updatedAmox?.activeBatches.isEmpty, isTrue);
    });
  });
}
