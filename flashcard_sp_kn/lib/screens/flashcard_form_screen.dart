import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/flashcard.dart';
import '../providers/flashcard_provider.dart';
import '../services/ai_service.dart';

class FlashcardFormScreen extends StatefulWidget {
  final int groupId;
  final Flashcard? flashcard;

  const FlashcardFormScreen({
    super.key,
    required this.groupId,
    this.flashcard,
  });

  bool get isEditing => flashcard != null;

  @override
  State<FlashcardFormScreen> createState() =>
      _FlashcardFormScreenState();
}

class _FlashcardFormScreenState
    extends State<FlashcardFormScreen> {
  final _formKey =
  GlobalKey<FormState>();

  final TextEditingController
  _koreanController =
  TextEditingController();

  final TextEditingController
  _romanizationController =
  TextEditingController();

  final TextEditingController
  _translationController =
  TextEditingController();

  final TextEditingController
  _noteController =
  TextEditingController();

  final TextEditingController
  _exampleController =
  TextEditingController();

  final TextEditingController
  _exampleTranslationController =
  TextEditingController();

  final TextEditingController
  _contextController =
  TextEditingController();

  final ImagePicker _imagePicker =
  ImagePicker();

  String? _imagePath;

  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isTranslating = false;

  final AiService _ai = AiService.instance;

  @override
  void initState() {
    super.initState();

    _loadExistingFlashcard();
  }

  // ============================================================
  // CARGAR FLASHCARD EXISTENTE
  // ============================================================

  void _loadExistingFlashcard() {
    final flashcard =
        widget.flashcard;

    if (flashcard == null) {
      return;
    }

    _koreanController.text =
        flashcard.korean;

    _romanizationController.text =
        flashcard.romanization ?? '';

    _translationController.text =
        flashcard.translation;

    _noteController.text =
        flashcard.note ?? '';

    _exampleController.text =
        flashcard.example ?? '';

    _exampleTranslationController.text =
        flashcard.exampleTranslation ?? '';

    _contextController.text =
        flashcard.context ?? '';

    final image =
        flashcard.imagePath;

    if (image != null &&
        image.trim().isNotEmpty) {
      _imagePath = image;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _koreanController.dispose();
    _romanizationController.dispose();
    _translationController.dispose();
    _noteController.dispose();
    _exampleController.dispose();
    _exampleTranslationController.dispose();
    _contextController.dispose();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      appBar:
      _buildAppBar(context),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child:
                SingleChildScrollView(
                  physics:
                  const BouncingScrollPhysics(),
                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    30,
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      _buildHeader(
                        context,
                      ),

                      const SizedBox(
                        height: 28,
                      ),

                      _buildKoreanField(
                        context,
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      _buildAiButton(
                        context,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      _buildRomanizationField(
                        context,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      _buildTranslationField(
                        context,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      _buildExampleField(
                        context,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      _buildExampleTranslationField(
                        context,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      _buildContextField(
                        context,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      _buildImageSection(
                        context,
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      _buildNoteField(
                        context,
                      ),

                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  ),

                ),
              ),

              _buildBottomButtons(
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget
  _buildAppBar(
      BuildContext context,
      ) {
    return AppBar(
      leading:
      IconButton(
        tooltip: 'Volver',
        icon:
        const Icon(
          Icons
              .arrow_back_rounded,
        ),
        onPressed:
        _isSaving ||
            _isDeleting
            ? null
            : () {
          Navigator.pop(
            context,
          );
        },
      ),
      title: Text(
        widget.isEditing
            ? 'EDITAR FLASHCARD'
            : 'NUEVA FLASHCARD',
        style:
        const TextStyle(
          fontWeight:
          FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
      BuildContext context,
      ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        22,
      ),
      decoration:
      BoxDecoration(
        color:
        colorScheme.primary
            .withValues(
          alpha: 0.07,
        ),
        borderRadius:
        BorderRadius.circular(
          24,
        ),
        border:
        Border.all(
          color:
          colorScheme.primary
              .withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration:
            BoxDecoration(
              gradient:
              LinearGradient(
                colors: [
                  colorScheme
                      .primary,
                  colorScheme
                      .secondary,
                ],
              ),
              borderRadius:
              BorderRadius
                  .circular(
                16,
              ),
            ),
            child:
            const Icon(
              Icons.style_rounded,
              color:
              Colors.white,
              size: 27,
            ),
          ),

          const SizedBox(
            width: 15,
          ),

          Expanded(
            child:
            Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .start,
              children: [
                Text(
                  widget.isEditing
                      ? 'Editar FlashCard'
                      : 'Crear FlashCard',
                  style:
                  const TextStyle(
                    fontSize: 20,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  widget.isEditing
                      ? 'Modifica el contenido de tu tarjeta.'
                      : 'Agrega una nueva tarjeta a tu grupo.',
                  style:
                  TextStyle(
                    color:
                    colorScheme
                        .onSurface
                        .withValues(
                      alpha: 0.60,
                    ),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CAMPO COREANO
  // ============================================================

  Widget _buildKoreanField(
      BuildContext context,
      ) {
    return _buildFieldContainer(
      context,
      child:
      TextFormField(
        controller:
        _koreanController,
        keyboardType:
        TextInputType.text,
        textInputAction:
        TextInputAction.next,
        maxLines: 4,
        minLines: 2,
        textCapitalization:
        TextCapitalization.none,
        decoration:
        _inputDecoration(
          context,
          label: '한국어',
          hint:
          '한국어로 입력하세요',
          icon:
          Icons.language_rounded,
        ),
        validator: (value) {
          if (value == null ||
              value.trim().isEmpty) {
            return 'Escribe el texto en coreano.';
          }

          return null;
        },
      ),
    );
  }
  // ============================================================
  // BOTÓN TRADUCIR Y COMPLETAR (IA)
  // ============================================================

  Widget _buildAiButton(
      BuildContext context,
      ) {
    final colorScheme =
        Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _isTranslating
            ? null
            : _translateAndComplete,
        icon: _isTranslating
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Icon(
          Icons.auto_awesome_rounded,
          size: 20,
        ),
        label: Text(
          _isTranslating
              ? 'Traduciendo...'
              : 'Traducir y completar',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor:
          colorScheme.primary,
          foregroundColor:
          colorScheme.onPrimary,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
  // ============================================================
  // CAMPO ROMANIZACIÓN
  // ============================================================

  Widget _buildRomanizationField(
      BuildContext context,
      ) {
    return _buildFieldContainer(
      context,
      child: TextFormField(
        controller: _romanizationController,
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.next,
        maxLines: 2,
        minLines: 1,
        textCapitalization: TextCapitalization.none,
        decoration: _inputDecoration(
          context,
          label: 'Romanización',
          hint: 'Ej: eomma',
          icon: Icons.abc_rounded,
        ),
      ),
    );
  }

  // ============================================================
  // CAMPO EJEMPLO (coreano)
  // ============================================================

  Widget _buildExampleField(
      BuildContext context,
      ) {
    return _buildFieldContainer(
      context,
      child: TextFormField(
        controller: _exampleController,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        maxLines: 4,
        minLines: 2,
        textCapitalization: TextCapitalization.none,
        decoration: _inputDecoration(
          context,
          label: 'Ejemplo (coreano)',
          hint: 'Oración de ejemplo...',
          icon: Icons.format_quote_rounded,
        ),
      ),
    );
  }
  // ============================================================
  // CAMPO TRADUCCIÓN DEL EJEMPLO
  // ============================================================

  Widget _buildExampleTranslationField(
      BuildContext context,
      ) {
    return _buildFieldContainer(
      context,
      child: TextFormField(
        controller: _exampleTranslationController,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        maxLines: 3,
        minLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: _inputDecoration(
          context,
          label: 'Traducción del ejemplo',
          hint: 'Traducción al español...',
          icon: Icons.translate_rounded,
        ),
      ),
    );
  }

  // ============================================================
  // CAMPO CONTEXTO
  // ============================================================

  Widget _buildContextField(
      BuildContext context,
      ) {
    return _buildFieldContainer(
      context,
      child: TextFormField(
        controller: _contextController,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        maxLines: 4,
        minLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: _inputDecoration(
          context,
          label: 'Contexto de uso',
          hint: 'Formal/informal, situaciones típicas, matices...',
          icon: Icons.info_outline_rounded,
        ),
      ),
    );
  }

  // ============================================================
  // CAMPO TRADUCCIÓN
  // ============================================================

  Widget _buildTranslationField(
      BuildContext context,
      ) {
    return _buildFieldContainer(
      context,
      child:
      TextFormField(
        controller:
        _translationController,
        keyboardType:
        TextInputType.text,
        textInputAction:
        TextInputAction.next,
        maxLines: 4,
        minLines: 2,
        textCapitalization:
        TextCapitalization
            .sentences,
        decoration:
        _inputDecoration(
          context,
          label: 'Español',
          hint:
          'Escribe la traducción',
          icon:
          Icons.translate_rounded,
        ),
        validator: (value) {
          if (value == null ||
              value.trim().isEmpty) {
            return 'Escribe la traducción al español.';
          }

          return null;
        },
      ),
    );
  }

  // ============================================================
  // CAMPO NOTA
  // ============================================================

  Widget _buildNoteField(
      BuildContext context,
      ) {
    return _buildFieldContainer(
      context,
      child:
      TextFormField(
        controller:
        _noteController,
        keyboardType:
        TextInputType.multiline,
        textInputAction:
        TextInputAction.newline,
        maxLines: 5,
        minLines: 3,
        decoration:
        _inputDecoration(
          context,
          label:
          'Nota / descripción',
          hint:
          'Agrega una explicación, ejemplo o información adicional...',
          icon: Icons
              .lightbulb_outline_rounded,
        ),
      ),
    );
  }

  // ============================================================
  // CONTENEDOR DE CAMPOS
  // ============================================================

  Widget _buildFieldContainer(
      BuildContext context, {
        required Widget child,
      }) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment
          .start,
      children: [
        child,
        const SizedBox(
          height: 7,
        ),
      ],
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration
  _inputDecoration(
      BuildContext context, {
        required String label,
        required String hint,
        required IconData icon,
      }) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon:
      Padding(
        padding:
        const EdgeInsets.only(
          left: 14,
          right: 8,
        ),
        child: Icon(
          icon,
        ),
      ),
      prefixIconConstraints:
      const BoxConstraints(
        minWidth: 52,
      ),
      alignLabelWithHint: true,
      filled: true,
      fillColor:
      colorScheme
          .surfaceContainerHighest
          .withValues(
        alpha: 0.35,
      ),
      border:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        borderSide:
        BorderSide.none,
      ),
      enabledBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        borderSide:
        BorderSide(
          color:
          colorScheme.outline
              .withValues(
            alpha: 0.10,
          ),
        ),
      ),
      focusedBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        borderSide:
        BorderSide(
          color:
          colorScheme.primary,
          width: 1.5,
        ),
      ),
      errorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        borderSide:
        BorderSide(
          color:
          colorScheme.error,
        ),
      ),
      focusedErrorBorder:
      OutlineInputBorder(
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        borderSide:
        BorderSide(
          color:
          colorScheme.error,
          width: 1.5,
        ),
      ),
      contentPadding:
      const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        18,
      ),
    );
  }

  // ============================================================
  // IMAGEN
  // ============================================================

  Widget _buildImageSection(
      BuildContext context,
      ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment
          .start,
      children: [
        const Padding(
          padding:
          EdgeInsets.only(
            left: 4,
            bottom: 9,
          ),
          child: Text(
            'Imagen',
            style:
            TextStyle(
              fontWeight:
              FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),

        AnimatedSwitcher(
          duration:
          const Duration(
            milliseconds: 250,
          ),
          child:
          _imagePath == null
              ? _buildEmptyImageBox(
            context,
          )
              : _buildSelectedImage(
            context,
          ),
        ),

        const SizedBox(
          height: 8,
        ),

        Text(
          'Opcional. Puedes agregar una fotografía o imagen relacionada.',
          style:
          TextStyle(
            color:
            colorScheme
                .onSurface
                .withValues(
              alpha: 0.50,
            ),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // IMAGEN VACÍA
  // ============================================================

  Widget _buildEmptyImageBox(
      BuildContext context,
      ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return InkWell(
      key:
      const ValueKey(
        'empty-image',
      ),
      borderRadius:
      BorderRadius.circular(
        22,
      ),
      onTap:
      _showImageSourceDialog,
      child: Container(
        width:
        double.infinity,
        height: 190,
        decoration:
        BoxDecoration(
          color:
          colorScheme
              .surfaceContainerHighest
              .withValues(
            alpha: 0.35,
          ),
          borderRadius:
          BorderRadius.circular(
            22,
          ),
          border:
          Border.all(
            color:
            colorScheme
                .outline
                .withValues(
              alpha: 0.14,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration:
              BoxDecoration(
                color:
                colorScheme
                    .primary
                    .withValues(
                  alpha: 0.09,
                ),
                shape:
                BoxShape.circle,
              ),
              child:
              Icon(
                Icons
                    .add_photo_alternate_outlined,
                size: 29,
                color:
                colorScheme
                    .primary,
              ),
            ),

            const SizedBox(
              height: 13,
            ),

            const Text(
              'Agregar imagen',
              style:
              TextStyle(
                fontWeight:
                FontWeight.w700,
                fontSize: 16,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            Text(
              'Galería o cámara',
              style:
              TextStyle(
                color:
                colorScheme
                    .onSurface
                    .withValues(
                  alpha: 0.50,
                ),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // IMAGEN SELECCIONADA
  // ============================================================

  Widget _buildSelectedImage(
      BuildContext context,
      ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    final path =
        _imagePath;

    if (path == null ||
        path.isEmpty) {
      return _buildEmptyImageBox(
        context,
      );
    }

    final file =
    File(path);

    if (!file.existsSync()) {
      return Container(
        key:
        const ValueKey(
          'invalid-image',
        ),
        width:
        double.infinity,
        height: 190,
        decoration:
        BoxDecoration(
          color:
          colorScheme
              .surfaceContainerHighest,
          borderRadius:
          BorderRadius.circular(
            22,
          ),
        ),
        child: Center(
          child: Text(
            'La imagen ya no está disponible.',
            style:
            TextStyle(
              color:
              colorScheme
                  .onSurface
                  .withValues(
                alpha: 0.60,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      key:
      const ValueKey(
        'selected-image',
      ),
      width:
      double.infinity,
      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        border:
        Border.all(
          color:
          colorScheme.outline
              .withValues(
            alpha: 0.12,
          ),
        ),
      ),
      clipBehavior:
      Clip.antiAlias,
      child: Stack(
        children: [
          Image.file(
            file,
            width:
            double.infinity,
            height: 240,
            fit: BoxFit.cover,
            errorBuilder:
                (
                context,
                error,
                stackTrace,
                ) {
              return Container(
                height: 240,
                color:
                colorScheme
                    .surfaceContainerHighest,
                child:
                const Center(
                  child: Icon(
                    Icons
                        .broken_image_outlined,
                    size: 45,
                  ),
                ),
              );
            },
          ),

          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                _buildImageActionButton(
                  context,
                  icon: Icons
                      .edit_rounded,
                  tooltip:
                  'Cambiar imagen',
                  onPressed:
                  _showImageSourceDialog,
                ),

                const SizedBox(
                  width: 8,
                ),

                _buildImageActionButton(
                  context,
                  icon: Icons
                      .delete_outline_rounded,
                  tooltip:
                  'Eliminar imagen',
                  onPressed:
                  _removeImage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTÓN SOBRE IMAGEN
  // ============================================================

  Widget _buildImageActionButton(
      BuildContext context, {
        required IconData icon,
        required String tooltip,
        required VoidCallback onPressed,
      }) {
    return Material(
      color:
      Colors.black.withValues(
        alpha: 0.65,
      ),
      borderRadius:
      BorderRadius.circular(
        13,
      ),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          13,
        ),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip,
          child: SizedBox(
            width: 45,
            height: 45,
            child: Icon(
              icon,
              color:
              Colors.white,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SELECCIÓN DE IMAGEN
  // ============================================================

  Future<void>
  _showImageSourceDialog() async {
    if (_isSaving ||
        _isDeleting) {
      return;
    }

    final source =
    await showModalBottomSheet<
        ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.fromLTRB(
              18,
              0,
              18,
              22,
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                const Text(
                  'Agregar imagen',
                  style:
                  TextStyle(
                    fontSize: 19,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                const Text(
                  'Selecciona de dónde quieres obtener la imagen.',
                  textAlign:
                  TextAlign.center,
                ),

                const SizedBox(
                  height: 18,
                ),

                ListTile(
                  leading:
                  const CircleAvatar(
                    child: Icon(
                      Icons
                          .photo_library_outlined,
                    ),
                  ),
                  title:
                  const Text(
                    'Galería',
                  ),
                  subtitle:
                  const Text(
                    'Seleccionar una imagen existente',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      ImageSource
                          .gallery,
                    );
                  },
                ),

                ListTile(
                  leading:
                  const CircleAvatar(
                    child: Icon(
                      Icons
                          .photo_camera_outlined,
                    ),
                  ),
                  title:
                  const Text(
                    'Cámara',
                  ),
                  subtitle:
                  const Text(
                    'Tomar una fotografía',
                  ),
                  onTap: () {
                    Navigator.pop(
                      context,
                      ImageSource
                          .camera,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    await _pickImage(
      source,
    );
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage(
      ImageSource source,
      ) async {
    try {
      final XFile? image =
      await _imagePicker
          .pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _imagePath =
            image.path;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo seleccionar la imagen.',
          ),
          behavior:
          SnackBarBehavior
              .floating,
        ),
      );
    }
  }

  // ============================================================
  // ELIMINAR IMAGEN
  // ============================================================

  void _removeImage() {
    setState(() {
      _imagePath = null;
    });
  }

  // ============================================================
  // BOTONES INFERIORES
  // ============================================================

  Widget _buildBottomButtons(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        16,
      ),
      decoration:
      BoxDecoration(
        color:
        Theme.of(context)
            .colorScheme
            .surface,
        border: Border(
          top: BorderSide(
            color:
            Theme.of(context)
                .colorScheme
                .outline
                .withValues(
              alpha: 0.10,
            ),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child:
            OutlinedButton.icon(
              onPressed:
              widget.isEditing &&
                  !_isSaving &&
                  !_isDeleting
                  ? _confirmDelete
                  : null,
              icon:
              const Icon(
                Icons
                    .delete_outline_rounded,
              ),
              label:
              const Text(
                'Eliminar',
              ),
              style:
              OutlinedButton
                  .styleFrom(
                foregroundColor:
                Theme.of(
                  context,
                )
                    .colorScheme
                    .error,
                minimumSize:
                const Size(
                  0,
                  52,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    16,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Expanded(
            flex: 2,
            child:
            FilledButton.icon(
              onPressed:
              _isSaving ||
                  _isDeleting
                  ? null
                  : _saveFlashcard,
              icon:
              _isSaving
                  ? const SizedBox(
                width: 19,
                height: 19,
                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2,
                  color:
                  Colors
                      .white,
                ),
              )
                  : const Icon(
                Icons
                    .check_rounded,
              ),
              label: Text(
                _isSaving
                    ? 'Guardando...'
                    : widget.isEditing
                    ? 'Guardar cambios'
                    : 'Agregar FlashCard',
              ),
              style:
              FilledButton
                  .styleFrom(
                minimumSize:
                const Size(
                  0,
                  52,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius
                      .circular(
                    16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GUARDAR
  // ============================================================

  Future<void>
  _saveFlashcard() async {
    FocusScope.of(
      context,
    ).unfocus();

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider =
      context.read<
          FlashcardProvider>();

      final korean =
      _koreanController.text
          .trim();

      final romanization =
      _romanizationController.text
          .trim();

      final translation =
      _translationController
          .text
          .trim();

      final note =
      _noteController.text
          .trim();

      final example =
      _exampleController.text
          .trim();

      final exampleTranslation =
      _exampleTranslationController
          .text
          .trim();

      final contextText =
      _contextController.text
          .trim();

      if (widget.isEditing) {
        final flashcard =
            widget.flashcard;

        if (flashcard == null) {
          throw Exception(
            'No se encontró la FlashCard que se está editando.',
          );
        }

        await provider
            .updateFlashcard(
          id: flashcard.id,
          groupId:
          widget.groupId,
          korean: korean,
          romanization:
          romanization.isEmpty
              ? null
              : romanization,
          translation:
          translation,
          imagePath:
          _imagePath,
          note: note,
          example:
          example.isEmpty ? null : example,
          exampleTranslation:
          exampleTranslation.isEmpty
              ? null
              : exampleTranslation,
          context:
          contextText.isEmpty
              ? null
              : contextText,
        );
      } else {
        await provider
            .createFlashcard(
          groupId:
          widget.groupId,
          korean: korean,
          romanization:
          romanization.isEmpty
              ? null
              : romanization,
          translation:
          translation,
          imagePath:
          _imagePath,
          note: note,
          example:
          example.isEmpty ? null : example,
          exampleTranslation:
          exampleTranslation.isEmpty
              ? null
              : exampleTranslation,
          context:
          contextText.isEmpty
              ? null
              : contextText,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'FlashCard actualizada.'
                : 'FlashCard creada correctamente.',
          ),
          behavior:
          SnackBarBehavior
              .floating,
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar la FlashCard: $e',
          ),
          behavior:
          SnackBarBehavior
              .floating,
        ),
      );
    }
  }

  // ============================================================
  // TRADUCIR Y COMPLETAR (IA)
  // ============================================================

  Future<void> _translateAndComplete() async {
    final koreanText =
    _koreanController.text.trim();

    if (koreanText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Escribe primero el texto en coreano.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    // Ocultar teclado mientras carga
    FocusScope.of(context).unfocus();

    setState(() {
      _isTranslating = true;
    });

    try {
      final result =
      await _ai.translateAndComplete(koreanText);

      if (!mounted) return;

      if (result.isEmpty) {
        throw Exception(
          'La IA devolvió una respuesta vacía.',
        );
      }

      // Rellenar todos los campos de la flashcard.
      setState(() {
        _romanizationController.text = result.romanization;
        _translationController.text = result.translation;
        _exampleController.text = result.exampleKorean;
        _exampleTranslationController.text = result.exampleSpanish;
        _contextController.text = result.context;
        _noteController.text = result.note;

        _isTranslating = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Traducción completada. Revisa y ajusta si es necesario.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isTranslating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo traducir: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // CONFIRMAR ELIMINACIÓN
  // ============================================================

  Future<void>
  _confirmDelete() async {
    if (!widget.isEditing ||
        _isSaving ||
        _isDeleting) {
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Eliminar FlashCard',
          ),
          content:
          const Text(
            '¿Estás seguro de que quieres eliminar esta FlashCard? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child:
              const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              style:
              FilledButton.styleFrom(
                backgroundColor:
                Theme.of(
                  context,
                )
                    .colorScheme
                    .error,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child:
              const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _deleteFlashcard();
  }

  // ============================================================
  // ELIMINAR
  // ============================================================

  Future<void>
  _deleteFlashcard() async {
    final flashcard =
        widget.flashcard;

    if (flashcard == null) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      final provider =
      context.read<
          FlashcardProvider>();

      await provider
          .deleteFlashcard(
        flashcard.id,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'FlashCard eliminada.',
          ),
          behavior:
          SnackBarBehavior
              .floating,
        ),
      );

      Navigator.pop(
        context,
        true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isDeleting = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar la FlashCard: $e',
          ),
          behavior:
          SnackBarBehavior
              .floating,
        ),
      );
    }
  }
}
