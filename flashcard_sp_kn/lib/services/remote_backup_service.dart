import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/backup_data.dart';
import 'api_config_service.dart';

class RemoteBackupService {
  RemoteBackupService._();

  static final RemoteBackupService instance = RemoteBackupService._();

  Future<Dio> _client() async {
    final config = await ApiConfigService.instance.requireConfiguration();
    return Dio(BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${config.token}',
      },
    ));
  }

  Future<RemoteBackup> uploadBackup(BackupData backup) async {
    final dio = await _client();
    try {
      final response = await dio.post('/api/backups', data: backup.toMap());
      final payload = Map<String, dynamic>.from(response.data as Map);
      return RemoteBackup.fromMap(
        Map<String, dynamic>.from(payload['backup'] as Map),
      );
    } on DioException catch (error) {
      throw Exception('No se pudo subir el respaldo: ${_errorMessage(error)}');
    }
  }

  Future<List<RemoteBackup>> getRemoteBackups() async {
    final dio = await _client();
    try {
      final response = await dio.get('/api/backups');
      final dynamic responseData = response.data;
      final List<dynamic> backups;
      if (responseData is Map) {
        backups = List<dynamic>.from(responseData['backups'] ?? []);
      } else if (responseData is List) {
        backups = responseData;
      } else {
        throw const FormatException('Respuesta del historial no válida.');
      }
      return backups.map((item) => RemoteBackup.fromMap(
        Map<String, dynamic>.from(item as Map),
      )).toList();
    } on DioException catch (error) {
      throw Exception('No se pudo obtener el historial: ${_errorMessage(error)}');
    }
  }

  Future<BackupData> downloadRemoteBackup(String backupId) async {
    final dio = await _client();
    try {
      final response = await dio.get('/api/backups/$backupId');
      dynamic decoded = response.data;
      if (decoded is String) decoded = jsonDecode(decoded);
      if (decoded is! Map) {
        throw const FormatException('El respaldo descargado no tiene un formato válido.');
      }
      final envelope = Map<String, dynamic>.from(decoded);
      final backupContent = envelope['data'] ?? envelope;
      if (backupContent is! Map) {
        throw const FormatException('No se encontró el contenido del respaldo.');
      }
      return BackupData.fromMap(Map<String, dynamic>.from(backupContent));
    } on DioException catch (error) {
      throw Exception('No se pudo descargar el respaldo: ${_errorMessage(error)}');
    }
  }

  Future<void> deleteRemoteBackup(String backupId) async {
    final dio = await _client();
    try {
      await dio.delete('/api/backups/$backupId');
    } on DioException catch (error) {
      throw Exception('No se pudo eliminar el respaldo: ${_errorMessage(error)}');
    }
  }

  String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['error'] != null) return data['error'].toString();
    return data?.toString() ?? error.message ?? 'Error de conexión';
  }
}

class RemoteBackup {
  final String id;
  final String createdAt;
  final int groupCount;
  final int flashcardCount;

  RemoteBackup({
    required this.id,
    required this.createdAt,
    required this.groupCount,
    required this.flashcardCount,
  });

  factory RemoteBackup.fromMap(Map<String, dynamic> map) {
    return RemoteBackup(
      id: (map['id'] ?? '').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
      groupCount: (map['group_count'] as num?)?.toInt() ?? 0,
      flashcardCount: (map['flashcard_count'] as num?)?.toInt() ?? 0,
    );
  }

  DateTime? get date => DateTime.tryParse(createdAt)?.toLocal();
}
