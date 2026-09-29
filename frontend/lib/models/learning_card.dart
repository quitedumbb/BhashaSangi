class LearningCard {
  final int id;
  final String wordEn;
  final String wordHi;
  final String wordVernacular;
  final String romanPhonetic;
  final String category;
  final String exampleSentenceEn;
  final String exampleSentenceHi;
  final String exampleSentenceVernacular;
  final int targetLanguageId;
  final String targetLanguageName;
  final String targetLanguageCode;
  final String targetLanguageScript;
  String? audioBase64;
  bool isMastered;

  LearningCard({
    required this.id,
    required this.wordEn,
    required this.wordHi,
    required this.wordVernacular,
    this.romanPhonetic = '',
    this.category = 'Everyday Vocabulary',
    this.exampleSentenceEn = '',
    this.exampleSentenceHi = '',
    this.exampleSentenceVernacular = '',
    this.targetLanguageId = 1,
    this.targetLanguageName = 'Santali',
    this.targetLanguageCode = 'sat',
    this.targetLanguageScript = 'Ol Chiki',
    this.audioBase64,
    this.isMastered = false,
  });

  factory LearningCard.fromJson(Map<String, dynamic> json) {
    return LearningCard(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      wordEn: (json['word_en'] ?? '').toString(),
      wordHi: (json['word_hi'] ?? '').toString(),
      wordVernacular: (json['word_vernacular'] ?? '').toString(),
      romanPhonetic: (json['roman_phonetic'] ?? '').toString(),
      category: (json['category'] ?? 'Everyday Vocabulary').toString(),
      exampleSentenceEn: (json['example_sentence_en'] ?? '').toString(),
      exampleSentenceHi: (json['example_sentence_hi'] ?? '').toString(),
      exampleSentenceVernacular: (json['example_sentence_vernacular'] ?? '').toString(),
      targetLanguageId: json['target_language_id'] is int
          ? json['target_language_id'] as int
          : int.tryParse(json['target_language_id']?.toString() ?? '1') ?? 1,
      targetLanguageName: (json['target_language_name'] ?? 'Santali').toString(),
      targetLanguageCode: (json['target_language_code'] ?? 'sat').toString(),
      targetLanguageScript: (json['target_language_script'] ?? 'Ol Chiki').toString(),
      audioBase64: json['audio_base64']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word_en': wordEn,
      'word_hi': wordHi,
      'word_vernacular': wordVernacular,
      'roman_phonetic': romanPhonetic,
      'category': category,
      'example_sentence_en': exampleSentenceEn,
      'example_sentence_hi': exampleSentenceHi,
      'example_sentence_vernacular': exampleSentenceVernacular,
      'target_language_id': targetLanguageId,
      'target_language_name': targetLanguageName,
      'target_language_code': targetLanguageCode,
      'target_language_script': targetLanguageScript,
      'audio_base64': audioBase64,
    };
  }
}
