
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_release.dart';
import '../services/update_service.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  final UpdateService _updateService = UpdateService();

  PackageInfo? _installed;
  AppRelease? _release;

  bool _checking = false;
  bool _downloading = false;
  double _progress = 0;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  @override
  void dispose() {
    _updateService.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    if (_checking || _downloading) return;

    setState(() {
      _checking = true;
      _error = null;
      _message = null;
      _release = null;
    });

    try {
      final installed =
      await _updateService.getInstalledVersion();

      final release =
      await _updateService.checkForUpdate();

      if (!mounted) return;

      setState(() {
        _installed = installed;
        _release = release;
        _message = release == null
            ? 'Ya tienes instalada la última versión.'
            : 'Hay una actualización disponible.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudo consultar el servidor.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
        });
      }
    }
  }

  Future<void> _downloadAndInstall() async {
    final release = _release;
    if (release == null || _downloading) return;

    setState(() {
      _downloading = true;
      _progress = 0;
      _error = null;
      _message = null;
    });

    try {
      final File apk = await _updateService.downloadUpdate(
        release,
        onProgress: (received, total) {
          if (!mounted || total <= 0) return;

          setState(() {
            _progress = received / total;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        _message =
        'Descarga verificada. Abriendo el instalador de Android...';
      });

      final result = await OpenFilex.open(
        apk.path,
        type: 'application/vnd.android.package-archive',
      );

      if (!mounted) return;

      if (result.type != ResultType.done) {
        setState(() {
          _error =
          'No se pudo abrir el instalador: ${result.message}';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'No se pudo descargar o verificar el APK.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _downloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final installed = _installed;
    final release = _release;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualización'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            const Icon(
              Icons.system_update_alt_rounded,
              size: 76,
            ),
            const SizedBox(height: 16),
            Text(
              'FlashCard SP-KN',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _versionRow(
                      'Versión instalada',
                      installed == null
                          ? 'Consultando...'
                          : '${installed.version}+${installed.buildNumber}',
                    ),
                    const Divider(height: 24),
                    _versionRow(
                      'Versión disponible',
                      _checking
                          ? 'Consultando...'
                          : release == null
                          ? 'No hay una versión nueva'
                          : '${release.version}+${release.buildNumber}',
                    ),
                  ],
                ),
              ),
            ),

            if (release != null) ...[
              const SizedBox(height: 20),
              Text(
                'Novedades',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...release.releaseNotes.map(
                    (note) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(note)),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            if (_checking)
              const Center(child: CircularProgressIndicator()),

            if (_downloading) ...[
              LinearProgressIndicator(
                value: _progress > 0 ? _progress : null,
              ),
              const SizedBox(height: 8),
              Text(
                _progress > 0
                    ? 'Descargando: ${(_progress * 100).toStringAsFixed(0)}%'
                    : 'Preparando descarga...',
                textAlign: TextAlign.center,
              ),
            ],

            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                textAlign: TextAlign.center,
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: _checking || _downloading
                  ? null
                  : _checkForUpdate,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Buscar actualización'),
            ),

            const SizedBox(height: 10),

            if (release != null)
              FilledButton.icon(
                onPressed:
                _checking || _downloading
                    ? null
                    : _downloadAndInstall,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Descargar e instalar'),
              ),

            const SizedBox(height: 16),

            const Text(
              'La descarga se verifica mediante SHA-256. '
                  'Android solicitará confirmación antes de instalar. '
                  'No desinstales la aplicación actual, porque eso '
                  'puede eliminar sus datos locales.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _versionRow(String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
