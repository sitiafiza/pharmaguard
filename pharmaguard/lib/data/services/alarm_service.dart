import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../local_storage.dart';

class AlarmService {
  static final AlarmService instance = AlarmService._internal();
  AlarmService._internal();

  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _pendingPlay = false;
  DateTime? _lastPlayedAt;

  bool get isPlaying => _isPlaying;

  static const String alarmSoundUrl =
      'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg';

  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Memeriksa apakah ada obat aktif berstatus kritis/kedaluwarsa (sisa hari <= 7 hari, termasuk <= 0 hari)
  bool hasCriticalMedicine() {
    return mockMedicines.any((m) => m.remainingDays <= 7);
  }

  /// Memeriksa kondisi obat dan menyalakan alarm jika syarat terpenuhi
  Future<void> checkAndPlayAlarm({bool force = false}) async {
    // 1. Cek preferensi notifikasi dari pengguna
    if (isNotificationEnabled.value != true) {
      debugPrint('[AlarmService] Notifikasi alarm dinonaktifkan di pengaturan.');
      return;
    }

    // 2. Cek apakah ada obat aktif yang sisa hari <= 7 (termasuk 0 atau minus / expired)
    final criticalMeds = mockMedicines.where((m) => m.remainingDays <= 7).toList();
    if (criticalMeds.isEmpty) {
      debugPrint('[AlarmService] Tidak ada obat kritis (sisa hari <= 7).');
      return;
    }

    debugPrint('[AlarmService] Ditemukan ${criticalMeds.length} obat kritis/expired. Memutar alarm...');

    // Hindari spam suara jika baru diputar kurang dari 2 detik yang lalu (kecuali force)
    if (!force && _lastPlayedAt != null) {
      final diff = DateTime.now().difference(_lastPlayedAt!);
      if (diff.inSeconds < 2) {
        return;
      }
    }

    await playAlarm();
  }

  /// Memutar audio alarm secara langsung
  Future<void> playAlarm() async {
    try {
      _lastPlayedAt = DateTime.now();
      _isPlaying = true;
      _pendingPlay = false;

      final p = player;
      await p.stop();
      await p.setVolume(1.0);
      await p.play(UrlSource(alarmSoundUrl));
      debugPrint('[AlarmService] Audio alarm berhasil diputar.');
    } catch (e) {
      debugPrint('[AlarmService] Gagal memutar audio: $e');
      // Jika browser memblokir karena kebijakan autoplay di Flutter Web, simpan flag pending
      if (kIsWeb) {
        _pendingPlay = true;
      }
    } finally {
      _isPlaying = false;
    }
  }

  /// Dipanggil saat ada sentuhan/klik pengguna di layar untuk membuka blokir autoplay browser
  void onUserInteraction() {
    if (_pendingPlay && hasCriticalMedicine() && isNotificationEnabled.value == true) {
      _pendingPlay = false;
      playAlarm();
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
    _isPlaying = false;
    _pendingPlay = false;
  }

  void dispose() {
    try {
      _player?.dispose();
    } catch (_) {}
    _player = null;
  }
}
