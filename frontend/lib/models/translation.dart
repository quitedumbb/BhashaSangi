class Translation {
  final int id;
  final String lessonTitle;
  final String? gradeLevel;
  final String? subject;
  final String sourceLanguage;
  final String targetLanguage;
  final String sourceText;
  final String translatedText;
  final String translationMethod;
  final String sessionTag;

  const Translation({
    required this.id,
    required this.lessonTitle,
    this.gradeLevel,
    this.subject,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.sourceText,
    required this.translatedText,
    required this.translationMethod,
    this.sessionTag = 'General Classroom',
  });

  factory Translation.fromJson(Map<String, dynamic> json) {
    return Translation(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      lessonTitle: (json['lesson_title'] ?? 'Classroom Translations').toString(),
      gradeLevel: json['grade_level']?.toString(),
      subject: json['subject']?.toString(),
      sourceLanguage: (json['source_language'] ?? '').toString(),
      targetLanguage: (json['target_language'] ?? '').toString(),
      sourceText: (json['source_text'] ?? '').toString(),
      translatedText: (json['translated_text'] ?? '').toString(),
      translationMethod: (json['translation_method'] ?? 'pending').toString(),
      sessionTag: (json['session_tag'] ?? 'General Classroom').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_title': lessonTitle,
      'grade_level': gradeLevel,
      'subject': subject,
      'source_language': sourceLanguage,
      'target_language': targetLanguage,
      'source_text': sourceText,
      'translated_text': translatedText,
      'translation_method': translationMethod,
      'session_tag': sessionTag,
    };
  }

  bool get isPending =>
      translatedText == 'AI_TRANSLATION_PENDING' ||
      translationMethod.toLowerCase() == 'pending';
}
