import 'package:flutter/foundation.dart';

/// Central API Configuration for Bhasha Sangi.
/// Configurable through [ApiConfig.baseUrl] without hardcoding URLs across the app.
class ApiConfig {
  ApiConfig._();

  static final ValueNotifier<String> baseUrlNotifier = ValueNotifier<String>(
    defaultBaseUrl,
  );

  /// Default backend URL for local development.
  static const String defaultBaseUrl = 'http://127.0.0.1:8000';

  /// Current base URL in use.
  static String get baseUrl => baseUrlNotifier.value;

  /// Update the base URL dynamically (e.g. from Settings screen).
  static void setBaseUrl(String newUrl) {
    var trimmed = newUrl.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    baseUrlNotifier.value = trimmed;
  }

  // Endpoints matching existing FastAPI contract exactly
  static String get healthEndpoint => '$baseUrl/';
  static String get languagesEndpoint => '$baseUrl/languages';
  static String get translationsEndpoint => '$baseUrl/translations';
  static String get translateEndpoint => '$baseUrl/translate';
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get teachersEndpoint => '$baseUrl/auth/teachers';
}
