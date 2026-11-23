import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/medication.dart';
import 'services/alarm_service.dart';

// ==========================================
// 1. VARIABEL GLOBAL (Penyimpan Data Sementara)
// ==========================================
List<Medicine> mockMedicines = [];
List<Medicine> quarantinedMedicines = [];
List<ActivityLog> activityLogs = [];
String? userProfileImageUrl;
ValueNotifier<bool> isDarkMode = ValueNotifier(false);
ValueNotifier<bool> isNotificationEnabled = ValueNotifier(true);
ValueNotifier<int> medicinesUpdateNotifier = ValueNotifier<int>(0);
ValueNotifier<bool> isCriticalMultiSelectModeNotifier = ValueNotifier<bool>(false);

// ==========================================
// 2. KUNCI PENYIMPANAN MEMORI
// ==========================================
const String _keyMedicines = 'pharmaguard_medicines';
const String _keyQuarantined = 'pharmaguard_quarantined';
const String _keyActivityLogs = 'pharmaguard_activity_logs';
const String _keyIsDark = 'isDark';
const String _keyIsNotif = 'isNotificationEnabled';
const String _keyProfileImage = 'userProfileImageUrl';
const String _keySyncedLogIds = 'pharmaguard_synced_log_ids';

// Helper akses Supabase Client secara aman
SupabaseClient? get supabaseClient {
  try {
    return Supabase.instance.client;
  } catch (_) {
    return null;
  }
}

// ==========================================
// 3. FUNGSI SIMPAN DATA (LOKAL & ONLINE SUPABASE)
// ==========================================
Future<void> saveData() async {
  // 1. Simpan ke SharedPreferences (Offline-first & Instan)
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
    await prefs.setBool(_keyIsNotif, isNotificationEnabled.value);

    if (userProfileImageUrl != null) {
      await prefs.setString(_keyProfileImage, userProfileImageUrl!);
    } else {
      await prefs.remove(_keyProfileImage);
    }
  } catch (e) {
    debugPrint('Gagal menyimpan data ke SharedPreferences: $e');
  }

  // 2. Sinkronisasi Online ke Supabase
  final client = supabaseClient;
  if (client != null) {
    try {
      // a. Simpan Foto Profil & Info Pengguna ke tabel 'profiles'
      await client.from('profiles').upsert({
        'id': 'main_user',
        'full_name': 'Apoteker Pija',
        'pharmacy_name': 'Apotek Sehat Medika',
        'profile_image': userProfileImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // b. Sinkronisasi Data Obat ke tabel 'medicines'
      await _pushMedicinesToSupabase(client);

      // c. Sinkronisasi Riwayat Aktivitas ke tabel 'activity_logs'
      await _pushLogsToSupabase(client);
    } catch (e) {
      debugPrint('Gagal menyinkronkan data ke Supabase: $e');
    }
  }

  medicinesUpdateNotifier.value++;
}

// ==========================================
// 4. FUNGSI BACA DATA (LOKAL & SINKRONISASI SUPABASE)
// ==========================================
Future<void> loadData() async {
  // 1. Muat dari SharedPreferences terlebih dahulu agar aplikasi langsung tampil
  try {
    final prefs = await SharedPreferences.getInstance();
    final medicinesList = prefs.getStringList(_keyMedicines);
    final quarantinedList = prefs.getStringList(_keyQuarantined);
    final logsList = prefs.getStringList(_keyActivityLogs);
    final savedDark = prefs.getBool(_keyIsDark);
    final savedNotif = prefs.getBool(_keyIsNotif);
    final savedProfileImg = prefs.getString(_keyProfileImage);

    if (savedDark != null) {
      isDarkMode.value = savedDark;
    }
    if (savedNotif != null) {
      isNotificationEnabled.value = savedNotif;
    }
    if (savedProfileImg != null && savedProfileImg.isNotEmpty) {
      userProfileImageUrl = savedProfileImg;
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

  // 2. Tarik Data Terbaru dari Supabase (Online Sync)
  final client = supabaseClient;
  if (client != null) {
    try {
      // a. Ambil Profil dari tabel 'profiles'
      final profileData = await client
          .from('profiles')
          .select()
          .eq('id', 'main_user')
          .maybeSingle();

      if (profileData != null) {
        final onlineImg = profileData['profile_image'] as String?;
        if (onlineImg != null && onlineImg.isNotEmpty) {
          userProfileImageUrl = onlineImg;
        }
      } else {
        // Buat profil default di Supabase jika belum ada
        await client.from('profiles').upsert({
          'id': 'main_user',
          'full_name': 'Apoteker Pija',
          'pharmacy_name': 'Apotek Sehat Medika',
          'profile_image': userProfileImageUrl,
        });
      }

      // b. Ambil Data Obat dari tabel 'medicines'
      final List<dynamic> remoteMeds = await client.from('medicines').select();
      if (remoteMeds.isNotEmpty) {
        final List<Medicine> activeList = [];
        final List<Medicine> qList = [];

        for (final item in remoteMeds) {
          final row = item as Map<String, dynamic>;
          final id = row['id']?.toString() ?? '';
          final name = row['name'] as String? ?? 'Obat';
          final barcode = row['barcode'] as String? ?? '';
          final category = row['category'] as String? ?? 'Tablet/Kapsul';
          final stock = (row['stock'] as num?)?.toInt() ?? 0;
          final expStr = row['expiry_date'] as String?;
          final expiryDate = expStr != null
              ? (DateTime.tryParse(expStr) ?? DateTime.now())
              : DateTime.now();
          final isQuarantined = row['is_quarantined'] == true;

          // Pertahankan metadata lokal (dosis, lokasi, unit) jika ada
          final localExisting = mockMedicines
              .where((m) => m.id == id)
              .followedBy(quarantinedMedicines.where((m) => m.id == id))
              .firstOrNull;

          final med = Medicine(
            id: id,
            name: name,
            dose: localExisting?.dose ?? 'Standar',
            type: category,
            location: localExisting?.location ?? 'Rak Utama',
            stock: stock,
            unit: localExisting?.unit ?? 'Pcs',
            batch: barcode.isNotEmpty ? barcode : (localExisting?.batch ?? '#BATCH-1'),
            expiryDate: expiryDate,
            progress: localExisting?.progress ?? 0.85,
          );

          if (isQuarantined) {
            qList.add(med);
          } else {
            activeList.add(med);
          }
        }

        mockMedicines = activeList;
        quarantinedMedicines = qList;
        medicinesUpdateNotifier.value++;
        // KUNCI: Alarm otomatis dipanggil tepat setelah data obat selesai dimuat dari Supabase!
        AlarmService.instance.checkAndPlayAlarm();
      } else if (mockMedicines.isNotEmpty || quarantinedMedicines.isNotEmpty) {
        // Supabase masih kosong, unggah data lokal ke Supabase
        await _pushMedicinesToSupabase(client);
        medicinesUpdateNotifier.value++;
        AlarmService.instance.checkAndPlayAlarm();
      }

      // c. Ambil Riwayat Aktivitas dari tabel 'activity_logs'
      final List<dynamic> remoteLogs = await client
          .from('activity_logs')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      if (remoteLogs.isNotEmpty) {
        activityLogs = remoteLogs.map((item) {
          final row = item as Map<String, dynamic>;
          final action = row['action'] as String? ?? 'Aktivitas';
          final desc = row['description'] as String? ?? '';
          final createdAt = row['created_at'] != null
              ? DateTime.tryParse(row['created_at'].toString()) ?? DateTime.now()
              : DateTime.now();
          final id = row['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

          return ActivityLog(
            id: id,
            title: action,
            description: desc,
            timestamp: createdAt,
            type: _mapActionToType(action),
          );
        }).toList();
      } else if (activityLogs.isNotEmpty) {
        // Supabase masih kosong, unggah riwayat lokal ke Supabase
        await _pushLogsToSupabase(client);
      }
    } catch (e) {
      debugPrint('Gagal menyelaraskan data dengan Supabase: $e');
    }
  }

  // Notifikasi perubahan data obat dan panggil alarm jika ada obat kritis
  medicinesUpdateNotifier.value++;
  AlarmService.instance.checkAndPlayAlarm();
}

// ==========================================
// 5. HELPER UNTUK MENGIRIM DATA KE SUPABASE
// ==========================================
Future<void> _pushMedicinesToSupabase(SupabaseClient client) async {
  final allRows = <Map<String, dynamic>>[];
  final currentIds = <String>[];

  for (final m in mockMedicines) {
    currentIds.add(m.id);
    allRows.add({
      'id': m.id,
      'name': m.name,
      'barcode': m.batch,
      'category': m.type,
      'stock': m.stock,
      'expiry_date': m.expiryDate.toIso8601String().split('T').first,
      'is_quarantined': false,
    });
  }

  for (final m in quarantinedMedicines) {
    currentIds.add(m.id);
    allRows.add({
      'id': m.id,
      'name': m.name,
      'barcode': m.batch,
      'category': m.type,
      'stock': m.stock,
      'expiry_date': m.expiryDate.toIso8601String().split('T').first,
      'is_quarantined': true,
    });
  }

  if (allRows.isNotEmpty) {
    await client.from('medicines').upsert(allRows);
    // Hapus obat yang sudah dihapus permanen dari sistem
    await client.from('medicines').delete().not('id', 'in', currentIds);
  } else {
    await client.from('medicines').delete().neq('id', '');
  }
}

Future<void> _pushLogsToSupabase(SupabaseClient client) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> syncedIds = prefs.getStringList(_keySyncedLogIds) ?? [];

  for (final log in activityLogs) {
    if (!syncedIds.contains(log.id)) {
      try {
        await client.from('activity_logs').insert({
          'action': log.title,
          'description': log.description,
          'actor': 'Apoteker Pija',
          'created_at': log.timestamp.toIso8601String(),
        });
        syncedIds.add(log.id);
      } catch (e) {
        debugPrint('Error inserting log to Supabase: $e');
      }
    }
  }

  await prefs.setStringList(_keySyncedLogIds, syncedIds);
}

String _mapActionToType(String action) {
  final act = action.toLowerCase();
  if (act.contains('karantina')) return 'quarantine';
  if (act.contains('keluar') || act.contains('jual')) return 'sell';
  if (act.contains('hapus') || act.contains('retur') || act.contains('delete')) return 'delete';
  return 'add';
}
