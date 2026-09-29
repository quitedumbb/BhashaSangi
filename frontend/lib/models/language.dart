class Language {
  final int id;
  final String languageCode;
  final String languageName;
  final String nativeName;
  final String script;

  const Language({
    required this.id,
    required this.languageCode,
    required this.languageName,
    required this.nativeName,
    required this.script,
  });

  factory Language.fromJson(Map<String, dynamic> json) {
    return Language(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      languageCode: (json['language_code'] ?? '').toString(),
      languageName: (json['language_name'] ?? '').toString(),
      nativeName: (json['native_name'] ?? '').toString(),
      script: (json['script'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'language_code': languageCode,
      'language_name': languageName,
      'native_name': nativeName,
      'script': script,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$languageName ($nativeName)';
}
