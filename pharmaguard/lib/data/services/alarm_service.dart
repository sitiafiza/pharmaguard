import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../local_storage.dart';
import 'web_audio/web_audio.dart';

class AlarmService {
  static final AlarmService instance = AlarmService._internal();
  AlarmService._internal();

  AudioPlayer? _player;
  bool _isPlaying = false;
  bool _pendingPlay = false;
  DateTime? _lastPlayedAt;
  Timer? _alarmTimer;

  final ValueNotifier<bool> isAlarmPlayingNotifier = ValueNotifier<bool>(false);

  bool get isPlaying => _isPlaying;

  static const String alarmSoundUrl =
      'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg';

  AudioPlayer get player {
    _player ??= AudioPlayer();
    return _player!;
  }

  /// Membuka izin audio (Web Audio API context) sebelum proses async
  void unlockAudio() {
    _pendingPlay = false;
    if (kIsWeb) {
      try {
        unlockWebAudio();
      } catch (e) {
        debugPrint('[AlarmService] unlockWebAudio error: $e');
      }
    }
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
      isAlarmPlayingNotifier.value = true;

      // 1. Prioritas Utama di Web: Gunakan Web Audio API synthesizer bawaan browser
      if (kIsWeb) {
        playWebAlarm();
        debugPrint('[AlarmService] Web Audio API alarm berhasil diputar.');
      } else {
        // 2. Di platform native (Android/iOS/Desktop): Gunakan audioplayers
        final p = player;
        await p.stop();
        await p.setVolume(1.0);
        await p.play(UrlSource(alarmSoundUrl));
        debugPrint('[AlarmService] AudioPlayer alarm berhasil diputar.');
      }

      // Reset status alarm setelah 2.8 detik (durasi rangkaian sirine Web Audio)
      _alarmTimer?.cancel();
      _alarmTimer = Timer(const Duration(milliseconds: 2800), () {
        _isPlaying = false;
        isAlarmPlayingNotifier.value = false;
      });
    } catch (e) {
      debugPrint('[AlarmService] Gagal memutar audio: $e');
      if (kIsWeb) {
        _pendingPlay = true;
      }
      _isPlaying = false;
      isAlarmPlayingNotifier.value = false;
    }
  }

  /// Dipanggil saat ada sentuhan/klik pengguna di layar untuk membuka blokir autoplay browser
  void onUserInteraction() {
    unlockAudio();
    if (_pendingPlay && hasCriticalMedicine() && isNotificationEnabled.value == true) {
      _pendingPlay = false;
      playAlarm();
    }
  }

  Future<void> stop() async {
    try {
      _alarmTimer?.cancel();
      _alarmTimer = null;
      if (kIsWeb) {
        stopWebAlarm();
      }
      await _player?.stop();
    } catch (_) {}
    _isPlaying = false;
    _pendingPlay = false;
    isAlarmPlayingNotifier.value = false;
  }

  void dispose() {
    _alarmTimer?.cancel();
    try {
      _player?.dispose();
    } catch (_) {}
    _player = null;
  }
}
