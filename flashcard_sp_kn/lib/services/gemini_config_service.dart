import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Almacena la API Key personal de Gemini separada de las credenciales
/// del servidor FlashCard. Nunca se incluye una clave dentro del APK.
class GeminiConfigService {
  GeminiConfigService._();

  static final GeminiConfigService instance = GeminiConfigService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _apiKeyStorageKey = 'flashcard_gemini_api_key';

  Future<String?> readApiKey() => _storage.read(key: _apiKeyStorageKey);

  Future<bool> hasApiKey() async {
    final key = await readApiKey();
    return key != null && key.trim().isNotEmpty;
  }

  Future<void> saveApiKey(String apiKey) async {
    final normalized = apiKey.trim();
    if (normalized.isEmpty) {
      throw const FormatException('Ingresa una API Key de Gemini.');
    }
    if (normalized.length < 20) {
      throw const FormatException('La API Key parece incompleta. Revísala.');
    }
    await _storage.write(key: _apiKeyStorageKey, value: normalized);
  }

  Future<void> clearApiKey() => _storage.delete(key: _apiKeyStorageKey);
}
