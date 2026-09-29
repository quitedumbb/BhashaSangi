import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

@JS('bhashaVoiceHelper')
external BhashaVoiceHelper? get _voiceHelper;

extension type BhashaVoiceHelper(JSObject _) implements JSObject {
  external void startListening(
    String lang,
    JSFunction onResult,
    JSFunction onEnd,
    JSFunction onError,
  );
  external void stopListening();
}

class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  web.HTMLAudioElement? _currentAudio;
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  bool _isListening = false;
  bool get isListening => _isListening;

  /// Plays WAV audio directly from base64 returned by Bhashini TTS.
  void playBase64Audio(
    String base64Audio, {
    VoidCallback? onStart,
    VoidCallback? onDone,
    VoidCallback? onError,
  }) {
    try {
      stopAudio();

      final audio = web.HTMLAudioElement();
      _currentAudio = audio;
      audio.src = 'data:audio/wav;base64,$base64Audio';

      _isPlaying = true;
      if (onStart != null) onStart();

      audio.onended = ((web.Event _) {
        _isPlaying = false;
        if (onDone != null) onDone();
      }).toJS;

      audio.onerror = ((web.Event _) {
        _isPlaying = false;
        if (onError != null) onError();
      }).toJS;

      audio.play();
    } catch (e) {
      _isPlaying = false;
      if (onError != null) onError();
      debugPrint('[VoiceService] Audio playback error: $e');
    }
  }

  /// Stops any currently playing audio clip.
  void stopAudio() {
    if (_currentAudio != null) {
      try {
        _currentAudio!.pause();
        _currentAudio!.currentTime = 0;
      } catch (_) {}
      _currentAudio = null;
    }
    _isPlaying = false;
  }

  /// Starts listening to microphone for classroom speech recognition.
  void startListening({
    String language = 'hi-IN',
    required Function(String text) onResult,
    required VoidCallback onDone,
    required Function(String error) onError,
  }) {
    try {
      stopAudio();
      _isListening = true;

      final helper = _voiceHelper;
      if (helper == null) {
        _isListening = false;
        onError('Voice recognition helper not initialized.');
        return;
      }

      final onResultJS = ((JSString text) {
        onResult(text.toDart);
      }).toJS;

      final onEndJS = (() {
        _isListening = false;
        onDone();
      }).toJS;

      final onErrorJS = ((JSString err) {
        _isListening = false;
        onError(err.toDart);
      }).toJS;

      helper.startListening(language, onResultJS, onEndJS, onErrorJS);
    } catch (e) {
      _isListening = false;
      onError(e.toString());
    }
  }

  /// Stops listening to microphone.
  void stopListening() {
    try {
      _voiceHelper?.stopListening();
    } catch (_) {}
    _isListening = false;
  }
}
