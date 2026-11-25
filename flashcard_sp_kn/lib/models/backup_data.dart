class BackupData {
  /// Versión actual del formato de respaldo.
  ///
  /// v1: solo korean, translation, note
  /// v2: agrega romanization, example, example_translation, context
  static const int currentVersion = 2;

  final int version;
  final String exportedAt;
  final List<BackupGroup> groups;

  BackupData({
    required this.version,
    required this.exportedAt,
    required this.groups,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'exported_at': exportedAt,
      'groups': groups.map((g) => g.toMap()).toList(),
    };
  }

  factory BackupData.fromMap(Map<String, dynamic> map) {
    final rawGroups = map['groups'] as List<dynamic>? ?? [];

    return BackupData(
      version: (map['version'] as num?)?.toInt() ?? 1,
      exportedAt: (map['exported_at'] ?? '').toString(),
      groups: rawGroups
          .map((g) => BackupGroup.fromMap(Map<String, dynamic>.from(g)))
          .toList(),
    );
  }
}

class BackupGroup {
  final String name;
  final String createdAt;
  final List<BackupFlashcard> flashcards;

  BackupGroup({
    required this.name,
    required this.createdAt,
    required this.flashcards,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'created_at': createdAt,
      'flashcards': flashcards.map((f) => f.toMap()).toList(),
    };
  }

  factory BackupGroup.fromMap(Map<String, dynamic> map) {
    final rawCards = map['flashcards'] as List<dynamic>? ?? [];

    return BackupGroup(
      name: (map['name'] ?? '').toString(),
      createdAt:
      (map['created_at'] ?? DateTime.now().toIso8601String()).toString(),
      flashcards: rawCards
          .map((f) => BackupFlashcard.fromMap(Map<String, dynamic>.from(f)))
          .toList(),
    );
  }
}

class BackupFlashcard {
  final String korean;
  final String translation;
  final String? romanization;
  final String? example;
  final String? exampleTranslation;
  final String? context;
  final String? note;

  BackupFlashcard({
    required this.korean,
    required this.translation,
    this.romanization,
    this.example,
    this.exampleTranslation,
    this.context,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'korean': korean,
      'translation': translation,
      'romanization': romanization,
      'example': example,
      'example_translation': exampleTranslation,
      'context': context,
      'note': note,
    };
  }

  factory BackupFlashcard.fromMap(Map<String, dynamic> map) {
    String? clean(dynamic value) {
      if (value == null) return null;

      final text = value.toString().trim();

      return text.isEmpty ? null : text;
    }

    return BackupFlashcard(
      korean: (map['korean'] ?? '').toString(),
      translation: (map['translation'] ?? '').toString(),
      romanization: clean(map['romanization']),
      example: clean(map['example']),
      exampleTranslation: clean(map['example_translation']),
      context: clean(map['context']),
      note: clean(map['note']),
    );
  }
}