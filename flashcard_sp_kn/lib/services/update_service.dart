import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_release.dart';
import 'api_config_service.dart';

class UpdateService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
      },
    ),
  );

  /// Obtiene la versión y compilación reales de la aplicación instalada.
  Future<PackageInfo> getInstalledVersion() async {
    return PackageInfo.fromPlatform();
  }

  /// Consulta el manifiesto y devuelve la versión si hay una actualización.
  /// Devuelve null cuando la aplicación ya está actualizada.
  Future<AppRelease?> checkForUpdate() async {
    final installed = await getInstalledVersion();

    final installedVersion = installed.version;
    final installedBuild =
        int.tryParse(installed.buildNumber) ?? 0;

    final serverUrl = await ApiConfigService.instance.readServerUrl();
    if (serverUrl == null || serverUrl.trim().isEmpty) {
      throw Exception('Configura la dirección del servidor desde el menú de la aplicación.');
    }
    final manifestUrl = '${serverUrl.trim().replaceFirst(RegExp(r'/+$'), '')}/manifest.json';
    final response = await _dio.get<dynamic>(manifestUrl);

    if (response.statusCode != 200 || response.data == null) {
      throw Exception(
        'No se pudo obtener el manifiesto de actualización.',
      );
    }

    final dynamic data = response.data;

    final Map<String, dynamic> json = data is Map
        ? Map<String, dynamic>.from(data)
        : data is String
        ? Map<String, dynamic>.from(
      jsonDecode(data) as Map,
    )
        : throw const FormatException(
      'Formato de manifiesto no válido.',
    );

    final release = AppRelease.fromJson(json);

    // La comparación se realiza con el número de compilación.
    if (release.buildNumber > installedBuild) {
      return release;
    }

    return null;
  }




  /// Descarga el APK y comprueba su SHA-256.
  /// Devuelve el archivo solamente si la verificación es correcta.
  Future<File> downloadUpdate(
      AppRelease release, {
        void Function(int received, int total)? onProgress,
      }) async {
    final directory = await getTemporaryDirectory();

    final apkFile = File(
      '${directory.path}/flashcard-sp-kn-update.apk',
    );

    // Eliminar una descarga anterior para evitar reutilizarla.
    if (await apkFile.exists()) {
      await apkFile.delete();
    }

    try {
      await _dio.download(
        release.apkUrl,
        apkFile.path,
        onReceiveProgress: onProgress,
        deleteOnError: true,
      );

      if (!await apkFile.exists()) {
        throw Exception('No se encontró el APK descargado.');
      }

      final bytes = await apkFile.readAsBytes();
      final actualHash = sha256.convert(bytes).toString();

      if (actualHash.toLowerCase() !=
          release.sha256.toLowerCase()) {
        await apkFile.delete();

        throw Exception(
          'La verificación SHA-256 falló. '
              'El APK descargado no coincide con el manifiesto.',
        );
      }

      return apkFile;
    } catch (_) {
      if (await apkFile.exists()) {
        await apkFile.delete();
      }
      rethrow;
    }
  }

  void dispose() {
    _dio.close();
  }
}