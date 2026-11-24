import 'dart:js_interop';

@JS('window.unlockAudioContext')
external void _jsUnlock();

@JS('window.playAlarmSiren')
external void _jsPlay();

@JS('window.stopAlarmSiren')
external void _jsStop();

@JS('window.isAlarmSirenPlaying')
external bool? _jsIsPlaying();

void unlockWebAudio() {
  try {
    _jsUnlock();
  } catch (_) {}
}

void playWebAlarm() {
  try {
    _jsPlay();
  } catch (_) {}
}

void stopWebAlarm() {
  try {
    _jsStop();
  } catch (_) {}
}

bool isWebAlarmPlaying() {
  try {
    return _jsIsPlaying() ?? false;
  } catch (_) {
    return false;
  }
}
