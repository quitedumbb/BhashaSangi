class ChapterNotes {
  final int lessonId;
  final String lessonTitle;
  final String gradeLevel;
  final String subject;
  final String targetLanguage;
  final String targetLanguageCode;
  final String aiProvider;
  final String summaryEn;
  final String summaryHi;
  final String summaryTranslated;
  final List<String> keyPoints;
  final List<NoteVocabularyItem> vocabulary;
  final NoteActivity classroomActivity;
  final List<NoteQuestionItem> practiceQuestions;
  final String? audioBase64;

  const ChapterNotes({
    required this.lessonId,
    required this.lessonTitle,
    required this.gradeLevel,
    required this.subject,
    required this.targetLanguage,
    required this.targetLanguageCode,
    required this.aiProvider,
    required this.summaryEn,
    required this.summaryHi,
    required this.summaryTranslated,
    required this.keyPoints,
    required this.vocabulary,
    required this.classroomActivity,
    required this.practiceQuestions,
    this.audioBase64,
  });

  factory ChapterNotes.fromJson(Map<String, dynamic> json) {
    return ChapterNotes(
      lessonId: json['lesson_id'] is int
          ? json['lesson_id'] as int
          : int.tryParse(json['lesson_id'].toString()) ?? 0,
      lessonTitle: (json['lesson_title'] ?? '').toString(),
      gradeLevel: (json['grade_level'] ?? 'Class 3').toString(),
      subject: (json['subject'] ?? 'Science / EVS').toString(),
      targetLanguage: (json['target_language'] ?? 'Santali').toString(),
      targetLanguageCode: (json['target_language_code'] ?? 'sat').toString(),
      aiProvider: (json['ai_provider'] ?? 'bhashini_curriculum_engine').toString(),
      summaryEn: (json['summary_en'] ?? '').toString(),
      summaryHi: (json['summary_hi'] ?? '').toString(),
      summaryTranslated: (json['summary_translated'] ?? '').toString(),
      keyPoints: (json['key_points'] as List? ?? []).map((e) => e.toString()).toList(),
      vocabulary: (json['vocabulary'] as List? ?? [])
          .map((e) => NoteVocabularyItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      classroomActivity: NoteActivity.fromJson(
        json['classroom_activity'] as Map<String, dynamic>? ?? {},
      ),
      practiceQuestions: (json['practice_questions'] as List? ?? json['questions'] as List? ?? [])
          .map((e) => NoteQuestionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      audioBase64: json['audio_base64']?.toString(),
    );
  }
}

class NoteVocabularyItem {
  final String wordEn;
  final String wordHi;
  final String meaning;

  const NoteVocabularyItem({
    required this.wordEn,
    required this.wordHi,
    required this.meaning,
  });

  factory NoteVocabularyItem.fromJson(Map<String, dynamic> json) {
    return NoteVocabularyItem(
      wordEn: (json['word_en'] ?? '').toString(),
      wordHi: (json['word_hi'] ?? '').toString(),
      meaning: (json['meaning'] ?? '').toString(),
    );
  }
}

class NoteActivity {
  final String title;
  final String instructions;
  final String instructionsTranslated;

  const NoteActivity({
    required this.title,
    required this.instructions,
    required this.instructionsTranslated,
  });

  factory NoteActivity.fromJson(Map<String, dynamic> json) {
    return NoteActivity(
      title: (json['title'] ?? 'Classroom Activity').toString(),
      instructions: (json['instructions'] ?? '').toString(),
      instructionsTranslated: (json['instructions_translated'] ?? '').toString(),
    );
  }
}

class NoteQuestionItem {
  final String questionEn;
  final String questionHi;
  final String questionTranslated;
  final String answerEn;
  final String answerHi;
  final String answerTranslated;

  const NoteQuestionItem({
    required this.questionEn,
    required this.questionHi,
    required this.questionTranslated,
    required this.answerEn,
    required this.answerHi,
    required this.answerTranslated,
  });

  factory NoteQuestionItem.fromJson(Map<String, dynamic> json) {
    return NoteQuestionItem(
      questionEn: (json['question_en'] ?? '').toString(),
      questionHi: (json['question_hi'] ?? '').toString(),
      questionTranslated: (json['question_translated'] ?? '').toString(),
      answerEn: (json['answer_en'] ?? '').toString(),
      answerHi: (json['answer_hi'] ?? '').toString(),
      answerTranslated: (json['answer_translated'] ?? '').toString(),
    );
  }
}
