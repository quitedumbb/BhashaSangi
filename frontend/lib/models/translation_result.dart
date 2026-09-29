class TranslationRequestPayload {
  final int sourceLanguageId;
  final int targetLanguageId;
  final String sourceText;
  final int? lessonId;
  final int? dialectId;
  final bool includeAudio;
  final String sessionTag;

  const TranslationRequestPayload({
    required this.sourceLanguageId,
    required this.targetLanguageId,
    required this.sourceText,
    this.lessonId,
    this.dialectId,
    this.includeAudio = true,
    this.sessionTag = 'General Classroom',
  });

  Map<String, dynamic> toJson() {
    return {
      'source_language_id': sourceLanguageId,
      'target_language_id': targetLanguageId,
      'source_text': sourceText,
      'lesson_id': lessonId,
      'dialect_id': dialectId,
      'include_audio': includeAudio,
      'session_tag': sessionTag,
    };
  }
}

class TranslationResult {
  final String sourceText;
  final String translatedText;
  final String status;
  final String? audioBase64;

  const TranslationResult({
    required this.sourceText,
    required this.translatedText,
    required this.status,
    this.audioBase64,
  });

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      sourceText: (json['source_text'] ?? '').toString(),
      translatedText: (json['translated_text'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      audioBase64: json['audio_base64'] != null && json['audio_base64'].toString().isNotEmpty
          ? json['audio_base64'].toString()
          : null,
    );
  }

  /// Returns true if the backend indicates AI service is not yet connected or pending.
  bool get isPending =>
      translatedText == 'AI_TRANSLATION_PENDING' ||
      status == 'translation_pending';
}
