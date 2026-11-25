
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/flashcard_provider.dart';
import '../services/backup_service.dart';
import '../services/remote_backup_service.dart';

class RemoteBackupScreen extends StatefulWidget {
  const RemoteBackupScreen({super.key});

  @override
  State<RemoteBackupScreen> createState() =>
      _RemoteBackupScreenState();
}

class _RemoteBackupScreenState extends State<RemoteBackupScreen> {
  final RemoteBackupService _remote =
      RemoteBackupService.instance;

  List<RemoteBackup> _backups = [];

  bool _loading = true;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  // ============================================================
  // CARGAR HISTORIAL
  // ============================================================

  Future<void> _loadBackups() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final backups = await _remote.getRemoteBackups();

      if (!mounted) return;

      setState(() {
        _backups = backups;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ============================================================
  // CREAR RESPALDO MANUAL
  // ============================================================

  Future<void> _createBackup() async {
    if (_uploading) return;

    setState(() {
      _uploading = true;
    });

    try {
      final backup = await BackupService.instance.createBackupData();

      if (backup.groups.isEmpty) {
        throw Exception('No tienes grupos para respaldar.');
      }

      final result = await _remote.uploadBackup(backup);

      if (!mounted) return;

      _showMessage(
        'Respaldo creado correctamente: '
            '${result.groupCount} grupos y '
            '${result.flashcardCount} FlashCards.',
      );

      await _loadBackups();
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo crear el respaldo: $e');
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  // ============================================================
  // RESTAURAR RESPALDO
  // ============================================================

  Future<void> _restoreBackup(RemoteBackup backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restaurar respaldo'),
          content: Text(
            'Se descargarán ${backup.groupCount} grupos y '
                '${backup.flashcardCount} FlashCards.\n\n'
                'Los datos se combinarán con los que ya tienes. '
                'No se reemplazará tu base de datos.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    _showMessage('Descargando respaldo...');

    try {
      final data = await _remote.downloadRemoteBackup(backup.id);

      final imported =
      await BackupService.instance.importBackup(data);

      if (!mounted) return;

      await context.read<FlashcardProvider>().refresh();

      if (!mounted) return;

      _showMessage(
        'Restauración completada. '
            'Se procesaron $imported grupos.',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo restaurar: $e');
    }
  }

  // ============================================================
  // ELIMINAR RESPALDO
  // ============================================================

  Future<void> _deleteBackup(RemoteBackup backup) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar respaldo'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar este respaldo '
                'del servidor? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _remote.deleteRemoteBackup(backup.id);

      if (!mounted) return;

      _showMessage('Respaldo eliminado.');
      await _loadBackups();
    } catch (e) {
      if (!mounted) return;
      _showMessage('No se pudo eliminar: $e');
    }
  }

  // ============================================================
  // MENSAJES
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // INTERFAZ
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respaldos en el servidor'),
        actions: [
          IconButton(
            tooltip: 'Actualizar historial',
            onPressed: _loading ? null : _loadBackups,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _uploading ? null : _createBackup,
                icon: _uploading
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _uploading
                      ? 'Creando respaldo...'
                      : 'Crear respaldo manual',
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Historial de respaldos',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_backups.length} / 10',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildBackupList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupList() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'No se pudo conectar con el servidor.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadBackups,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_backups.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.backup_outlined,
                size: 56,
              ),
              SizedBox(height: 12),
              Text(
                'Todavía no tienes respaldos.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Pulsa "Crear respaldo manual" para guardar '
                    'tus grupos y FlashCards en el servidor.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBackups,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: _backups.length,
        itemBuilder: (context, index) {
          final backup = _backups[index];

          final date = backup.date;
          final dateText = date == null
              ? backup.createdAt
              : '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/'
              '${date.year} '
              '${date.hour.toString().padLeft(2, '0')}:'
              '${date.minute.toString().padLeft(2, '0')}';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.cloud_done_outlined,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateText,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${backup.groupCount} grupos · '
                                  '${backup.flashcardCount} FlashCards',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'restore') {
                            _restoreBackup(backup);
                          } else if (value == 'delete') {
                            _deleteBackup(backup);
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'restore',
                            child: Row(
                              children: [
                                Icon(Icons.download),
                                SizedBox(width: 8),
                                Text('Restaurar'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text('Eliminar'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _restoreBackup(backup),
                      icon: const Icon(Icons.restore),
                      label: const Text('Descargar y restaurar'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
