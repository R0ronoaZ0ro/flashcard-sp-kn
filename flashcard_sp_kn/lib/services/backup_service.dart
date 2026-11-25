import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/backup_data.dart';
import 'database_service.dart';

class BackupService {
  BackupService._();

  static final BackupService instance = BackupService._();

  final DatabaseService _db = DatabaseService.instance;

  Future<BackupData> createBackupData() async {
    final groups = await _db.getAllGroups();

    final backupGroups = <BackupGroup>[];

    for (final group in groups) {
      final cards = await _db.getFlashcardsByGroup(group.id);

      backupGroups.add(
        BackupGroup(
          name: group.name,
          createdAt: group.createdAt.toIso8601String(),
          flashcards: cards.map(
                (c) => BackupFlashcard(
              korean: c.korean,
              translation: c.translation,
              romanization: c.romanization,
              example: c.example,
              exampleTranslation: c.exampleTranslation,
              context: c.context,
              note: c.note,
            ),
          ).toList(),
        ),
      );
    }

    return BackupData(
      version: BackupData.currentVersion,
      exportedAt: DateTime.now().toIso8601String(),
      groups: backupGroups,
    );
  }

  // ============================================================
  // EXPORTAR A ARCHIVO LOCAL
  // ============================================================

  Future<ExportResult> exportAll() async {
    final backup = await createBackupData();

    return _writeBackupToCache(backup);
  }


  Future<ExportResult> exportGroup(int groupId) async {
    final group = await _db.getGroupById(groupId);

    if (group == null) {
      throw Exception('El grupo no existe.');
    }

    final cards = await _db.getFlashcardsByGroup(groupId);

    final backup = BackupData(
      version: BackupData.currentVersion,
      exportedAt: DateTime.now().toIso8601String(),
      groups: [
        BackupGroup(
          name: group.name,
          createdAt: group.createdAt.toIso8601String(),
          flashcards: cards
              .map(
                (c) => BackupFlashcard(
              korean: c.korean,
              translation: c.translation,
              romanization: c.romanization,
              example: c.example,
              exampleTranslation: c.exampleTranslation,
              context: c.context,
              note: c.note,
            ),
          )
              .toList(),
        ),
      ],
    );

    return _writeBackupToCache(backup);
  }

  Future<ExportResult> _writeBackupToCache(BackupData backup) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(backup.toMap());

    final tempDir = await getTemporaryDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final fileName = 'flashcard_backup_$timestamp.json';

    final file = File('${tempDir.path}/$fileName');

    await file.writeAsString(jsonStr, encoding: utf8);

    return ExportResult(
      filePath: file.path,
      fileName: fileName,
      groupCount: backup.groups.length,
      flashcardCount: backup.groups.fold<int>(
        0,
            (sum, g) => sum + g.flashcards.length,
      ),
    );
  }

  // ============================================================
  // COMPARTIR
  // ============================================================

  Future<void> share(ExportResult result) async {
    final file = File(result.filePath);

    if (!file.existsSync()) {
      throw Exception('El archivo temporal ya no existe.');
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        subject: 'Respaldo FlashCard SP-KN',
      ),
    );
  }

  // ============================================================
  // IMPORTAR
  // ============================================================

  Future<BackupData?> pickAndParseBackup() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final picked = result.files.single;

    String content;

    if (picked.bytes != null) {
      content = utf8.decode(picked.bytes!);
    } else if (picked.path != null) {
      content = await File(picked.path!).readAsString(encoding: utf8);
    } else {
      throw Exception('No se pudo leer el archivo.');
    }

    final decoded = jsonDecode(content);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('El archivo no tiene el formato esperado.');
    }

    final backup = BackupData.fromMap(decoded);

    if (backup.groups.isEmpty) {
      throw Exception('El respaldo no contiene grupos.');
    }

    return backup;
  }


  Future<int> importBackup(
      BackupData backup, {
        bool renameDuplicates = false,
      }) async {
    // Obtener los grupos existentes.
    final existingGroups = await _db.getAllGroups();

    // Indexar grupos por nombre normalizado.
    final Map<String, int> groupIds = {
      for (final group in existingGroups)
        group.name.trim().toLowerCase(): group.id,
    };

    // Guardar las tarjetas existentes por grupo.
    final Map<int, Set<String>> existingCards = {};

    int processedGroups = 0;

    for (final backupGroup in backup.groups) {
      final groupName = backupGroup.name.trim();

      if (groupName.isEmpty) {
        continue;
      }

      final normalizedGroupName = groupName.toLowerCase();

      // Buscar el grupo. Si no existe, crearlo.
      int? groupId = groupIds[normalizedGroupName];

      if (groupId == null) {
        final newGroup = await _db.insertGroup(groupName);

        groupId = newGroup.id;
        groupIds[normalizedGroupName] = groupId;
      }

      // Obtener las tarjetas existentes del grupo.
      final knownCards = existingCards.putIfAbsent(
        groupId,
            () => <String>{},
      );

      if (knownCards.isEmpty) {
        final cards = await _db.getFlashcardsByGroup(groupId);

        for (final card in cards) {
          knownCards.add(
            '${card.korean.trim().toLowerCase()}|'
                '${card.translation.trim().toLowerCase()}',
          );
        }
      }

      // Importar únicamente tarjetas nuevas.
      for (final card in backupGroup.flashcards) {
        final korean = card.korean.trim();
        final translation = card.translation.trim();

        if (korean.isEmpty || translation.isEmpty) {
          continue;
        }

        final cardKey =
            '${korean.toLowerCase()}|${translation.toLowerCase()}';

        if (knownCards.contains(cardKey)) {
          continue;
        }

        await _db.insertFlashcard(
          groupId: groupId,
          korean: korean,
          translation: translation,
          romanization: card.romanization,
          example: card.example,
          exampleTranslation: card.exampleTranslation,
          context: card.context,
          note: card.note,
          imagePath: null,
        );

        // Registrar inmediatamente para evitar duplicados
        // incluso dentro del mismo archivo de respaldo.
        knownCards.add(cardKey);
      }

      processedGroups++;
    }

    return processedGroups;
  }


  // ============================================================
  // UTILIDADES
  // ============================================================

  String _generateUniqueName(String base, Set<String> existing) {
    int counter = 2;

    while (true) {
      final candidate = '$base ($counter)';

      if (!existing.contains(candidate.toLowerCase())) {
        return candidate;
      }

      counter++;
    }
  }
}

// ============================================================
// RESULTADO DE EXPORTAR
// ============================================================

class ExportResult {
  final String filePath;
  final String fileName;
  final int groupCount;
  final int flashcardCount;

  ExportResult({
    required this.filePath,
    required this.fileName,
    required this.groupCount,
    required this.flashcardCount,
  });
}