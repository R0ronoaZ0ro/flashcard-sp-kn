import 'package:flutter/foundation.dart';

import '../models/flashcard.dart';
import '../models/flashcard_group.dart';
import '../services/database_service.dart';

class FlashcardProvider extends ChangeNotifier {
  // ============================================================
  // DEPENDENCIAS
  // ============================================================

  final DatabaseService _database =
      DatabaseService.instance;

  // ============================================================
  // ESTADO DE GRUPOS
  // ============================================================

  List<FlashcardGroup> _groups = [];

  List<FlashcardGroup> get groups =>
      List.unmodifiable(_groups);

  // ============================================================
  // ESTADO DE FLASHCARDS
  // ============================================================

  List<Flashcard> _flashcards = [];

  List<Flashcard> get flashcards =>
      List.unmodifiable(_flashcards);

  // ============================================================
  // GRUPO SELECCIONADO
  // ============================================================

  int? _selectedGroupId;

  int? get selectedGroupId =>
      _selectedGroupId;

  FlashcardGroup? get selectedGroup {
    if (_selectedGroupId == null) {
      return null;
    }

    for (final group in _groups) {
      if (group.id ==
          _selectedGroupId) {
        return group;
      }
    }

    return null;
  }

  // ============================================================
  // FLASHCARD ACTUAL
  // ============================================================

  int _currentFlashcardIndex = 0;

  int get currentFlashcardIndex =>
      _currentFlashcardIndex;

  Flashcard? get currentFlashcard {
    if (_flashcards.isEmpty) {
      return null;
    }

    if (_currentFlashcardIndex < 0 ||
        _currentFlashcardIndex >=
            _flashcards.length) {
      return null;
    }

    return _flashcards[
    _currentFlashcardIndex];
  }

  // ============================================================
  // ESTADO GENERAL
  // ============================================================

  bool _isLoading = false;

  bool get isLoading =>
      _isLoading;

  bool _isSaving = false;

  bool get isSaving =>
      _isSaving;

  String? _error;

  String? get error =>
      _error;

  // ============================================================
  // INICIALIZACIÓN
  // ============================================================

  Future<void> initialize() async {
    _setLoading(true);

    try {
      _clearError();

      await loadGroups();

      if (_selectedGroupId != null) {
        await loadFlashcards(
          _selectedGroupId!,
        );
      }
    } catch (e) {
      _setError(
        'No se pudieron cargar los datos.',
      );
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // CARGAR GRUPOS
  // ============================================================

  Future<void> loadGroups() async {
    try {
      _clearError();

      final groups =
      await _database
          .getAllGroups();

      _groups = groups;

      // Si el grupo seleccionado
      // ya no existe, limpiamos
      // la selección.
      if (_selectedGroupId != null) {
        final exists =
        _groups.any(
              (group) =>
          group.id ==
              _selectedGroupId,
        );

        if (!exists) {
          _selectedGroupId =
          null;

          _flashcards = [];

          _currentFlashcardIndex =
          0;
        }
      }

      notifyListeners();
    } catch (e) {
      _setError(
        'No se pudieron cargar los grupos.',
      );

      rethrow;
    }
  }

  // ============================================================
  // CREAR GRUPO
  // ============================================================

  Future<FlashcardGroup>
  createGroup(
      String name,
      ) async {
    final cleanName =
    name.trim();

    if (cleanName.isEmpty) {
      throw Exception(
        'El nombre del grupo no puede estar vacío.',
      );
    }

    _setSaving(true);

    try {
      _clearError();

      final group =
      await _database
          .insertGroup(
        cleanName,
      );

      await loadGroups();

      return group;
    } catch (e) {
      _setError(
        'No se pudo crear el grupo.',
      );

      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // ACTUALIZAR GRUPO
  // ============================================================

  Future<FlashcardGroup?>
  updateGroup({
    required int id,
    required String name,
  }) async {
    final cleanName =
    name.trim();

    if (cleanName.isEmpty) {
      throw Exception(
        'El nombre del grupo no puede estar vacío.',
      );
    }

    _setSaving(true);

    try {
      _clearError();

      final group =
      await _database
          .updateGroup(
        id: id,
        name: cleanName,
      );

      await loadGroups();

      return group;
    } catch (e) {
      _setError(
        'No se pudo actualizar el grupo.',
      );

      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // ELIMINAR GRUPO
  // ============================================================

  Future<void> deleteGroup(
      int groupId,
      ) async {
    _setSaving(true);

    try {
      _clearError();

      await _database
          .deleteGroup(
        groupId,
      );

      if (_selectedGroupId ==
          groupId) {
        _selectedGroupId =
        null;

        _flashcards = [];

        _currentFlashcardIndex =
        0;
      }

      await loadGroups();
    } catch (e) {
      _setError(
        'No se pudo eliminar el grupo.',
      );

      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // SELECCIONAR GRUPO
  // ============================================================

  Future<void> selectGroup(
      int groupId,
      ) async {
    final exists =
    _groups.any(
          (group) =>
      group.id == groupId,
    );

    if (!exists) {
      throw Exception(
        'El grupo seleccionado no existe.',
      );
    }

    _selectedGroupId =
        groupId;

    _currentFlashcardIndex =
    0;

    notifyListeners();

    await loadFlashcards(
      groupId,
    );
  }

  // ============================================================
  // LIMPIAR GRUPO SELECCIONADO
  // ============================================================

  void clearSelectedGroup() {
    _selectedGroupId =
    null;

    _flashcards = [];

    _currentFlashcardIndex =
    0;

    notifyListeners();
  }

  // ============================================================
  // CARGAR FLASHCARDS
  // ============================================================

  Future<void> loadFlashcards(
      int groupId,
      ) async {
    try {
      _clearError();

      final cards =
      await _database
          .getFlashcardsByGroup(
        groupId,
      );

      _flashcards = cards;

      if (_flashcards.isEmpty) {
        _currentFlashcardIndex =
        0;
      } else if (_currentFlashcardIndex >=
          _flashcards.length) {
        _currentFlashcardIndex =
            _flashcards.length - 1;
      }

      notifyListeners();
    } catch (e) {
      _setError(
        'No se pudieron cargar las FlashCards.',
      );

      rethrow;
    }
  }

  // ============================================================
  // CREAR FLASHCARD
  // ============================================================

  Future<Flashcard>
  createFlashcard({
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
    final cleanKorean =
    korean.trim();

    final cleanTranslation =
    translation.trim();

    if (cleanKorean.isEmpty) {
      throw Exception(
        'El texto coreano no puede estar vacío.',
      );
    }

    if (cleanTranslation.isEmpty) {
      throw Exception(
        'La traducción no puede estar vacía.',
      );
    }

    _setSaving(true);

    try {
      _clearError();

      final flashcard =
      await _database
          .insertFlashcard(
        groupId:
        groupId,
        korean:
        cleanKorean,
        romanization:
        romanization,
        translation:
        cleanTranslation,
        imagePath:
        imagePath,
        note:
        note,
        example:
        example,
        exampleTranslation:
        exampleTranslation,
        context:
        context,
      );

      _selectedGroupId =
          groupId;

      await loadFlashcards(
        groupId,
      );

      // Después de crear una tarjeta,
      // mostramos la tarjeta recién creada.
      final index =
      _flashcards.indexWhere(
            (card) =>
        card.id ==
            flashcard.id,
      );

      if (index >= 0) {
        _currentFlashcardIndex =
            index;
      }

      await loadGroups();

      notifyListeners();

      return flashcard;
    } catch (e) {
      _setError(
        'No se pudo crear la FlashCard.',
      );

      rethrow;
    } finally {
      _setSaving(false);
    }
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
    final cleanKorean =
    korean.trim();

    final cleanTranslation =
    translation.trim();

    if (cleanKorean.isEmpty) {
      throw Exception(
        'El texto coreano no puede estar vacío.',
      );
    }

    if (cleanTranslation.isEmpty) {
      throw Exception(
        'La traducción no puede estar vacía.',
      );
    }

    _setSaving(true);

    try {
      _clearError();

      final updated =
      await _database
          .updateFlashcard(
        id: id,
        groupId:
        groupId,
        korean:
        cleanKorean,
        romanization:
        romanization,
        translation:
        cleanTranslation,
        imagePath:
        imagePath,
        note:
        note,
        example:
        example,
        exampleTranslation:
        exampleTranslation,
        context:
        context,
      );

      if (updated == null) {
        throw Exception(
          'La FlashCard no existe.',
        );
      }

      _selectedGroupId =
          groupId;

      await loadFlashcards(
        groupId,
      );

      final index =
      _flashcards.indexWhere(
            (card) =>
        card.id == id,
      );

      if (index >= 0) {
        _currentFlashcardIndex =
            index;
      }

      await loadGroups();

      notifyListeners();

      return updated;
    } catch (e) {
      _setError(
        'No se pudo actualizar la FlashCard.',
      );

      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // ELIMINAR FLASHCARD
  // ============================================================

  Future<void>
  deleteFlashcard(
      int flashcardId,
      ) async {
    _setSaving(true);

    try {
      _clearError();

      final groupId =
          _selectedGroupId;

      await _database
          .deleteFlashcard(
        flashcardId,
      );

      if (groupId != null) {
        await loadFlashcards(
          groupId,
        );

        await loadGroups();
      } else {
        _flashcards.removeWhere(
              (card) =>
          card.id ==
              flashcardId,
        );

        if (_flashcards.isEmpty) {
          _currentFlashcardIndex =
          0;
        } else if (_currentFlashcardIndex >=
            _flashcards.length) {
          _currentFlashcardIndex =
              _flashcards.length - 1;
        }

        notifyListeners();
      }
    } catch (e) {
      _setError(
        'No se pudo eliminar la FlashCard.',
      );

      rethrow;
    } finally {
      _setSaving(false);
    }
  }
  // ============================================================
  // OBTENER FLASHCARDS DE UN GRUPO (SIN CAMBIAR EL ESTADO)
  // ============================================================

  Future<List<Flashcard>> getFlashcards(
      int groupId,
      ) async {
    try {
      return await _database.getFlashcardsByGroup(
        groupId,
      );
    } catch (e) {
      _setError(
        'No se pudieron obtener las FlashCards.',
      );

      return [];
    }
  }

  // ============================================================
  // BUSCAR FLASHCARDS
  // ============================================================

  Future<List<Flashcard>>
  searchFlashcards(
      String query,
      ) async {
    if (_selectedGroupId ==
        null) {
      return [];
    }

    try {
      return await _database
          .searchFlashcards(
        groupId:
        _selectedGroupId!,
        query:
        query,
      );
    } catch (e) {
      _setError(
        'No se pudieron buscar las FlashCards.',
      );

      return [];
    }
  }

  // ============================================================
  // ABRIR UNA FLASHCARD POR SU ID
  // ============================================================

  bool selectFlashcardById(int flashcardId) {
    final index = _flashcards.indexWhere(
          (card) => card.id == flashcardId,
    );

    if (index < 0) {
      return false;
    }

    _currentFlashcardIndex = index;
    notifyListeners();
    return true;
  }

  // ============================================================
  // MOVER FLASHCARD A OTRO GRUPO
  // ============================================================

  Future<void> moveFlashcardToGroup({
    required int flashcardId,
    required int destinationGroupId,
  }) async {
    _setSaving(true);
    try {
      _clearError();
      await _database.moveFlashcardToGroup(
        flashcardId: flashcardId,
        destinationGroupId: destinationGroupId,
      );

      final selectedGroupId = _selectedGroupId;
      if (selectedGroupId != null) {
        await loadFlashcards(selectedGroupId);
      }
      await loadGroups();
      notifyListeners();
    } catch (e) {
      _setError('No se pudo mover la FlashCard al grupo seleccionado.');
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  // ============================================================
  // SIGUIENTE FLASHCARD
  // ============================================================

  void nextFlashcard() {
    if (_flashcards.isEmpty) {
      return;
    }

    if (_currentFlashcardIndex <
        _flashcards.length - 1) {
      _currentFlashcardIndex++;

      notifyListeners();
    }
  }

  // ============================================================
  // FLASHCARD ANTERIOR
  // ============================================================

  void previousFlashcard() {
    if (_flashcards.isEmpty) {
      return;
    }

    if (_currentFlashcardIndex >
        0) {
      _currentFlashcardIndex--;

      notifyListeners();
    }
  }

  // ============================================================
  // IR A UNA FLASHCARD
  // ============================================================

  void goToFlashcard(
      int index,
      ) {
    if (_flashcards.isEmpty) {
      return;
    }

    if (index < 0 ||
        index >=
            _flashcards.length) {
      return;
    }

    _currentFlashcardIndex =
        index;

    notifyListeners();
  }

  // ============================================================
  // PRIMERA FLASHCARD
  // ============================================================

  void firstFlashcard() {
    if (_flashcards.isEmpty) {
      return;
    }

    _currentFlashcardIndex =
    0;

    notifyListeners();
  }

  // ============================================================
  // ÚLTIMA FLASHCARD
  // ============================================================

  void lastFlashcard() {
    if (_flashcards.isEmpty) {
      return;
    }

    _currentFlashcardIndex =
        _flashcards.length - 1;

    notifyListeners();
  }

  // ============================================================
  // ¿HAY ANTERIOR?
  // ============================================================

  bool get hasPreviousFlashcard {
    return _flashcards.isNotEmpty &&
        _currentFlashcardIndex >
            0;
  }

  // ============================================================
  // ¿HAY SIGUIENTE?
  // ============================================================

  bool get hasNextFlashcard {
    return _flashcards.isNotEmpty &&
        _currentFlashcardIndex <
            _flashcards.length - 1;
  }

  // ============================================================
  // INFORMACIÓN DE POSICIÓN
  // ============================================================

  String get flashcardPositionText {
    if (_flashcards.isEmpty) {
      return '0 / 0';
    }

    return '${_currentFlashcardIndex + 1}'
        ' / '
        '${_flashcards.length}';
  }

  // ============================================================
  // RECARGAR TODO
  // ============================================================

  Future<void> refresh() async {
    _setLoading(true);

    try {
      await loadGroups();

      if (_selectedGroupId !=
          null) {
        await loadFlashcards(
          _selectedGroupId!,
        );
      }
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================
  // ESTADO DE LOADING
  // ============================================================

  void _setLoading(
      bool value,
      ) {
    _isLoading =
        value;

    notifyListeners();
  }

  // ============================================================
  // ESTADO DE GUARDADO
  // ============================================================

  void _setSaving(
      bool value,
      ) {
    _isSaving =
        value;

    notifyListeners();
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _setError(
      String message,
      ) {
    _error =
        message;

    notifyListeners();
  }

  void _clearError() {
    _error =
    null;
  }

  // ============================================================
  // LIMPIAR ERROR PÚBLICAMENTE
  // ============================================================

  void clearError() {
    if (_error == null) {
      return;
    }

    _error =
    null;

    notifyListeners();
  }
}
