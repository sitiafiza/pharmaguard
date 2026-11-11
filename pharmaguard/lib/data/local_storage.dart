import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Ini untuk menghubungkan data dengan Tahap 1 tadi:
import '../domain/models/medication.dart'; 

// ==========================================
// 1. VARIABEL GLOBAL (Penyimpan Data Sementara)
// ==========================================
List<Medicine> mockMedicines = [];
List<Medicine> quarantinedMedicines = [];
List<ActivityLog> activityLogs = [];
String? userProfileImageUrl;
ValueNotifier<bool> isDarkMode = ValueNotifier(false);

// ==========================================
// 2. KUNCI PENYIMPANAN MEMORI
// ==========================================
const String _keyMedicines = 'pharmaguard_medicines';
const String _keyQuarantined = 'pharmaguard_quarantined';
const String _keyActivityLogs = 'pharmaguard_activity_logs';
const String _keyIsDark = 'isDark';

// ==========================================
// 3. FUNGSI SIMPAN KE HARD DISK
// ==========================================
Future<void> saveData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final medicinesJson = mockMedicines
        .map((med) => jsonEncode(med.toJson()))
        .toList();
    final quarantinedJson = quarantinedMedicines
        .map((med) => jsonEncode(med.toJson()))
        .toList();
    final logsJson = activityLogs
        .map((log) => jsonEncode(log.toJson()))
        .toList();

    await prefs.setStringList(_keyMedicines, medicinesJson);
    await prefs.setStringList(_keyQuarantined, quarantinedJson);
    await prefs.setStringList(_keyActivityLogs, logsJson);
    await prefs.setBool(_keyIsDark, isDarkMode.value);
  } catch (e) {
    debugPrint('Gagal menyimpan data ke SharedPreferences: $e');
  }
}

// ==========================================
// 4. FUNGSI BACA DARI HARD DISK (SAAT APLIKASI DIBUKA)
// ==========================================
Future<void> loadData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final medicinesList = prefs.getStringList(_keyMedicines);
    final quarantinedList = prefs.getStringList(_keyQuarantined);
    final logsList = prefs.getStringList(_keyActivityLogs);
    final savedDark = prefs.getBool(_keyIsDark);

    if (savedDark != null) {
      isDarkMode.value = savedDark;
    }

    if (medicinesList != null) {
      mockMedicines = medicinesList
          .map((item) => Medicine.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    }

    if (quarantinedList != null) {
      quarantinedMedicines = quarantinedList
          .map((item) => Medicine.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    }

    if (logsList != null) {
      activityLogs = logsList
          .map((item) => ActivityLog.fromJson(jsonDecode(item) as Map<String, dynamic>))
          .toList();
    }
  } catch (e) {
    debugPrint('Gagal memuat data dari SharedPreferences: $e');
  }
}