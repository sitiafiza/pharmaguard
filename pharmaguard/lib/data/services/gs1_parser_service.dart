class Gs1ParseResult {
  final String raw;
  final String? gtin;
  final String? batchNumber;
  final DateTime? expiryDate;
  final bool isGs1;

  const Gs1ParseResult({
    required this.raw,
    this.gtin,
    this.batchNumber,
    this.expiryDate,
    required this.isGs1,
  });
}

class Gs1ParserService {
  /// Parses standard GS1 DataMatrix string containing Application Identifiers (AI)
  /// Common formats:
  /// - Bracketed: "(01)08991234567890(17)271024(10)BATCH-A24"
  /// - Plain with AI prefixes: "01089912345678901727102410BATCH-A24"
  /// - Standard 1D Barcode fallback: "8991234567890"
  Gs1ParseResult parse(String rawInput) {
    final input = rawInput.trim();

    // Check bracketed format: (01)...(17)...(10)...
    if (input.contains('(01)') || input.contains('(17)') || input.contains('(10)')) {
      return _parseBracketedGs1(input);
    }

    // Check if it starts with 01 and has enough length for GS1 (01 + 14 digits)
    if (input.startsWith('01') && input.length >= 16) {
      return _parseUnbracketedGs1(input);
    }

    // Fallback: standard 1D linear barcode (EAN-13, UPC, etc.)
    return Gs1ParseResult(
      raw: input,
      gtin: input,
      batchNumber: null,
      expiryDate: null,
      isGs1: false,
    );
  }

  Gs1ParseResult _parseBracketedGs1(String input) {
    String? gtin;
    String? batchNumber;
    DateTime? expiryDate;

    final gtinMatch = RegExp(r'\(01\)(\d{14}|\d{13})').firstMatch(input);
    if (gtinMatch != null) {
      gtin = gtinMatch.group(1);
    }

    final expiryMatch = RegExp(r'\(17\)(\d{6})').firstMatch(input);
    if (expiryMatch != null) {
      expiryDate = _parseYYMMDD(expiryMatch.group(1)!);
    }

    final batchMatch = RegExp(r'\(10\)([A-Za-z0-9\-_]+)').firstMatch(input);
    if (batchMatch != null) {
      batchNumber = batchMatch.group(1);
    }

    return Gs1ParseResult(
      raw: input,
      gtin: gtin,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
      isGs1: true,
    );
  }

  Gs1ParseResult _parseUnbracketedGs1(String input) {
    String? gtin;
    String? batchNumber;
    DateTime? expiryDate;

    // AI 01 is 14 digits GTIN
    if (input.length >= 16) {
      gtin = input.substring(2, 16);
      int index = 16;

      while (index < input.length) {
        if (input.startsWith('17', index) && input.length >= index + 8) {
          final yymmdd = input.substring(index + 2, index + 8);
          expiryDate = _parseYYMMDD(yymmdd);
          index += 8;
        } else if (input.startsWith('10', index)) {
          // Batch number is variable length, up to 20 chars
          final remaining = input.substring(index + 2);
          batchNumber = remaining.split(RegExp(r'[\x1D\s]')).first;
          break;
        } else {
          index++;
        }
      }
    }

    return Gs1ParseResult(
      raw: input,
      gtin: gtin,
      batchNumber: batchNumber,
      expiryDate: expiryDate,
      isGs1: true,
    );
  }

  /// Parses YYMMDD into DateTime
  /// Example: 271024 -> 2027-10-24
  DateTime? _parseYYMMDD(String yymmdd) {
    if (yymmdd.length != 6) return null;
    try {
      final yearPart = int.parse(yymmdd.substring(0, 2));
      final month = int.parse(yymmdd.substring(2, 4));
      var day = int.parse(yymmdd.substring(4, 6));

      // Day 00 in GS1 means the last day of the month
      if (day == 0) {
        day = DateTime(2000 + yearPart, month + 1, 0).day;
      }

      final fullYear = 2000 + yearPart;
      return DateTime(fullYear, month, day);
    } catch (_) {
      return null;
    }
  }
}
