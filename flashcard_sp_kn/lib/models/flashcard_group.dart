class FlashcardGroup {
  final int id;

  /// Nombre que verá el usuario.
  ///
  /// Ejemplo:
  /// "Saludos"
  /// "Verbos"
  /// "Comida"
  final String name;

  /// Cantidad de FlashCards pertenecientes
  /// a este grupo.
  final int flashcardCount;

  /// Fecha de creación.
  final DateTime createdAt;

  /// Fecha de última modificación.
  final DateTime updatedAt;

  const FlashcardGroup({
    required this.id,
    required this.name,
    required this.flashcardCount,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // CREAR DESDE MAP
  // ============================================================

  factory FlashcardGroup.fromMap(
      Map<String, dynamic> map,
      ) {
    return FlashcardGroup(
      id: _parseInt(
        map['id'],
      ),
      name:
      (map['name'] ?? '').toString(),
      flashcardCount:
      _parseInt(
        map['flashcard_count'],
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
      'name': name,
      'flashcard_count':
      flashcardCount,
      'created_at':
      createdAt.toIso8601String(),
      'updated_at':
      updatedAt.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  FlashcardGroup copyWith({
    int? id,
    String? name,
    int? flashcardCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FlashcardGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      flashcardCount:
      flashcardCount ??
          this.flashcardCount,
      createdAt:
      createdAt ?? this.createdAt,
      updatedAt:
      updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // UTILIDADES
  // ============================================================

  bool get isEmpty {
    return name.trim().isEmpty;
  }

  bool get hasFlashcards {
    return flashcardCount > 0;
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return 'FlashcardGroup('
        'id: $id, '
        'name: $name, '
        'flashcardCount: '
        '$flashcardCount, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }

  // ============================================================
  // EQUALITY
  // ============================================================

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

    return other is FlashcardGroup &&
        other.id == id &&
        other.name == name &&
        other.flashcardCount ==
            flashcardCount &&
        other.createdAt ==
            createdAt &&
        other.updatedAt ==
            updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      flashcardCount,
      createdAt,
      updatedAt,
    );
  }

  // ============================================================
  // PARSERS
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
