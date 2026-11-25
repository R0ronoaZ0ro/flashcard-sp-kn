import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/flashcard_provider.dart';
import '../services/tts_service.dart';
import 'flashcard_form_screen.dart';
import 'flashcard_list_screen.dart';

class FlashcardScreen extends StatefulWidget {
  final int groupId;

  const FlashcardScreen({
    super.key,
    required this.groupId,
  });

  @override
  State<FlashcardScreen> createState() =>
      _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final TtsService _tts = TtsService.instance;

  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
          (_) async {
        final provider =
        context.read<
            FlashcardProvider>();

        await provider.selectGroup(
          widget.groupId,
        );
      },
    );
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
      _buildAppBar(context),
      body: SafeArea(
        child:
        Consumer<
            FlashcardProvider>(
          builder: (
              context,
              provider,
              child,
              ) {
            return _buildBody(
              context,
              provider,
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(
      BuildContext context,
      ) {
    return AppBar(
      leading:
      IconButton(
        tooltip:
        'Volver',
        icon:
        const Icon(
          Icons
              .arrow_back_rounded,
        ),
        onPressed: () {
          _tts.stop();

          Navigator.pop(
            context,
          );
        },
      ),
      title:
      const Text(
        'FLASHCARD SP-KN',
        style:
        TextStyle(
          fontWeight:
          FontWeight.w800,
          letterSpacing:
          1.1,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Lista de FlashCards',
          icon: const Icon(Icons.view_list_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FlashcardListScreen(
                  groupId: widget.groupId,
                ),
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'Ajustes de voz',
          icon: const Icon(Icons.tune_rounded),
          onPressed: () {
            _showTtsSettings(context);
          },
        ),
        Consumer<FlashcardProvider>(
          builder: (context, provider, child) {
            if (provider.currentFlashcard == null) {
              return const SizedBox.shrink();
            }

            return IconButton(
              tooltip: 'Editar FlashCard',
              icon: const Icon(Icons.edit_rounded),
              onPressed: () {
                _editCurrentFlashcard(context, provider);
              },
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(
      BuildContext context,
      FlashcardProvider provider,
      ) {
    if (provider.isLoading &&
        provider.flashcards.isEmpty) {
      return const Center(
        child:
        CircularProgressIndicator(),
      );
    }

    if (provider.flashcards.isEmpty) {
      return _buildEmptyState(
        context,
        provider,
      );
    }

    final flashcard =
        provider.currentFlashcard;

    if (flashcard == null) {
      return _buildEmptyState(
        context,
        provider,
      );
    }

    return _buildFlashcard(
      context,
      provider,
      flashcard,
    );
  }

  // ============================================================
  // FLASHCARD
  // ============================================================

  Widget _buildFlashcard(
      BuildContext context,
      FlashcardProvider provider,
      dynamic flashcard,
      ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Column(
      children: [
        Padding(
          padding:
          const EdgeInsets.fromLTRB(
            20,
            18,
            20,
            8,
          ),
          child: Row(
            mainAxisAlignment:
            MainAxisAlignment
                .spaceBetween,
            children: [
              _buildGroupBadge(
                context,
                provider,
              ),
              _buildPositionBadge(
                context,
                provider,
              ),
            ],
          ),
        ),

        Expanded(
          child:
          SingleChildScrollView(
            physics:
            const BouncingScrollPhysics(),
            padding:
            const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            child: Column(
              children: [
                _buildKoreanCard(
                  context,
                  flashcard,
                ),

                if (_hasRomanization(flashcard)) ...[
                  const SizedBox(
                    height: 14,
                  ),
                  _buildRomanizationCard(
                    context,
                    flashcard,
                  ),
                ],

                const SizedBox(
                  height: 18,
                ),

                _buildTranslationCard(
                  context,
                  flashcard,
                ),

                if (_hasExample(flashcard)) ...[
                  const SizedBox(
                    height: 18,
                  ),
                  _buildExampleCard(
                    context,
                    flashcard,
                  ),
                ],

                if (_hasContext(flashcard)) ...[
                  const SizedBox(
                    height: 18,
                  ),
                  _buildContextCard(
                    context,
                    flashcard,
                  ),
                ],

                if (_hasImage(flashcard)) ...[
                  const SizedBox(
                    height: 18,
                  ),
                  _buildImageCard(
                    context,
                    flashcard,
                  ),
                ],

                if (_hasNote(flashcard)) ...[
                  const SizedBox(
                    height: 18,
                  ),
                  _buildNoteCard(
                    context,
                    flashcard,
                  ),
                ],

                const SizedBox(
                  height: 10,
                ),
              ],
            ),


          ),
        ),

        Container(
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
            colorScheme.surface,
            border:
            Border(
              top:
              BorderSide(
                color:
                colorScheme
                    .outline
                    .withValues(
                  alpha:
                  0.10,
                ),
              ),
            ),
          ),
          child:
          _buildNavigationButtons(
            context,
            provider,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BADGE GRUPO
  // ============================================================

  Widget _buildGroupBadge(
      BuildContext context,
      FlashcardProvider provider,
      ) {
    final group =
        provider.selectedGroup;

    if (group == null) {
      return const SizedBox
          .shrink();
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color:
        Theme.of(context)
            .colorScheme
            .primary
            .withValues(
          alpha: 0.08,
        ),
        borderRadius:
        BorderRadius.circular(
          30,
        ),
      ),
      child:
      Row(
        mainAxisSize:
        MainAxisSize.min,
        children: [
          const Text(
            '🇰🇷',
            style:
            TextStyle(
              fontSize: 15,
            ),
          ),
          const SizedBox(
            width: 7,
          ),
          ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 160,
            ),
            child:
            Text(
              group.name,
              maxLines: 1,
              overflow:
              TextOverflow
                  .ellipsis,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // POSICIÓN
  // ============================================================

  Widget _buildPositionBadge(
      BuildContext context,
      FlashcardProvider provider,
      ) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 7,
      ),
      decoration:
      BoxDecoration(
        color:
        Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius:
        BorderRadius.circular(
          30,
        ),
      ),
      child:
      Text(
        provider
            .flashcardPositionText,
        style:
        const TextStyle(
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // TARJETA COREANA
  // ============================================================

  Widget _buildKoreanCard(
      BuildContext context,
      dynamic flashcard,
      ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.fromLTRB(
        24,
        30,
        24,
        28,
      ),
      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(
          28,
        ),
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color:
            colorScheme
                .primary
                .withValues(
              alpha: 0.20,
            ),
            blurRadius:
            28,
            offset:
            const Offset(
              0,
              12,
            ),
          ),
        ],
      ),
      child:
      Column(
        children: [
          Row(
            children: [
              Expanded(
                child:
                Text(
                  '한국어',
                  style:
                  TextStyle(
                    color:
                    Colors.white
                        .withValues(
                      alpha:
                      0.75,
                    ),
                    fontSize:
                    13,
                    fontWeight:
                    FontWeight.w700,
                    letterSpacing:
                    1.2,
                  ),
                ),
              ),

              _buildAudioButton(
                context,
                flashcard,
              ),
            ],
          ),

          const SizedBox(
            height: 25,
          ),

          Text(
            flashcard.korean,
            textAlign:
            TextAlign.center,
            style:
            const TextStyle(
              color:
              Colors.white,
              fontSize:
              34,
              fontWeight:
              FontWeight.w800,
              height:
              1.25,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          Text(
            'Texto coreano',
            style:
            TextStyle(
              color:
              Colors.white
                  .withValues(
                alpha:
                0.60,
              ),
              fontSize:
              12,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOTÓN AUDIO
  // ============================================================

  Widget _buildAudioButton(
      BuildContext context,
      dynamic flashcard,
      ) {
    return Material(
      color:
      Colors.white
          .withValues(
        alpha:
        0.16,
      ),
      borderRadius:
      BorderRadius.circular(
        16,
      ),
      child:
      InkWell(
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        onTap:
            () => _toggleAudio(
          context,
          flashcard.korean,
        ),
        child:
        SizedBox(
          width:
          48,
          height:
          48,
          child:
          Icon(
            _isPlaying
                ? Icons
                .stop_rounded
                : Icons
                .volume_up_rounded,
            color:
            Colors.white,
            size:
            25,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REPRODUCIR / DETENER
  // ============================================================

  Future<void> _toggleAudio(
      BuildContext context, String korean,) async {
    if (_isPlaying) {
      await _tts.stop();

      if (mounted) {
        setState(() {
          _isPlaying =
          false;
        });
      }

      return;
    }

    if (korean
        .trim()
        .isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _isPlaying =
        true;
      });
    }

    try {
      await _tts.speakKorean(
        korean,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isPlaying =
        false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo reproducir la pronunciación.',
          ),
          behavior:
          SnackBarBehavior
              .floating,
        ),
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isPlaying =
      false;
    });
  }

  // ============================================================
  // TRADUCCIÓN
  // ============================================================

  Widget _buildTranslationCard(
      BuildContext context,
      dynamic flashcard,
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
        colorScheme.surface,
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
            alpha:
            0.10,
          ),
        ),
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Row(
            children: [
              Container(
                width:
                36,
                height:
                36,
                decoration:
                BoxDecoration(
                  color:
                  colorScheme
                      .secondary
                      .withValues(
                    alpha:
                    0.10,
                  ),
                  borderRadius:
                  BorderRadius
                      .circular(
                    11,
                  ),
                ),
                child:
                Icon(
                  Icons
                      .translate_rounded,
                  size:
                  19,
                  color:
                  colorScheme
                      .secondary,
                ),
              ),

              const SizedBox(
                width:
                12,
              ),

              Text(
                'ESPAÑOL',
                style:
                TextStyle(
                  fontSize:
                  12,
                  fontWeight:
                  FontWeight
                      .w800,
                  letterSpacing:
                  1.1,
                  color:
                  colorScheme
                      .onSurface
                      .withValues(
                    alpha:
                    0.55,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
            15,
          ),

          Text(
            flashcard.translation,
            style:
            Theme.of(
              context,
            )
                .textTheme
                .titleLarge
                ?.copyWith(
              fontWeight:
              FontWeight
                  .w700,
              height:
              1.3,
            ),
          ),
        ],
      ),
    );
  }


  // ============================================================
  // IMAGEN
  // ============================================================

  Widget _buildImageCard(
      BuildContext context,
      dynamic flashcard,
      ) {
    final imagePath =
    flashcard.imagePath
        ?.toString()
        .trim();

    if (imagePath ==
        null ||
        imagePath.isEmpty) {
      return const SizedBox
          .shrink();
    }

    final file =
    File(imagePath);

    return Container(
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
          Theme.of(context)
              .colorScheme
              .outline
              .withValues(
            alpha:
            0.10,
          ),
        ),
      ),
      clipBehavior:
      Clip.antiAlias,
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Padding(
            padding:
            const EdgeInsets
                .fromLTRB(
              18,
              16,
              18,
              12,
            ),
            child:
            Row(
              children: [
                Icon(
                  Icons
                      .image_outlined,
                  size:
                  19,
                  color:
                  Theme.of(
                    context,
                  )
                      .colorScheme
                      .primary,
                ),
                const SizedBox(
                  width:
                  8,
                ),
                const Text(
                  'IMAGEN',
                  style:
                  TextStyle(
                    fontWeight:
                    FontWeight
                        .w800,
                    fontSize:
                    12,
                    letterSpacing:
                    1,
                  ),
                ),
              ],
            ),
          ),

          if (file.existsSync())
            Image.file(
              file,
              width:
              double.infinity,
              fit:
              BoxFit.cover,
              errorBuilder:
                  (
                  context,
                  error,
                  stackTrace,
                  ) {
                return _buildImageError(
                  context,
                );
              },
            )
          else
            _buildImageError(
              context,
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR IMAGEN
  // ============================================================

  Widget _buildImageError(
      BuildContext context,
      ) {
    return Container(
      width:
      double.infinity,
      height:
      180,
      color:
      Theme.of(context)
          .colorScheme
          .surfaceContainerHighest,
      child:
      Column(
        mainAxisAlignment:
        MainAxisAlignment
            .center,
        children: [
          Icon(
            Icons
                .broken_image_outlined,
            size:
            44,
            color:
            Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(
              alpha:
              0.40,
            ),
          ),
          const SizedBox(
            height:
            8,
          ),
          Text(
            'No se pudo cargar la imagen.',
            style:
            TextStyle(
              color:
              Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(
                alpha:
                0.55,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NOTA
  // ============================================================

  Widget _buildNoteCard(
      BuildContext context,
      dynamic flashcard,
      ) {
    final colorScheme =
        Theme.of(context)
            .colorScheme;

    return Container(
      width:
      double.infinity,
      padding:
      const EdgeInsets.all(
        20,
      ),
      decoration:
      BoxDecoration(
        color:
        colorScheme.tertiary
            .withValues(
          alpha:
          0.07,
        ),
        borderRadius:
        BorderRadius.circular(
          22,
        ),
        border:
        Border.all(
          color:
          colorScheme
              .tertiary
              .withValues(
            alpha:
            0.12,
          ),
        ),
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment
            .start,
        children: [
          Row(
            children: [
              Icon(
                Icons
                    .lightbulb_outline_rounded,
                color:
                colorScheme
                    .tertiary,
                size:
                21,
              ),
              const SizedBox(
                width:
                9,
              ),
              Text(
                'NOTA',
                style:
                TextStyle(
                  fontWeight:
                  FontWeight
                      .w800,
                  fontSize:
                  12,
                  letterSpacing:
                  1,
                  color:
                  colorScheme
                      .tertiary,
                ),
              ),
            ],
          ),

          const SizedBox(
            height:
            12,
          ),

          Text(
            flashcard.note,
            style:
            Theme.of(
              context,
            )
                .textTheme
                .bodyLarge
                ?.copyWith(
              height:
              1.45,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRomanizationCard(
      BuildContext context,
      dynamic flashcard,
      ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.abc_rounded,
            size: 20,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              flashcard.romanization,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                color: colorScheme.primary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildExampleCard(
      BuildContext context,
      dynamic flashcard,
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasTranslation =
        flashcard.exampleTranslation != null &&
            flashcard.exampleTranslation
                .toString()
                .trim()
                .isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 9),
              Text(
                'EJEMPLO',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: colorScheme.onSurface
                      .withValues(alpha: 0.55),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            flashcard.example,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),

          if (hasTranslation) ...[
            const SizedBox(height: 10),
            Text(
              flashcard.exampleTranslation,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: colorScheme.onSurface
                    .withValues(alpha: 0.70),
                height: 1.4,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildContextCard(
      BuildContext context,
      dynamic flashcard,
      ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.tertiary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 9),
              Text(
                'CONTEXTO',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            flashcard.context,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NAVEGACIÓN
  // ============================================================

  Widget _buildNavigationButtons(
      BuildContext context,
      FlashcardProvider provider,
      ) {
    return Row(
      children: [
        Expanded(
          child:
          OutlinedButton.icon(
            onPressed:
            provider
                .hasPreviousFlashcard
                ? () async {
              await _tts.stop();

              if (mounted) {
                setState(() {
                  _isPlaying =
                  false;
                });
              }

              provider
                  .previousFlashcard();
            }
                : null,
            icon:
            const Icon(
              Icons
                  .arrow_back_rounded,
            ),
            label:
            const Text(
              'Anterior',
            ),
            style:
            OutlinedButton
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

        const SizedBox(
          width:
          12,
        ),

        Expanded(
          child:
          FilledButton.icon(
            onPressed:
            provider
                .hasNextFlashcard
                ? () async {
              await _tts.stop();

              if (mounted) {
                setState(() {
                  _isPlaying =
                  false;
                });
              }

              provider
                  .nextFlashcard();
            }
                : null,
            icon:
            const Icon(
              Icons
                  .arrow_forward_rounded,
            ),
            label:
            const Text(
              'Siguiente',
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
    );
  }

  // ============================================================
  // ESTADO VACÍO
  // ============================================================

  Widget _buildEmptyState(
      BuildContext context,
      FlashcardProvider provider,
      ) {
    final group =
        provider.selectedGroup;

    return Center(
      child:
      Padding(
        padding:
        const EdgeInsets.all(
          28,
        ),
        child:
        Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            Container(
              width:
              100,
              height:
              100,
              decoration:
              BoxDecoration(
                shape:
                BoxShape.circle,
                color:
                Theme.of(
                  context,
                )
                    .colorScheme
                    .primary
                    .withValues(
                  alpha:
                  0.10,
                ),
              ),
              child:
              Icon(
                Icons
                    .style_outlined,
                size:
                48,
                color:
                Theme.of(
                  context,
                )
                    .colorScheme
                    .primary,
              ),
            ),

            const SizedBox(
              height:
              24,
            ),

            Text(
              'No hay FlashCards',
              textAlign:
              TextAlign.center,
              style:
              Theme.of(
                context,
              )
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight:
                FontWeight
                    .w800,
              ),
            ),

            const SizedBox(
              height:
              10,
            ),

            Text(
              group == null
                  ? 'Este grupo todavía no tiene tarjetas.'
                  : 'El grupo "${group.name}" '
                  'todavía no tiene tarjetas.',
              textAlign:
              TextAlign.center,
              style:
              Theme.of(
                context,
              )
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
                color:
                Theme.of(
                  context,
                )
                    .colorScheme
                    .onSurface
                    .withValues(
                  alpha:
                  0.60,
                ),
              ),
            ),

            const SizedBox(
              height:
              28,
            ),

            FilledButton.icon(
              onPressed:
              group == null
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) =>
                        FlashcardFormScreen(
                          groupId:
                          group.id,
                        ),
                  ),
                );
              },
              icon:
              const Icon(
                Icons.add_rounded,
              ),
              label:
              const Text(
                'Crear FlashCard',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // EDITAR
  // ============================================================

  Future<void>
  _editCurrentFlashcard(
      BuildContext context,
      FlashcardProvider provider,
      ) async {
    final flashcard =
        provider.currentFlashcard;

    final group =
        provider.selectedGroup;

    if (flashcard == null ||
        group == null) {
      return;
    }

    await _tts.stop();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
            FlashcardFormScreen(
              groupId:
              group.id,
              flashcard:
              flashcard,
            ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    await provider.loadFlashcards(
      group.id,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool _hasImage(
      dynamic flashcard,
      ) {
    final image =
        flashcard.imagePath;

    return image != null &&
        image
            .toString()
            .trim()
            .isNotEmpty;
  }
  bool _hasRomanization(dynamic flashcard) {
    final value = flashcard.romanization;
    return value != null &&
        value.toString().trim().isNotEmpty;
  }

  bool _hasExample(dynamic flashcard) {
    final value = flashcard.example;
    return value != null &&
        value.toString().trim().isNotEmpty;
  }

  bool _hasContext(dynamic flashcard) {
    final value = flashcard.context;
    return value != null &&
        value.toString().trim().isNotEmpty;
  }
  bool _hasNote(
      dynamic flashcard,
      ) {
    final note =
        flashcard.note;

    return note != null &&
        note
            .toString()
            .trim()
            .isNotEmpty;
  }
  // ============================================================
  // AJUSTES DE VOZ
  // ============================================================

  Future<void> _showTtsSettings(BuildContext context) async {
    // ⚠️ Detenemos cualquier reproducción en curso
    await _tts.stop();

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _TtsSettingsSheet(
          tts: _tts,
        );
      },
    );

    // Refrescamos el estado del botón de audio
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }
}


// ============================================================
// HOJA DE AJUSTES DEL TTS
// ============================================================

class _TtsSettingsSheet extends StatefulWidget {
  final TtsService tts;

  const _TtsSettingsSheet({
    required this.tts,
  });

  @override
  State<_TtsSettingsSheet> createState() => _TtsSettingsSheetState();
}

class _TtsSettingsSheetState extends State<_TtsSettingsSheet> {
  late double _rate;

  bool _testing = false;

  @override
  void initState() {
    super.initState();

    _rate = widget.tts.speechRate;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF101621),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            // Título
            const Row(
              children: [
                Icon(
                  Icons.record_voice_over_rounded,
                  color: Color(0xFF00E5FF),
                ),
                SizedBox(width: 12),
                Text(
                  'Ajustes de voz',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'Ajusta la velocidad con la que se reproduce el coreano.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Etiqueta + valor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Velocidad',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _rate.toStringAsFixed(2),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF00E5FF),
                      fontFeatures: [
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF00E5FF),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
                thumbColor: const Color(0xFF00E5FF),
                overlayColor: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                trackHeight: 4,
              ),
              child: Slider(
                value: _rate,
                min: TtsService.minSpeechRate,
                max: TtsService.maxSpeechRate,
                divisions: 17, // (1.0 - 0.15) / 0.05 = 17 pasos
                label: _rate.toStringAsFixed(2),
                onChanged: (value) async {
                  setState(() {
                    _rate = value;
                  });

                  await widget.tts.setSpeechRate(value);
                },
              ),
            ),

            // Etiquetas de los extremos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lento',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                  Text(
                    'Rápido',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Botón de prueba
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: const Color(0xFF001014),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _testing
                    ? null
                    : () async {
                  setState(() {
                    _testing = true;
                  });

                  try {
                    await widget.tts.speakKorean('안녕하세요');
                  } catch (_) {
                    // Ignorar
                  }

                  if (!mounted) return;

                  setState(() {
                    _testing = false;
                  });
                },
                icon: _testing
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF001014),
                  ),
                )
                    : const Icon(Icons.play_arrow_rounded),
                label: Text(
                  _testing ? 'Reproduciendo...' : 'Probar',
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Botón restaurar
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await widget.tts.setSpeechRate(
                    TtsService.defaultSpeechRate,
                  );

                  if (!mounted) return;

                  setState(() {
                    _rate = TtsService.defaultSpeechRate;
                  });
                },
                icon: const Icon(
                  Icons.restore_rounded,
                  size: 18,
                ),
                label: const Text(
                  'Restaurar por defecto',
                ),
                style: TextButton.styleFrom(
                  foregroundColor:
                  Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}