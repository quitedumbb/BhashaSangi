import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/language.dart';
import '../models/translation.dart';
import '../models/translation_result.dart';
import '../models/chapter_notes.dart';
import '../models/curriculum_lesson.dart';
import '../models/classroom_session.dart';
import '../models/learning_card.dart';

class ApiException implements Exception {
  final String friendlyMessage;
  final String? technicalDetails;
  final int? statusCode;

  const ApiException({
    required this.friendlyMessage,
    this.technicalDetails,
    this.statusCode,
  });

  @override
  String toString() => friendlyMessage;
}

class BackendHealth {
  final bool isConnected;
  final String message;
  final DateTime checkedAt;
  final String? error;

  BackendHealth({
    required this.isConnected,
    required this.message,
    required this.checkedAt,
    this.error,
  });
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const Duration requestTimeout = Duration(seconds: 8);

  /// Check backend health: GET /
  Future<BackendHealth> checkHealth() async {
    final uri = Uri.parse(ApiConfig.healthEndpoint);
    try {
      final response = await _client.get(uri).timeout(requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final data = jsonDecode(response.body);
          final msg = data is Map ? (data['message'] ?? 'Online').toString() : 'Online';
          return BackendHealth(
            isConnected: true,
            message: msg,
            checkedAt: DateTime.now(),
          );
        } catch (_) {
          return BackendHealth(
            isConnected: true,
            message: 'Connected (raw response)',
            checkedAt: DateTime.now(),
          );
        }
      } else {
        return BackendHealth(
          isConnected: false,
          message: 'Server error (${response.statusCode})',
          checkedAt: DateTime.now(),
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      return BackendHealth(
        isConnected: false,
        message: 'Connection timed out',
        checkedAt: DateTime.now(),
        error: 'Timeout waiting for ${ApiConfig.healthEndpoint}',
      );
    } catch (e) {
      return BackendHealth(
        isConnected: false,
        message: 'Classroom server offline',
        checkedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// GET /languages
  Future<List<Language>> getLanguages() async {
    final uri = Uri.parse(ApiConfig.languagesEndpoint);
    try {
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw ApiException(
            friendlyMessage: 'Received unexpected language format from the server.',
            technicalDetails: 'Expected JSON List, got: ${decoded.runtimeType}',
            statusCode: response.statusCode,
          );
        }
        return decoded
            .map((item) => Language.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          friendlyMessage: 'Bhasha Sangi could not load the languages catalog.',
          technicalDetails: 'Status ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        friendlyMessage: 'Connection timed out while loading classroom languages.',
        technicalDetails: 'Timeout reached after 8 seconds.',
      );
    } catch (e) {
      throw ApiException(
        friendlyMessage: 'Bhasha Sangi can\'t reach the classroom server right now.',
        technicalDetails: 'Error: $e\nTarget: ${ApiConfig.languagesEndpoint}\nNote: Check if FastAPI backend is running and CORS is configured.',
      );
    }
  }

  /// GET /translations
  Future<List<Translation>> getTranslations() async {
    final uri = Uri.parse(ApiConfig.translationsEndpoint);
    try {
      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(requestTimeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw ApiException(
            friendlyMessage: 'Received unexpected lesson library format.',
            technicalDetails: 'Expected JSON List, got: ${decoded.runtimeType}',
            statusCode: response.statusCode,
          );
        }
        return decoded
            .map((item) => Translation.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(
          friendlyMessage: 'Unable to retrieve translations from the classroom library.',
          technicalDetails: 'Status ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        friendlyMessage: 'Connection timed out while loading lesson translations.',
        technicalDetails: 'Timeout reached after 8 seconds.',
      );
    } catch (e) {
      throw ApiException(
        friendlyMessage: 'Bhasha Sangi can\'t reach the classroom server right now.',
        technicalDetails: 'Error: $e\nTarget: ${ApiConfig.translationsEndpoint}\nNote: Ensure backend is running and MySQL is connected.',
      );
    }
  }

  /// POST /translate
  Future<TranslationResult> translate(TranslationRequestPayload payload) async {
    final uri = Uri.parse(ApiConfig.translateEndpoint);
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload.toJson()),
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw ApiException(
            friendlyMessage: 'Received unexpected response format for translation.',
            technicalDetails: 'Expected JSON object, got ${decoded.runtimeType}',
            statusCode: response.statusCode,
          );
        }
        return TranslationResult.fromJson(decoded);
      } else {
        throw ApiException(
          friendlyMessage: 'The classroom server was unable to process this translation request.',
          technicalDetails: 'Status ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException(
        friendlyMessage: 'Translation request timed out. Please try again.',
        technicalDetails: 'Timeout connecting to ${ApiConfig.translateEndpoint}',
      );
    } catch (e) {
      throw ApiException(
        friendlyMessage: 'Bhasha Sangi can\'t reach the classroom server right now.',
        technicalDetails: 'Error: $e\nEndpoint: ${ApiConfig.translateEndpoint}\nCheck backend and CORS.',
      );
    }
  }

  /// Synthesizes speech audio using Bhashini TTS (POST /tts).
  Future<String?> synthesizeSpeech({
    required String text,
    required String languageCode,
    String gender = 'female',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/tts');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'text': text,
              'language_code': languageCode,
              'gender': gender,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['audio_base64'] != null) {
          return decoded['audio_base64'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Transcribes speech audio using Bhashini ASR (POST /asr).
  Future<String?> transcribeSpeech({
    required String audioBase64,
    required String languageCode,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/asr');
    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'audio_base64': audioBase64,
              'language_code': languageCode,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['transcribed_text'] != null) {
          return decoded['transcribed_text'].toString();
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /lessons
  Future<List<CurriculumLesson>> getCurriculumLessons({String? grade, String? subject}) async {
    var url = '${ApiConfig.baseUrl}/lessons';
    final queryParams = <String, String>{};
    if (grade != null) queryParams['grade'] = grade;
    if (subject != null) queryParams['subject'] = subject;
    if (queryParams.isNotEmpty) {
      url += '?${Uri(queryParameters: queryParams).query}';
    }
    final uri = Uri.parse(url);
    try {
      final response = await _client.get(uri).timeout(requestTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((e) => CurriculumLesson.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// GET /lessons/{lesson_id}/notes
  Future<ChapterNotes?> getChapterNotes({
    required int lessonId,
    int targetLanguageId = 1,
    bool includeAudio = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/lessons/$lessonId/notes?target_language_id=$targetLanguageId&include_audio=$includeAudio');
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 40));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ChapterNotes.fromJson(decoded);
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /lessons/{lesson_id}/generate-notes
  Future<ChapterNotes?> generateChapterNotes({
    required int lessonId,
    int targetLanguageId = 1,
    String? apiKey,
    String provider = 'auto',
    bool forceRefresh = true,
    bool includeAudio = true,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/lessons/$lessonId/generate-notes');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'target_language_id': targetLanguageId,
          'api_key': apiKey,
          'provider': provider,
          'force_refresh': forceRefresh,
          'include_audio': includeAudio,
        }),
      ).timeout(const Duration(seconds: 50));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ChapterNotes.fromJson(decoded);
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /sessions
  Future<List<ClassroomSession>> getSessions() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sessions');
    try {
      final response = await _client.get(uri).timeout(requestTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((e) => ClassroomSession.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// POST /sessions
  Future<bool> createSession(String name, String tag, {int? lessonId, int targetLanguageId = 1}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sessions');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'session_name': name,
          'folder_tag': tag,
          'lesson_id': lessonId,
          'target_language_id': targetLanguageId,
        }),
      ).timeout(requestTimeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// POST /sessions/generate-notes
  Future<ClassroomSession?> generateSessionNotes({
    required String folderTag,
    int targetLanguageId = 1,
    String? apiKey,
    String aiProvider = 'auto',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sessions/generate-notes');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'folder_tag': folderTag,
          'target_language_id': targetLanguageId,
          'api_key': apiKey,
          'ai_provider': aiProvider,
        }),
      ).timeout(const Duration(seconds: 50));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return ClassroomSession(
            id: decoded['session_id'] as int?,
            sessionName: folderTag,
            folderTag: folderTag,
            targetLanguageId: targetLanguageId,
            targetLanguage: (decoded['target_language'] ?? 'Santali').toString(),
            notes: decoded['notes'] != null ? ChapterNotes.fromJson(decoded['notes'] as Map<String, dynamic>) : null,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// GET /sessions/tags
  Future<List<String>> getSessionTags() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/sessions/tags');
    try {
      final response = await _client.get(uri).timeout(requestTimeout);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// POST /translations/{id}/tag
  Future<bool> updateTranslationTag(int translationId, String newTag) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/translations/$translationId/tag');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'session_tag': newTag}),
      ).timeout(requestTimeout);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  /// PDF Export URLs for native browser printing & PDF download
  String getChapterPdfUrl(int lessonId, int targetLanguageId) =>
      '${ApiConfig.baseUrl}/export/pdf/chapter-note?lesson_id=$lessonId&target_language_id=$targetLanguageId';

  String getSessionPdfUrl({int? sessionId, String? folderTag}) {
    if (sessionId != null) {
      return '${ApiConfig.baseUrl}/export/pdf/session-note?session_id=$sessionId';
    }
    return '${ApiConfig.baseUrl}/export/pdf/session-note?folder_tag=${Uri.encodeComponent(folderTag ?? "General Classroom")}';
  }

  /// GET /learning-cards/daily
  Future<List<LearningCard>> getDailyLearningCards({
    int targetLanguageId = 1,
    int count = 10,
    bool shuffle = false,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/learning-cards/daily?target_language_id=$targetLanguageId&count=$count&shuffle=$shuffle');
    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 35));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((e) => LearningCard.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// POST /learning-cards/custom
  Future<LearningCard?> createCustomLearningCard({
    required String wordEn,
    int targetLanguageId = 1,
    String category = 'Classroom Vocabulary',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/learning-cards/custom');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'word_en': wordEn,
          'target_language_id': targetLanguageId,
          'category': category,
        }),
      ).timeout(const Duration(seconds: 35));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return LearningCard.fromJson(decoded);
        }
      }
    } catch (_) {}
    return null;
  }

  /// POST /learning-cards/audio
  Future<String?> getCardAudio({
    required String text,
    required String languageCode,
    String gender = 'female',
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/learning-cards/audio');
    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'language_code': languageCode,
          'gender': gender,
        }),
      ).timeout(const Duration(seconds: 25));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['audio_base64'] != null) {
          return decoded['audio_base64'].toString();
        }
      }
    } catch (_) {}
    return null;
  }
}
