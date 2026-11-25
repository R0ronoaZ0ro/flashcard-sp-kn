import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/flashcard.dart';
import '../models/flashcard_group.dart';

class DatabaseService {
  // ============================================================
  // SINGLETON
  // ============================================================

  DatabaseService._internal();

  static final DatabaseService instance =
  DatabaseService._internal();

  Database? _database;

  // ============================================================
  // CONFIGURACIÓN
  // ============================================================

  static const String _databaseName =
      'flashcard_sp_kn.db';

  static const int _databaseVersion = 2;

  // ============================================================
  // TABLAS
  // ============================================================

  static const String _groupsTable =
      'flashcard_groups';

  static const String _flashcardsTable =
      'flashcards';

  // ============================================================
  // DATABASE GETTER
  // ============================================================

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  // ============================================================
  // INICIALIZAR DATABASE
  // ============================================================

  Future<Database> _initDatabase() async {
    final databasesPath =
    await getDatabasesPath();

    final path = join(
      databasesPath,
      _databaseName,
    );

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ============================================================
  // CONFIGURAR SQLITE
  // ============================================================

  Future<void> _onConfigure(
      Database db,
      ) async {
    // Activa foreign keys para que:
    //
    // grupo
    //   ↓
    // flashcards
    //
    // y al eliminar el grupo se eliminen
    // automáticamente sus tarjetas.

    await db.execute(
      'PRAGMA foreign_keys = ON',
    );
  }

  // ============================================================
  // CREAR TABLAS
  // ============================================================

  Future<void> _onCreate(
      Database db,
      int version,
      ) async {
    // ----------------------------------------------------------
    // TABLA DE GRUPOS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE $_groupsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ----------------------------------------------------------
    // TABLA DE FLASHCARDS
    // ----------------------------------------------------------

    await db.execute('''
  CREATE TABLE $_flashcardsTable (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    group_id INTEGER NOT NULL,

    korean TEXT NOT NULL,

    romanization TEXT,

    translation TEXT NOT NULL,

    image_path TEXT,

    note TEXT,

    example TEXT,

    example_translation TEXT,

    context TEXT,

    created_at TEXT NOT NULL,

    updated_at TEXT NOT NULL,

    FOREIGN KEY (group_id)
      REFERENCES $_groupsTable(id)
      ON DELETE CASCADE
      ON UPDATE CASCADE
  )
''');

    // ----------------------------------------------------------
    // ÍNDICE PARA BUSCAR TARJETAS POR GRUPO
    // ----------------------------------------------------------

    await db.execute('''
      CREATE INDEX idx_flashcards_group_id
      ON $_flashcardsTable(group_id)
    ''');

    // ----------------------------------------------------------
    // ÍNDICE PARA ORDENAR POR FECHA
    // ----------------------------------------------------------

    await db.execute('''
      CREATE INDEX idx_flashcards_created_at
      ON $_flashcardsTable(created_at)
    ''');
  }

  // ============================================================
  // ACTUALIZAR BASE DE DATOS
  // ============================================================

  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $_flashcardsTable '
            'ADD COLUMN romanization TEXT',
      );

      await db.execute(
        'ALTER TABLE $_flashcardsTable '
            'ADD COLUMN example TEXT',
      );

      await db.execute(
        'ALTER TABLE $_flashcardsTable '
            'ADD COLUMN example_translation TEXT',
      );

      await db.execute(
        'ALTER TABLE $_flashcardsTable '
            'ADD COLUMN context TEXT',
      );
    }
  }

  // ============================================================
  // OBTENER TODOS LOS GRUPOS
  // ============================================================

  Future<List<FlashcardGroup>>
  getAllGroups() async {
    final db =
    await database;

    final rows = await db.query(
      _groupsTable,
      orderBy: 'created_at ASC',
    );

    final groups =
    <FlashcardGroup>[];

    for (final row in rows) {
      final group =
      FlashcardGroup.fromMap(
        row,
      );

      final count =
      await countFlashcardsByGroup(
        group.id,
      );

      groups.add(
        group.copyWith(
          flashcardCount: count,
        ),
      );
    }

    return groups;
  }

  // ============================================================
  // OBTENER GRUPO POR ID
  // ============================================================

  Future<FlashcardGroup?>
  getGroupById(
      int id,
      ) async {
    final db =
    await database;

    final rows = await db.query(
      _groupsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    final group =
    FlashcardGroup.fromMap(
      rows.first,
    );

    final count =
    await countFlashcardsByGroup(
      id,
    );

    return group.copyWith(
      flashcardCount: count,
    );
  }

  // ============================================================
  // CREAR GRUPO
  // ============================================================

  Future<FlashcardGroup>
  insertGroup(
      String name,
      ) async {
    final db =
    await database;

    final now =
    DateTime.now()
        .toIso8601String();

    final id =
    await db.insert(
      _groupsTable,
      {
        'name': name.trim(),
        'created_at': now,
        'updated_at': now,
      },
    );

    final group =
    await getGroupById(id);

    if (group == null) {
      throw Exception(
        'No se pudo recuperar el grupo creado.',
      );
    }

    return group;
  }

  // ============================================================
  // ACTUALIZAR GRUPO
  // ============================================================

  Future<FlashcardGroup?>
  updateGroup({
    required int id,
    required String name,
  }) async {
    final db =
    await database;

    await db.update(
      _groupsTable,
      {
        'name': name.trim(),
        'updated_at':
        DateTime.now()
            .toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    return getGroupById(id);
  }

  // ============================================================
  // ELIMINAR GRUPO
  // ============================================================

  Future<void> deleteGroup(
      int groupId,
      ) async {
    final db =
    await database;

    await db.delete(
      _groupsTable,
      where: 'id = ?',
      whereArgs: [groupId],
    );

    // Gracias a:
    //
    // ON DELETE CASCADE
    //
    // SQLite elimina automáticamente
    // las FlashCards pertenecientes al grupo.
  }

  // ============================================================
  // CONTAR FLASHCARDS
  // ============================================================

  Future<int>
  countFlashcardsByGroup(
      int groupId,
      ) async {
    final db =
    await database;

    final result =
    await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM $_flashcardsTable
      WHERE group_id = ?
      ''',
      [groupId],
    );

    if (result.isEmpty) {
      return 0;
    }

    final value =
    result.first['total'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    ) ??
        0;
  }

  // ============================================================
  // OBTENER TODAS LAS FLASHCARDS DE UN GRUPO
  // ============================================================

  Future<List<Flashcard>>
  getFlashcardsByGroup(
      int groupId,
      ) async {
    final db =
    await database;

    final rows = await db.query(
      _flashcardsTable,
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'created_at ASC',
    );

    return rows
        .map(
      Flashcard.fromMap,
    )
        .toList();
  }

  // ============================================================
  // OBTENER FLASHCARD POR ID
  // ============================================================

  Future<Flashcard?>
  getFlashcardById(
      int id,
      ) async {
    final db =
    await database;

    final rows = await db.query(
      _flashcardsTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return Flashcard.fromMap(
      rows.first,
    );
  }

  // ============================================================
  // CREAR FLASHCARD
  // ============================================================

  Future<Flashcard>
  insertFlashcard({
    required int groupId,
    required String korean,
    String? romanization,
    required String translation,
    String? imagePath,
    String? note,
    String? example,
    String? exampleTranslation,
    String? context,
  }) async {
    final db =
    await database;

    // Verificar que el grupo exista.
    final group =
    await getGroupById(
      groupId,
    );

    if (group == null) {
      throw Exception(
        'El grupo seleccionado no existe.',
      );
    }

    final now =
    DateTime.now()
        .toIso8601String();

    final id =
    await db.insert(
      _flashcardsTable,
      {
        'group_id': groupId,
        'korean': korean.trim(),
        'romanization':
        _cleanNullableValue(romanization),
        'translation':
        translation.trim(),
        'image_path':
        _cleanNullableValue(
          imagePath,
        ),
        'note':
        _cleanNullableValue(
          note,
        ),
        'example':
        _cleanNullableValue(example),
        'example_translation':
        _cleanNullableValue(exampleTranslation),
        'context':
        _cleanNullableValue(context),
        'created_at': now,
        'updated_at': now,
      },
    );

    final flashcard =
    await getFlashcardById(id);

    if (flashcard == null) {
      throw Exception(
        'No se pudo recuperar la FlashCard creada.',
      );
    }

    return flashcard;
  }

  // ============================================================
  // ACTUALIZAR FLASHCARD
  // ============================================================

  Future<Flashcard?>
  updateFlashcard({
    required int id,
    required int groupId,
    required String korean,
    String? romanization,
    required String translation,
    String? imagePath,
    String? note,
    String? example,
    String? exampleTranslation,
    String? context,
  }) async {
    final db =
    await database;

    final existing =
    await getFlashcardById(id);

    if (existing == null) {
      return null;
    }

    final group =
    await getGroupById(
      groupId,
    );

    if (group == null) {
      throw Exception(
        'El grupo seleccionado no existe.',
      );
    }

    await db.update(
      _flashcardsTable,
      {
        'group_id': groupId,
        'korean': korean.trim(),
        'romanization':
        _cleanNullableValue(romanization),
        'translation':
        translation.trim(),
        'image_path':
        _cleanNullableValue(
          imagePath,
        ),
        'note':
        _cleanNullableValue(
          note,
        ),
        'example':
        _cleanNullableValue(example),
        'example_translation':
        _cleanNullableValue(exampleTranslation),
        'context':
        _cleanNullableValue(context),
        'updated_at':
        DateTime.now()
            .toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );

    return getFlashcardById(id);
  }

  // ============================================================
  // MOVER FLASHCARD A OTRO GRUPO
  // ============================================================

  Future<void> moveFlashcardToGroup({
    required int flashcardId,
    required int destinationGroupId,
  }) async {
    final db = await database;

    final card = await getFlashcardById(flashcardId);
    if (card == null) {
      throw Exception('La FlashCard no existe.');
    }

    final destination = await getGroupById(destinationGroupId);
    if (destination == null) {
      throw Exception('El grupo de destino no existe.');
    }

    if (card.groupId == destinationGroupId) {
      return;
    }

    final now = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      await txn.update(
        _flashcardsTable,
        {
          'group_id': destinationGroupId,
          'updated_at': now,
        },
        where: 'id = ?',
        whereArgs: [flashcardId],
      );

      await txn.update(
        _groupsTable,
        {'updated_at': now},
        where: 'id = ?',
        whereArgs: [card.groupId],
      );

      await txn.update(
        _groupsTable,
        {'updated_at': now},
        where: 'id = ?',
        whereArgs: [destinationGroupId],
      );
    });
  }

  // ============================================================
  // ELIMINAR FLASHCARD
  // ============================================================

  Future<void> deleteFlashcard(
      int id,
      ) async {
    final db =
    await database;

    await db.delete(
      _flashcardsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // BUSCAR FLASHCARDS
  // ============================================================

  Future<List<Flashcard>>
  searchFlashcards({
    required int groupId,
    required String query,
  }) async {
    final db =
    await database;

    final cleanQuery =
    query.trim();

    if (cleanQuery.isEmpty) {
      return getFlashcardsByGroup(
        groupId,
      );
    }

    final rows = await db.query(
      _flashcardsTable,
      where: '''
        group_id = ?
        AND (
          korean LIKE ?
          OR translation LIKE ?
          OR note LIKE ?
        )
      ''',
      whereArgs: [
        groupId,
        '%$cleanQuery%',
        '%$cleanQuery%',
        '%$cleanQuery%',
      ],
      orderBy: 'created_at ASC',
    );

    return rows
        .map(
      Flashcard.fromMap,
    )
        .toList();
  }

  // ============================================================
  // TOTAL DE GRUPOS
  // ============================================================

  Future<int>
  countGroups() async {
    final db =
    await database;

    final result =
    await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM $_groupsTable
      ''',
    );

    if (result.isEmpty) {
      return 0;
    }

    final value =
    result.first['total'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    ) ??
        0;
  }

  // ============================================================
  // TOTAL DE FLASHCARDS
  // ============================================================

  Future<int>
  countAllFlashcards() async {
    final db =
    await database;

    final result =
    await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM $_flashcardsTable
      ''',
    );

    if (result.isEmpty) {
      return 0;
    }

    final value =
    result.first['total'];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString(),
    ) ??
        0;
  }

  // ============================================================
  // ELIMINAR TODA LA BASE DE DATOS
  // ============================================================

  Future<void>
  deleteDatabaseFile() async {
    await close();

    final databasesPath =
    await getDatabasesPath();

    final path = join(
      databasesPath,
      _databaseName,
    );

    await deleteDatabase(
      path,
    );
  }

  // ============================================================
  // CERRAR BASE DE DATOS
  // ============================================================

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();

      _database = null;
    }
  }

  // ============================================================
  // VALORES NULL
  // ============================================================

  String? _cleanNullableValue(
      String? value,
      ) {
    if (value == null) {
      return null;
    }

    final clean =
    value.trim();

    if (clean.isEmpty) {
      return null;
    }

    return clean;
  }
}
