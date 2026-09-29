import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/language.dart';
import '../models/translation_result.dart';
import '../services/api_service.dart';
import '../services/voice_service.dart';
import '../state/classroom_state.dart';

class VoiceTranslateDialog extends StatefulWidget {
  final VoidCallback? onSaved;

  const VoiceTranslateDialog({super.key, this.onSaved});

  static Future<void> show(BuildContext context, {VoidCallback? onSaved}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => VoiceTranslateDialog(onSaved: onSaved),
    );
  }

  @override
  State<VoiceTranslateDialog> createState() => _VoiceTranslateDialogState();
}

class _VoiceTranslateDialogState extends State<VoiceTranslateDialog>
    with SingleTickerProviderStateMixin {
  final TextEditingController _speechTextController = TextEditingController();
  final ApiService _apiService = ApiService();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isListening = false;
  bool _isTranslating = false;
  bool _isPlayingAudio = false;
  String? _errorMessage;

  String _inputSpeechLocale = 'hi-IN'; // Speech input language (Hindi by default)
  Language? _selectedTargetLanguage;
  TranslationResult? _result;
  String? _currentAudioBase64;

  final Map<String, String> _inputLocales = {
    'hi-IN': 'Hindi (हिन्दी)',
    'en-IN': 'English (Indian)',
    'bn-IN': 'Bengali (বাংলা)',
    'or-IN': 'Odia (ଓଡ଼ିଆ)',
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Default target language to Santali or second language
    final state = ClassroomState.instance;
    _selectedTargetLanguage = state.selectedTargetLanguage ??
        (state.languages.isNotEmpty ? state.languages.first : null);
  }

  @override
  void dispose() {
    VoiceService.instance.stopListening();
    VoiceService.instance.stopAudio();
    _pulseController.dispose();
    _speechTextController.dispose();
    super.dispose();
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    setState(() {
      _isListening = true;
      _errorMessage = null;
    });
    _pulseController.repeat(reverse: true);

    VoiceService.instance.startListening(
      language: _inputSpeechLocale,
      onResult: (text) {
        if (mounted) {
          setState(() {
            _speechTextController.text = text;
          });
        }
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _isListening = false;
          });
          _pulseController.stop();
          _pulseController.reset();
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _errorMessage = err;
          });
          _pulseController.stop();
          _pulseController.reset();
        }
      },
    );
  }

  void _stopListening() {
    VoiceService.instance.stopListening();
    setState(() {
      _isListening = false;
    });
    _pulseController.stop();
    _pulseController.reset();
  }

  Future<void> _handleTranslateAndSpeak() async {
    final text = _speechTextController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorMessage = 'Please speak or type a sentence first.');
      return;
    }

    final state = ClassroomState.instance;

    // Resolve source language according to the voice speech input locale selected by the teacher
    Language? source;
    final localePrefix = _inputSpeechLocale.split('-').first.toLowerCase();
    for (final l in state.languages) {
      if (l.languageCode.toLowerCase().startsWith(localePrefix)) {
        source = l;
        break;
      }
    }
    source ??= state.selectedSourceLanguage ?? state.languages.first;

    final target = _selectedTargetLanguage ?? state.selectedTargetLanguage;

    if (target == null) {
      setState(() => _errorMessage = 'Source and target languages are required.');
      return;
    }

    if (source.id == target.id) {
      setState(() => _errorMessage = 'Source and target languages are identical. Please choose a different target mother tongue.');
      return;
    }

    setState(() {
      _isTranslating = true;
      _errorMessage = null;
      _result = null;
      _currentAudioBase64 = null;
    });

    final payload = TranslationRequestPayload(
      sourceLanguageId: source.id,
      targetLanguageId: target.id,
      sourceText: text,
      includeAudio: true,
    );

    try {
      final res = await _apiService.translate(payload);
      if (mounted) {
        setState(() {
          _result = res;
          _currentAudioBase64 = res.audioBase64;
          _isTranslating = false;
        });

        // Trigger background refresh for library
        ClassroomState.instance.refreshAll();

        // Automatically synthesize and speak output audio via Bhashini TTS!
        if (res.audioBase64 != null) {
          _playAudio(res.audioBase64!);
        } else {
          // Fallback: request TTS synthesis
          _synthesizeAndPlay(res.translatedText, target.languageCode);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _synthesizeAndPlay(String translatedText, String langCode) async {
    final audio = await _apiService.synthesizeSpeech(
      text: translatedText,
      languageCode: langCode,
    );
    if (audio != null && mounted) {
      setState(() => _currentAudioBase64 = audio);
      _playAudio(audio);
    }
  }

  void _playAudio(String audioBase64) {
    setState(() => _isPlayingAudio = true);
    VoiceService.instance.playBase64Audio(
      audioBase64,
      onDone: () {
        if (mounted) setState(() => _isPlayingAudio = false);
      },
      onError: () {
        if (mounted) setState(() => _isPlayingAudio = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ClassroomState.instance;
    final languages = state.languages;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ClassroomColors.terracottaLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: ClassroomColors.terracotta,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speak & Translate',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: ClassroomColors.textDark,
                  ),
                ),
                Text(
                  'Powered by Bhashini ASR (Voice-In) & TTS (Voice-Out)',
                  style: GoogleFonts.notoSans(
                    fontSize: 11,
                    color: ClassroomColors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Controls Row (Speech Input Language & Target Language)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ClassroomColors.creamBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: ClassroomColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    // Voice input language
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Speak In (Voice In):',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ClassroomColors.terracotta,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButton<String>(
                            isExpanded: true,
                            value: _inputSpeechLocale,
                            underline: const SizedBox(),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ClassroomColors.textDark,
                            ),
                            items: _inputLocales.entries.map((e) {
                              return DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _inputSpeechLocale = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: ClassroomColors.textSubtle,
                    ),
                    const SizedBox(width: 8),
                    // Target Vernacular Language
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Translate To (Voice Out):',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: ClassroomColors.earthySage,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DropdownButton<Language>(
                            isExpanded: true,
                            value: _selectedTargetLanguage,
                            underline: const SizedBox(),
                            hint: Text(
                              'Target Language',
                              style: GoogleFonts.notoSans(fontSize: 12),
                            ),
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ClassroomColors.textDark,
                            ),
                            items: languages.map((l) {
                              return DropdownMenuItem(
                                value: l,
                                child: Text(l.languageName),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedTargetLanguage = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Big Animated Microphone Button
              Center(
                child: ScaleTransition(
                  scale: _isListening ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening
                          ? ClassroomColors.errorRust
                          : ClassroomColors.terracotta,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening
                                  ? ClassroomColors.errorRust
                                  : ClassroomColors.terracotta)
                              .withOpacity(0.35),
                          blurRadius: _isListening ? 20 : 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                      tooltip: _isListening ? 'Tap to stop listening' : 'Tap to speak',
                      onPressed: _toggleListening,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isListening
                    ? 'Listening… Speak your classroom sentence now'
                    : 'Tap the microphone to speak',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _isListening
                      ? ClassroomColors.errorRust
                      : ClassroomColors.textMuted,
                ),
              ),

              const SizedBox(height: 16),

              // 3. Recognized / Input Text Box
              TextField(
                controller: _speechTextController,
                maxLines: 2,
                style: GoogleFonts.notoSans(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Recognized sentence will appear here (or type)…',
                  prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                  suffixIcon: _speechTextController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _speechTextController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              ),

              // Error display
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.notoSans(
                    fontSize: 12,
                    color: ClassroomColors.errorRust,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              // 4. Translation & Speech Output Result Card
              if (_result != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ClassroomColors.sageLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ClassroomColors.earthySage.withOpacity(0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Vernacular Voice Translation:',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: ClassroomColors.sageDark,
                            ),
                          ),
                          if (_currentAudioBase64 != null)
                            ElevatedButton.icon(
                              onPressed: () => _playAudio(_currentAudioBase64!),
                              icon: Icon(
                                _isPlayingAudio
                                    ? Icons.volume_up_rounded
                                    : Icons.play_arrow_rounded,
                                size: 16,
                              ),
                              label: Text(_isPlayingAudio ? 'Playing…' : 'Play Audio 🔊'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ClassroomColors.earthySage,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _result!.translatedText,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: ClassroomColors.textDark,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Close',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: ClassroomColors.textSubtle,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isTranslating || _isListening
              ? null
              : _handleTranslateAndSpeak,
          icon: _isTranslating
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.translate_rounded, size: 18),
          label: Text(_isTranslating ? 'Translating & Speaking…' : 'Translate & Speak 🔊'),
        ),
      ],
    );
  }
}
