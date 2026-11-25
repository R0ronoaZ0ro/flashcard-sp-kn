class Flashcard {
  final int id;
  final int groupId;

  /// Texto original en coreano.
  final String korean;

  /// Romanización del coreano (pronunciación escrita).
  /// Ejemplo: "eomma".
  final String? romanization;

  /// Traducción al español.
  final String translation;

  /// Ruta local de la imagen.
  final String? imagePath;

  /// Nota o descripción adicional.
  final String? note;

  /// Ejemplo de uso en coreano.
  final String? example;

  /// Traducción del ejemplo al español.
  final String? exampleTranslation;

  /// Contexto de uso de la palabra.
  final String? context;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Flashcard({
    required this.id,
    required this.groupId,
    required this.korean,
    this.romanization,
    required this.translation,
    this.imagePath,
    this.note,
    this.example,
    this.exampleTranslation,
    this.context,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // CREAR DESDE MAP
  // ============================================================

  factory Flashcard.fromMap(
      Map<String, dynamic> map,
      ) {
    return Flashcard(
      id: _parseInt(
        map['id'],
      ),
      groupId: _parseInt(
        map['group_id'],
      ),
      korean:
      (map['korean'] ?? '').toString(),
      romanization:
      _parseNullableString(
        map['romanization'],
      ),
      translation:
      (map['translation'] ?? '').toString(),
      imagePath:
      _parseNullableString(
        map['image_path'],
      ),
      note:
      _parseNullableString(
        map['note'],
      ),
      example:
      _parseNullableString(
        map['example'],
      ),
      exampleTranslation:
      _parseNullableString(
        map['example_translation'],
      ),
      context:
      _parseNullableString(
        map['context'],
      ),
      createdAt:
      _parseDateTime(
        map['created_at'],
      ),
      updatedAt:
      _parseDateTime(
        map['updated_at'],
      ),
    );
  }

  // ============================================================
  // CONVERTIR A MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'korean': korean,
      'romanization': romanization,
      'translation': translation,
      'image_path': imagePath,
      'note': note,
      'example': example,
      'example_translation': exampleTranslation,
      'context': context,
      'created_at':
      createdAt.toIso8601String(),
      'updated_at':
      updatedAt.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Flashcard copyWith({
    int? id,
    int? groupId,
    String? korean,
    bool clearRomanization = false,
    String? romanization,
    String? translation,

    bool clearImagePath = false,
    String? imagePath,

    bool clearNote = false,
    String? note,

    bool clearExample = false,
    String? example,

    bool clearExampleTranslation = false,
    String? exampleTranslation,

    bool clearContext = false,
    String? context,

    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      groupId:
      groupId ?? this.groupId,
      korean:
      korean ?? this.korean,
      romanization:
      clearRomanization
          ? null
          : romanization ?? this.romanization,
      translation:
      translation ?? this.translation,

      imagePath:
      clearImagePath
          ? null
          : imagePath ?? this.imagePath,

      note:
      clearNote
          ? null
          : note ?? this.note,

      example:
      clearExample
          ? null
          : example ?? this.example,

      exampleTranslation:
      clearExampleTranslation
          ? null
          : exampleTranslation ?? this.exampleTranslation,

      context:
      clearContext
          ? null
          : context ?? this.context,

      createdAt:
      createdAt ?? this.createdAt,

      updatedAt:
      updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // SERIALIZACIÓN
  // ============================================================

  @override
  String toString() {
    return 'Flashcard('
        'id: $id, '
        'groupId: $groupId, '
        'korean: $korean, '
        'romanization: $romanization, '
        'translation: $translation, '
        'imagePath: $imagePath, '
        'note: $note, '
        'example: $example, '
        'exampleTranslation: $exampleTranslation, '
        'context: $context, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }

  @override
  bool operator ==(
      Object other,
      ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other is Flashcard &&
        other.id == id &&
        other.groupId == groupId &&
        other.korean == korean &&
        other.romanization == romanization &&
        other.translation ==
            translation &&
        other.imagePath ==
            imagePath &&
        other.note == note &&
        other.example == example &&
        other.exampleTranslation == exampleTranslation &&
        other.context == context &&
        other.createdAt ==
            createdAt &&
        other.updatedAt ==
            updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      groupId,
      korean,
      romanization,
      translation,
      imagePath,
      note,
      example,
      exampleTranslation,
      context,
      createdAt,
      updatedAt,
    );
  }

  // ============================================================
  // UTILIDADES PRIVADAS
  // ============================================================

  static int _parseInt(
      dynamic value,
      ) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }

  static String? _parseNullableString(
      dynamic value,
      ) {
    if (value == null) {
      return null;
    }

    final text =
    value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  static DateTime _parseDateTime(
      dynamic value,
      ) {
    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final parsed =
      DateTime.tryParse(value);

      if (parsed != null) {
        return parsed;
      }
    }

    return DateTime.now();
  }
}
