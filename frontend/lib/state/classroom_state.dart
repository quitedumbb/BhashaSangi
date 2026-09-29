import 'package:flutter/foundation.dart';
import '../models/language.dart';
import '../models/translation.dart';
import '../services/api_service.dart';

class ClassroomState extends ChangeNotifier {
  static final ClassroomState instance = ClassroomState._();
  ClassroomState._();

  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  String? _technicalError;

  BackendHealth? _backendHealth;
  List<Language> _languages = [];
  List<Translation> _translations = [];

  Language? _selectedSourceLanguage;
  Language? _selectedTargetLanguage;

  DateTime? _lastSyncTime;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get technicalError => _technicalError;
  BackendHealth? get backendHealth => _backendHealth;
  List<Language> get languages => _languages;
  List<Translation> get translations => _translations;
  Language? get selectedSourceLanguage => _selectedSourceLanguage;
  Language? get selectedTargetLanguage => _selectedTargetLanguage;
  DateTime? get lastSyncTime => _lastSyncTime;

  bool get isBackendConnected => _backendHealth?.isConnected ?? false;

  void selectSourceLanguage(Language? lang) {
    _selectedSourceLanguage = lang;
    notifyListeners();
  }

  void selectTargetLanguage(Language? lang) {
    _selectedTargetLanguage = lang;
    notifyListeners();
  }

  void swapLanguages() {
    final temp = _selectedSourceLanguage;
    _selectedSourceLanguage = _selectedTargetLanguage;
    _selectedTargetLanguage = temp;
    notifyListeners();
  }

  /// Initial load or manual refresh of all backend data
  Future<void> refreshAll() async {
    _isLoading = true;
    _errorMessage = null;
    _technicalError = null;
    notifyListeners();

    // 1. Health check
    try {
      _backendHealth = await _apiService.checkHealth();
    } catch (e) {
      _backendHealth = BackendHealth(
        isConnected: false,
        message: 'Unable to reach backend',
        checkedAt: DateTime.now(),
        error: e.toString(),
      );
    }

    // 2. Languages
    try {
      final fetchedLanguages = await _apiService.getLanguages();
      _languages = fetchedLanguages;

      // Auto-assign default source and target if not already set or invalid
      if (_languages.isNotEmpty) {
        if (_selectedSourceLanguage == null ||
            !_languages.any((l) => l.id == _selectedSourceLanguage!.id)) {
          // Default source to Hindi, English, or first available instructional language
          _selectedSourceLanguage = _languages.firstWhere(
            (l) => l.languageCode.toLowerCase().startsWith('hi'),
            orElse: () => _languages.firstWhere(
              (l) => l.languageCode.toLowerCase().startsWith('en'),
              orElse: () => _languages.first,
            ),
          );
        }
        if (_languages.length > 1) {
          if (_selectedTargetLanguage == null ||
              !_languages.any((l) => l.id == _selectedTargetLanguage!.id) ||
              _selectedTargetLanguage!.id == _selectedSourceLanguage!.id) {
            // Default target to Santali, or first tribal mother tongue different from source
            _selectedTargetLanguage = _languages.firstWhere(
              (l) => l.languageCode.toLowerCase().startsWith('sat'),
              orElse: () => _languages.firstWhere(
                (l) => l.id != _selectedSourceLanguage!.id,
                orElse: () => _languages.last,
              ),
            );
          }
        } else {
          _selectedTargetLanguage = _languages.first;
        }
      }
    } on ApiException catch (e) {
      _errorMessage = e.friendlyMessage;
      _technicalError = e.technicalDetails;
    } catch (e) {
      _errorMessage = 'Could not load languages from classroom server.';
      _technicalError = e.toString();
    }

    // 3. Translations
    try {
      final fetchedTranslations = await _apiService.getTranslations();
      // Ensure most recent translations appear first (highest id first)
      fetchedTranslations.sort((a, b) => b.id.compareTo(a.id));
      _translations = fetchedTranslations;
    } on ApiException catch (e) {
      if (_errorMessage == null) {
        _errorMessage = e.friendlyMessage;
        _technicalError = e.technicalDetails;
      }
    } catch (e) {
      if (_errorMessage == null) {
        _errorMessage = 'Could not load lesson translations.';
        _technicalError = e.toString();
      }
    }

    _lastSyncTime = DateTime.now();
    _isLoading = false;
    notifyListeners();
  }

  /// Ping health only
  Future<void> checkHealthOnly() async {
    _backendHealth = await _apiService.checkHealth();
    _lastSyncTime = DateTime.now();
    notifyListeners();
  }
}
