import 'package:flutter_secure_storage/flutter_secure_storage.dart';
//aqui vamos a almacenar la direccion del backen personal y el token de acceso para que este fuera delAPK
class ApiConfigService {
  ApiConfigService._();
  static final ApiConfigService instance = ApiConfigService._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();//aqui importamos para usar el storage para almacenar keys entre otros
  static const String _serverUrlKey = 'flashcard_server_url';
  static const String _accessTokenKey = 'flashcard_server_access_token';

  Future<String?> readServerUrl() => _storage.read(key: _serverUrlKey);
  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> save({required String serverUrl, required String accessToken}) async{
    final normalizedUrl = serverUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.tryParse(normalizedUrl);//es para validar la url

    if (uri == null || !uri.hasAuthority || (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw Exception('Ingresa una URL valida que comience con http:// o https://');
    }
    if (uri.userInfo.isNotEmpty || uri.query.isNotEmpty || uri.fragment.isNotEmpty) {
      throw const FormatException('La URL no debe contener credenciales, parametros ni fragmentos');
    }
    if (accessToken.trim().length < 32) {
      throw const FormatException('El token debe tener al menos 32 caracteres');
    }
    await _storage.write(key: _serverUrlKey, value: normalizedUrl);//es para guardar la url
    await _storage.write(key: _accessTokenKey, value: accessToken);//es para guardar el token de acceso
  }

  Future<void> clear() async {//es para borrar la url y el token de acceso
    await _storage.delete(key: _serverUrlKey);
    await _storage.delete(key: _accessTokenKey);
  }
  Future<({String baseUrl, String token})> requireConfiguration() async {
    final baseUrl = (await readServerUrl())?.trim() ?? '';
    final token = (await readAccessToken())?.trim() ?? '';
    if (baseUrl.isEmpty) {
      throw Exception('Configura la direccion y el token del servidor desde el menu de la aplicacion');
    }
    return (baseUrl: baseUrl, token: token);
  }


}