import 'dart:convert';
import 'chapter_notes.dart';

class ClassroomSession {
  final int? id;
  final String sessionName;
  final String folderTag;
  final int? lessonId;
  final int targetLanguageId;
  final String targetLanguage;
  final String rawTranscript;
  final ChapterNotes? notes;
  final String? createdAt;
  final int translationCount;

  const ClassroomSession({
    this.id,
    required this.sessionName,
    required this.folderTag,
    this.lessonId,
    this.targetLanguageId = 1,
    this.targetLanguage = 'Santali',
    this.rawTranscript = '',
    this.notes,
    this.createdAt,
    this.translationCount = 0,
  });

  factory ClassroomSession.fromJson(Map<String, dynamic> json) {
    ChapterNotes? parsedNotes;
    if (json['notes_json'] != null) {
      try {
        final dynamic raw = json['notes_json'];
        final Map<String, dynamic> notesMap = raw is String ? jsonDecode(raw) : (raw as Map<String, dynamic>);
        parsedNotes = ChapterNotes.fromJson(notesMap);
      } catch (e) {
        // ignore parse errors
      }
    } else if (json['notes'] != null && json['notes'] is Map<String, dynamic>) {
      try {
        parsedNotes = ChapterNotes.fromJson(json['notes'] as Map<String, dynamic>);
      } catch (e) {
        // ignore
      }
    }

    return ClassroomSession(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      sessionName: (json['session_name'] ?? 'Classroom Session').toString(),
      folderTag: (json['folder_tag'] ?? 'General Classroom').toString(),
      lessonId: json['lesson_id'] is int ? json['lesson_id'] as int : int.tryParse(json['lesson_id']?.toString() ?? ''),
      targetLanguageId: json['target_language_id'] is int ? json['target_language_id'] as int : int.tryParse(json['target_language_id']?.toString() ?? '1') ?? 1,
      targetLanguage: (json['target_language'] ?? 'Santali').toString(),
      rawTranscript: (json['raw_transcript'] ?? '').toString(),
      notes: parsedNotes,
      createdAt: json['created_at']?.toString(),
      translationCount: json['translation_count'] is int ? json['translation_count'] as int : int.tryParse(json['translation_count']?.toString() ?? '0') ?? 0,
    );
  }

  bool get hasGeneratedNotes => notes != null;
}
