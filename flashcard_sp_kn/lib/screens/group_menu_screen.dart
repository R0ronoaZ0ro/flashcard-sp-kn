import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/flashcard_group.dart';
import '../providers/flashcard_provider.dart';
import '../services/backup_service.dart';
import 'remote_backup_screen.dart';

import 'flashcard_form_screen.dart';
import 'flashcard_screen.dart';
import 'update_screen.dart';
import 'server_settings_screen.dart';


class GroupMenuScreen extends StatefulWidget {
  const GroupMenuScreen({super.key});

  @override
  State<GroupMenuScreen> createState() => _GroupMenuScreenState();
}

class _GroupMenuScreenState extends State<GroupMenuScreen> {
  final Map<int, int> _flashcardCounts = {};

  bool _loadingCounts = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    final provider = context.read<FlashcardProvider>();

    await provider.loadGroups();

    if (!mounted) return;

    await _loadFlashcardCounts();
  }

  Future<void> _loadFlashcardCounts() async {
    if (!mounted) return;

    setState(() {
      _loadingCounts = true;
    });

    final provider = context.read<FlashcardProvider>();

    final Map<int, int> counts = {};

    for (final group in provider.groups) {
      try {
        final cards = await provider.getFlashcards(group.id);

        counts[group.id] = cards.length;
      } catch (_) {
        counts[group.id] = 0;
      }
    }

    if (!mounted) return;

    setState(() {
      _flashcardCounts
        ..clear()
        ..addAll(counts);

      _loadingCounts = false;
    });
  }

  Future<void> _refresh() async {
    await _loadData();
  }

  // ============================================================
  // CREAR GRUPO
  // ============================================================

  Future<void> _showCreateGroupDialog() async {
    final controller = TextEditingController();

    final formKey = GlobalKey<FormState>();

    // showDialog devuelve String? (el nombre del grupo)
    final createdName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111722),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.18),
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            8,
          ),
          contentPadding: const EdgeInsets.fromLTRB(
            24,
            12,
            24,
            8,
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            24,
            8,
            24,
            20,
          ),
          title: const Row(
            children: [
              Icon(
                Icons.create_new_folder_outlined,
                color: Color(0xFF00E5FF),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nuevo grupo',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 50,
              decoration: InputDecoration(
                labelText: 'Nombre del grupo',
                hintText: 'Ej: Verbos',
                counterText: '',
                prefixIcon: const Icon(
                  Icons.folder_outlined,
                ),
                filled: true,
                fillColor: const Color(0xFF0B1018),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF00E5FF),
                    width: 1.3,
                  ),
                ),
              ),
              validator: (value) {
                final name = value?.trim() ?? '';

                if (name.isEmpty) {
                  return 'Ingresa un nombre';
                }

                if (name.length < 2) {
                  return 'Usa al menos 2 caracteres';
                }

                return null;
              },
              onFieldSubmitted: (_) {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }

                final name = controller.text.trim();

                Navigator.of(dialogContext).pop(name);
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }

                final name = controller.text.trim();

                Navigator.of(dialogContext).pop(name);
              },
              icon: const Icon(
                Icons.add_rounded,
              ),
              label: const Text(
                'Crear',
              ),
            ),
          ],
        );
      },
    );

    // Diferimos el dispose al siguiente frame para evitar
    // que el TextFormField use el controller después de disposed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    // Crear el grupo AQUÍ, ya sin el diálogo montado.
    if (createdName != null && createdName.isNotEmpty) {
      if (!mounted) return;

      try {
        await context
            .read<FlashcardProvider>()
            .createGroup(createdName);

        if (!mounted) return;

        _showMessage('Grupo "$createdName" creado correctamente.');

        await _loadData();
      } catch (e) {
        if (!mounted) return;

        _showMessage(
          'No se pudo crear el grupo: $e',
        );
      }
    }
  }

  // ============================================================
  // ELIMINAR GRUPO
  // ============================================================

  Future<void> _showDeleteGroupDialog() async {
    final provider = context.read<FlashcardProvider>();

    if (provider.groups.isEmpty) {
      _showMessage(
        'No hay grupos para eliminar.',
      );

      return;
    }

    int? selectedGroupId;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool deleting = false;

        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111722),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: const Color(0xFFFF4D67).withValues(alpha: 0.20),
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                24,
                24,
                24,
                8,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                16,
                12,
                16,
                8,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                24,
                8,
                24,
                20,
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFFF4D67),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Eliminar grupo',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          8,
                          0,
                          8,
                          12,
                        ),
                        child: Text(
                          'Selecciona el grupo que deseas eliminar:',
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: provider.groups.length,
                        separatorBuilder: (_, _) {
                          return const SizedBox(height: 6);
                        },
                        itemBuilder: (
                            context,
                            index,
                            ) {
                          final group =
                          provider.groups[index];

                          final isSelected =
                              selectedGroupId == group.id;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius:
                              BorderRadius.circular(14),
                              onTap: deleting
                                  ? null
                                  : () {
                                setDialogState(() {
                                  selectedGroupId =
                                      group.id;
                                });
                              },
                              child: AnimatedContainer(
                                duration:
                                const Duration(
                                  milliseconds: 180,
                                ),
                                padding:
                                const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                    0xFFFF4D67,
                                  ).withValues(alpha: 0.10)
                                      : const Color(
                                    0xFF0B1018,
                                  ),
                                  borderRadius:
                                  BorderRadius.circular(
                                    14,
                                  ),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(
                                      0xFFFF4D67,
                                    ).withValues(alpha: 0.65)
                                        : Colors.white
                                        .withValues(alpha: 0.07),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration:
                                      BoxDecoration(
                                        color: isSelected
                                            ? const Color(
                                          0xFFFF4D67,
                                        ).withValues(alpha: 0.14)
                                            : const Color(
                                          0xFF00E5FF,
                                        ).withValues(alpha: 0.08),
                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                          12,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.folder_rounded,
                                        color: isSelected
                                            ? const Color(
                                          0xFFFF4D67,
                                        )
                                            : const Color(
                                          0xFF00E5FF,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        group.name,
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style:
                                        const TextStyle(
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Radio<int>(
                                      value: group.id,
                                      groupValue:
                                      selectedGroupId,
                                      activeColor:
                                      const Color(
                                        0xFFFF4D67,
                                      ),
                                      onChanged: deleting
                                          ? null
                                          : (value) {
                                        setDialogState(
                                              () {
                                            selectedGroupId =
                                                value;
                                          },
                                        );
                                      },
                                    ),


                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: deleting
                      ? null
                      : () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    const Color(0xFFFF4D67),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: selectedGroupId == null || deleting
                      ? null
                      : () async {
                    final group =
                    provider.groups.firstWhere(
                          (item) =>
                      item.id ==
                          selectedGroupId,
                    );

                    final confirmed =
                    await _confirmGroupDeletion(
                      group,
                    );

                    if (!confirmed) {
                      return;
                    }

                    setDialogState(() {
                      deleting = true;
                    });

                    try {
                      await provider.deleteGroup(
                        group.id,
                      );

                      if (!context.mounted) return;

                      Navigator.of(context).pop(true);
                    } catch (e) {
                      setDialogState(() {
                        deleting = false;
                      });

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            'No se pudo eliminar el grupo: $e',
                          ),
                        ),
                      );
                    }
                  },
                  icon: deleting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons.delete_outline_rounded,
                  ),
                  label: Text(
                    deleting
                        ? 'Eliminando...'
                        : 'Eliminar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<bool> _confirmGroupDeletion(
      FlashcardGroup group,
      ) async {
    final count =
        _flashcardCounts[group.id] ?? 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111722),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            '¿Eliminar grupo?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            count > 0
                ? 'Se eliminará "${group.name}" junto con $count ${count == 1 ? 'FlashCard' : 'FlashCards'}. Esta acción no se puede deshacer.'
                : 'Se eliminará "${group.name}". Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text(
                'Cancelar',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                const Color(0xFFFF4D67),
              ),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Eliminar',
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // CREAR FLASHCARD
  // ============================================================

  Future<void> _showCreateFlashcardDialog() async {
    final provider = context.read<FlashcardProvider>();

    if (provider.groups.isEmpty) {
      _showMessage(
        'Primero debes crear un grupo.',
      );

      await _showCreateGroupDialog();

      return;
    }

    int? selectedGroupId;

    final result = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        bool continuing = false;

        return StatefulBuilder(
          builder: (
              context,
              setDialogState,
              ) {
            return AlertDialog(
              backgroundColor: const Color(0xFF111722),
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: const Color(0xFF7C4DFF).withValues(alpha: 0.20),
                ),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                24,
                24,
                24,
                8,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                24,
                12,
                24,
                8,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                24,
                8,
                24,
                20,
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.add_card_rounded,
                    color: Color(0xFF9B7CFF),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Nueva FlashCard',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: DropdownButtonFormField<int>(
                initialValue: selectedGroupId,
                decoration: InputDecoration(
                  labelText: 'Grupo',
                  prefixIcon: const Icon(
                    Icons.folder_outlined,
                  ),
                  filled: true,
                  fillColor: const Color(0xFF0B1018),
                  border: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white
                          .withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder:
                  OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(16),
                    borderSide:
                    const BorderSide(
                      color: Color(0xFF7C4DFF),
                      width: 1.3,
                    ),
                  ),
                ),
                items: provider.groups
                    .map(
                      (group) {
                    return DropdownMenuItem<int>(
                      value: group.id,
                      child: Text(
                        group.name,
                        overflow:
                        TextOverflow.ellipsis,
                      ),
                    );
                  },
                )
                    .toList(),
                onChanged: continuing
                    ? null
                    : (value) {
                  setDialogState(() {
                    selectedGroupId = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: continuing
                      ? null
                      : () {
                    Navigator.of(context)
                        .pop();
                  },
                  child: const Text(
                    'Cancelar',
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                  selectedGroupId == null ||
                      continuing
                      ? null
                      : () {
                    setDialogState(() {
                      continuing = true;
                    });

                    Navigator.of(context)
                        .pop(
                      selectedGroupId,
                    );
                  },
                  icon: continuing
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.arrow_forward_rounded,
                  ),
                  label: const Text(
                    'Continuar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null || !mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardFormScreen(
          groupId: result,
        ),
      ),
    );

    if (!mounted) return;

    await _loadData();
  }

  // ============================================================
  // ABRIR GRUPO
  // ============================================================

  Future<void> _openGroup(
      FlashcardGroup group,
      ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FlashcardScreen(
          groupId: group.id,
        ),
      ),
    );

    if (!mounted) return;

    await _loadData();
  }

  // ============================================================
  // BURGER MENU
  // ============================================================

  Future<void> _showMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12,
            ),
            padding: const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
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
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(
                    bottom: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MENÚ',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 2,
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _MenuAction(
                  icon: Icons.create_new_folder_outlined,
                  color: const Color(0xFF00E5FF),
                  title: 'Crear grupo',
                  subtitle:
                  'Crear un nuevo grupo de FlashCards',
                  onTap: () async {
                    Navigator.of(context).pop();

                    await _showCreateGroupDialog();
                  },
                ),
                const SizedBox(height: 8),
                _MenuAction(
                  icon: Icons.add_card_rounded,
                  color: const Color(0xFF9B7CFF),
                  title: 'Crear FlashCard',
                  subtitle:
                  'Agregar una nueva tarjeta a un grupo',
                  onTap: () async {
                    Navigator.of(context).pop();

                    await _showCreateFlashcardDialog();
                  },
                ),
                const SizedBox(height: 8),
                _MenuAction(
                  icon: Icons.delete_sweep_outlined,
                  color: const Color(0xFFFF4D67),
                  title: 'Eliminar grupo',
                  subtitle:
                  'Eliminar un grupo y sus FlashCards',
                  onTap: () async {
                    Navigator.of(context).pop();

                    await _showDeleteGroupDialog();
                  },
                ),
                const SizedBox(height: 8),
                _MenuAction(
                  icon: Icons.upload_file_rounded,
                  color: const Color(0xFF00E5FF),
                  title: 'Exportar grupos',
                  subtitle:
                  'Compartir un respaldo con tus grupos',
                  onTap: () async {
                    Navigator.of(context).pop();

                    await _showExportDialog();
                  },
                ),
                const SizedBox(height: 8),
                _MenuAction(
                  icon: Icons.download_rounded,
                  color: const Color(0xFF4CE0B3),
                  title: 'Importar grupos',
                  subtitle:
                  'Restaurar desde un archivo .json',
                  onTap: () async {
                    Navigator.of(context).pop();

                    await _importBackup();
                  },
                ),
                const SizedBox(height: 8),
                _MenuAction(
                  icon: Icons.cloud_sync_outlined,
                  color: const Color(0xFF4CE0B3),
                  title: 'Respaldos en el servidor',
                  subtitle: 'Crear, consultar y restaurar respaldos online',
                  onTap: () async {
                    Navigator.of(context).pop();

                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RemoteBackupScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _MenuAction(
                  icon: Icons.security_outlined,
                  color: const Color(0xFF00E5FF),
                  title: 'Conexión y seguridad',
                  subtitle: 'Configurar el servidor y las credenciales',
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ServerSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // EXPORTAR
  // ============================================================

  Future<void> _showExportDialog() async {
    final provider = context.read<FlashcardProvider>();

    if (provider.groups.isEmpty) {
      _showMessage('No tienes grupos para exportar.');
      return;
    }

    final option = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
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
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'EXPORTAR',
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 2,
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _MenuAction(
                  icon: Icons.inventory_2_outlined,
                  color: const Color(0xFF00E5FF),
                  title: 'Exportar todos',
                  subtitle: 'Compartir todos tus grupos',
                  onTap: () {
                    Navigator.of(context).pop('all');
                  },
                ),
                const SizedBox(height: 8),
                _MenuAction(
                  icon: Icons.folder_outlined,
                  color: const Color(0xFF7C4DFF),
                  title: 'Exportar un grupo',
                  subtitle: 'Elegir un grupo específico',
                  onTap: () {
                    Navigator.of(context).pop('one');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (option == null || !mounted) return;

    if (option == 'all') {
      await _exportAll();
    } else if (option == 'one') {
      await _showPickGroupToExportDialog();
    }
  }

  Future<void> _exportAll() async {
    try {
      final result = await BackupService.instance.exportAll();

      if (!mounted) return;

      await _handleExportResult(result);
    } catch (e) {
      if (!mounted) return;

      _showMessage('No se pudo exportar: $e');
    }
  }

  Future<void> _showPickGroupToExportDialog() async {
    final provider = context.read<FlashcardProvider>();

    final selected = await showDialog<FlashcardGroup>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF111722),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: const Color(0xFF7C4DFF).withValues(alpha: 0.20),
            ),
          ),
          title: const Text('Exportar un grupo'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: provider.groups.length,
              itemBuilder: (context, index) {
                final group = provider.groups[index];

                return ListTile(
                  leading: const Text('🇰🇷', style: TextStyle(fontSize: 22)),
                  title: Text(group.name),
                  subtitle: Text(
                    '${group.flashcardCount} '
                        '${group.flashcardCount == 1 ? 'FlashCard' : 'FlashCards'}',
                  ),
                  onTap: () {
                    Navigator.of(dialogContext).pop(group);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );

    if (selected == null || !mounted) return;

    try {
      final result = await BackupService.instance.exportGroup(selected.id);

      if (!mounted) return;

      await _handleExportResult(result);
    } catch (e) {
      if (!mounted) return;

      _showMessage('No se pudo exportar: $e');
    }
  }

  // ============================================================
  // MANEJAR RESULTADO DE EXPORTAR
  // ============================================================

  Future<void> _handleExportResult(ExportResult result) async {
    if (!mounted) return;

    // Mostrar diálogo con las acciones disponibles
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: const Color(0xFF101621),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF4CE0B3).withValues(alpha: 0.20),
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
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CE0B3).withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF4CE0B3),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Respaldo listo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${result.groupCount} '
                      '${result.groupCount == 1 ? 'grupo' : 'grupos'} · '
                      '${result.flashcardCount} '
                      '${result.flashcardCount == 1 ? 'FlashCard' : 'FlashCards'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 22),
                _MenuAction(
                  icon: Icons.share_rounded,
                  color: const Color(0xFF00E5FF),
                  title: 'Compartir',
                  subtitle: 'WhatsApp, Drive, correo, etc.',
                  onTap: () {
                    Navigator.of(context).pop('share');
                  },
                ),
                const SizedBox(height: 8),
                _MenuAction(
                  icon: Icons.close_rounded,
                  color: Colors.white70,
                  title: 'Cerrar',
                  subtitle: 'No hacer nada más',
                  onTap: () {
                    Navigator.of(context).pop('close');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'share') {
      await _shareBackup(result);
    }
  }

  Future<void> _shareBackup(ExportResult result) async {
    try {
      await BackupService.instance.share(result);
    } catch (e) {
      if (!mounted) return;

      _showMessage('No se pudo compartir: $e');
    }
  }

  // ============================================================
  // IMPORTAR
  // ============================================================

  Future<void> _importBackup() async {
    try {
      final backup = await BackupService.instance.pickAndParseBackup();

      if (backup == null || !mounted) return;

      // Preview
      final totalCards = backup.groups.fold<int>(
        0,
            (sum, g) => sum + g.flashcards.length,
      );

      final preview = backup.groups
          .take(5)
          .map((g) => '• ${g.name} (${g.flashcards.length})')
          .join('\n');

      final extra = backup.groups.length > 5
          ? '\n... y ${backup.groups.length - 5} más'
          : '';

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: const Color(0xFF111722),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: const Color(0xFF4CE0B3).withValues(alpha: 0.25),
              ),
            ),
            title: const Row(
              children: [
                Icon(Icons.download_rounded, color: Color(0xFF4CE0B3)),
                SizedBox(width: 12),
                Text('Confirmar importación'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Se combinarán ${backup.groups.length} grupos '
                        'con $totalCards FlashCards en total:',
                    style: const TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    preview + extra,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '⚠️ Las imágenes NO se importan. Si algún grupo '
                        'duplicaba el nombre, se renombrará '
                        'automáticamente.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4CE0B3),
                  foregroundColor: const Color(0xFF001A14),
                ),
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                icon: const Icon(Icons.check_rounded),
                label: const Text('Importar'),
              ),
            ],
          );
        },
      );

      if (confirmed != true || !mounted) return;

      final imported = await BackupService.instance.importBackup(backup);

      if (!mounted) return;

      _showMessage(
        'Importación combinada completada. '
            'Se procesaron $imported '
            '${imported == 1 ? 'grupo' : 'grupos'}. '
            'Los grupos y tarjetas existentes se conservaron.',
      );

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      _showMessage('No se pudo importar: $e');
    }
  }

  // ============================================================
  // MENSAJES
  // ============================================================

  void _showMessage(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final provider =
    context.watch<FlashcardProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF070A10),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        color: const Color(0xFF00E5FF),
        backgroundColor: const Color(0xFF111722),
        onRefresh: _refresh,
        child: provider.isLoading && provider.groups.isEmpty
            ? _buildLoading()
            : provider.groups.isEmpty
            ? _buildEmptyState()
            : _buildGroupList(
          provider.groups,
        ),
      ),
      floatingActionButton:
      provider.groups.isEmpty
          ? FloatingActionButton.extended(
        onPressed:
        _showCreateGroupDialog,
        backgroundColor:
        const Color(0xFF00E5FF),
        foregroundColor:
        const Color(0xFF001014),
        icon: const Icon(
          Icons.create_new_folder_outlined,
        ),
        label: const Text(
          'Crear grupo',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      )
          : FloatingActionButton(
        onPressed:
        _showCreateFlashcardDialog,
        backgroundColor:
        const Color(0xFF7C4DFF),
        foregroundColor: Colors.white,
        child: const Icon(
          Icons.add_card_rounded,
        ),
      ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF0A0E16),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      leading: IconButton(
        tooltip: 'Menú',
        onPressed: _showMenu,
        icon: const Icon(
          Icons.menu_rounded,
          size: 28,
        ),
      ),
      titleSpacing: 0,
      title: const Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'FLASHCARD SP-KN',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Estudio de coreano',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white54,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Buscar actualizaciones de la app',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const UpdateScreen(),
              ),
            );
          },
          icon: const Icon(
            Icons.system_update_alt_rounded,
          ),
        ),
        IconButton(
          tooltip: 'Actualizar grupos',
          onPressed: _refresh,
          icon: const Icon(
            Icons.refresh_rounded,
          ),
        ),
        const SizedBox(width: 6),
      ],

    );
  }

  // ============================================================
  // LISTA DE GRUPOS
  // ============================================================

  Widget _buildGroupList(
      List<FlashcardGroup> groups,
      ) {
    return LayoutBuilder(
      builder: (
          context,
          constraints,
          ) {
        final width = constraints.maxWidth;

        final horizontalPadding =
        width >= 700 ? 48.0 : 20.0;

        return ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            28,
            horizontalPadding,
            120,
          ),
          children: [
            _buildHeader(),

            const SizedBox(height: 24),

            if (_loadingCounts)
              const Padding(
                padding: EdgeInsets.only(
                  bottom: 16,
                ),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFF00E5FF),
                  backgroundColor:
                  Color(0xFF151B26),
                ),
              ),

            ...groups.map(
                  (group) {
                return Padding(
                  padding:
                  const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: _buildGroupCard(
                    group,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                Color(0xFF00E5FF),
                Color(0xFF9B7CFF),
              ],
            ).createShader(bounds);
          },
          child: const Text(
            'MIS GRUPOS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selecciona un grupo para comenzar a estudiar.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildGroupCard(
      FlashcardGroup group,
      ) {
    final count =
        _flashcardCounts[group.id] ?? 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openGroup(group),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFF101621),
            borderRadius:
            BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.07),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E5FF)
                    .withValues(alpha: 0.025),
                blurRadius: 25,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                _buildGroupIcon(),

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration:
                            const BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                              Color(0xFF00E5FF),
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '$count ${count == 1 ? 'FlashCard' : 'FlashCards'}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white
                                  .withValues(alpha: 0.48),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: 0.035),
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupIcon() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00E5FF)
                .withValues(alpha: 0.16),
            const Color(0xFF7C4DFF)
                .withValues(alpha: 0.12),
          ],
        ),
        borderRadius:
        BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00E5FF)
              .withValues(alpha: 0.14),
        ),
      ),
      child: const Center(
        child: Text(
          '🇰🇷',
          style: TextStyle(
            fontSize: 25,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20,
        28,
        20,
        40,
      ),
      children: [
        Container(
          width: 190,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF151B26),
            borderRadius:
            BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 260,
          height: 18,
          decoration: BoxDecoration(
            color: const Color(0xFF111722),
            borderRadius:
            BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 30),
        ...List.generate(
          4,
              (index) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: Container(
                height: 92,
                decoration: BoxDecoration(
                  color: const Color(0xFF101621),
                  borderRadius:
                  BorderRadius.circular(22),
                  border: Border.all(
                    color:
                    Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return ListView(
      physics:
      const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 40,
      ),
      children: [
        const SizedBox(
          height: 80,
        ),
        Center(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00E5FF)
                  .withValues(alpha: 0.06),
              border: Border.all(
                color: const Color(0xFF00E5FF)
                    .withValues(alpha: 0.12),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.style_outlined,
                size: 48,
                color: Color(0xFF00E5FF),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Center(
          child: Text(
            'Aún no tienes grupos',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 340,
            ),
            child: Text(
              'Crea tu primer grupo para comenzar a guardar y estudiar tus FlashCards de coreano.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white
                    .withValues(alpha: 0.55),
                height: 1.5,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Center(
          child: FilledButton.icon(
            onPressed:
            _showCreateGroupDialog,
            icon: const Icon(
              Icons.add_rounded,
            ),
            label: const Text(
              'Crear mi primer grupo',
            ),
            style: FilledButton.styleFrom(
              backgroundColor:
              const Color(0xFF00E5FF),
              foregroundColor:
              const Color(0xFF001014),
              padding:
              const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ITEM DEL MENÚ BURGER
// ============================================================

class _MenuAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white
                .withValues(alpha: 0.025),
            borderRadius:
            BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white
                  .withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color:
                  color.withValues(alpha: 0.10),
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow:
                      TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white
                            .withValues(alpha: 0.42),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white38,
              ),
            ],
          ),
        ),
      ),
    );
  }
}