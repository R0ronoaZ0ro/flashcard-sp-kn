import 'dart:convert';

import 'package:dio/dio.dart';

import 'api_config_service.dart';
import 'gemini_config_service.dart';

class AiService {
  AiService._();

  static final AiService instance = AiService._();

  // Lista centralizada para poder sustituir modelos cuando Google los retire
  // o cambie su disponibilidad. El orden determina la prioridad.
  static const List<String> directGeminiModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash-lite',
  ];

  Future<AiTranslationResult> translateAndComplete(String koreanText) async {
    final text = koreanText.trim();
    if (text.isEmpty) {
      throw Exception('El texto coreano está vacío.');
    }
    if (text.length > 300) {
      throw Exception('El texto no puede superar los 300 caracteres.');
    }

    String? serverFailure;
    final serverUrl = (await ApiConfigService.instance.readServerUrl())?.trim() ?? '';
    final serverToken = (await ApiConfigService.instance.readAccessToken())?.trim() ?? '';

    if (serverUrl.isNotEmpty && serverToken.isNotEmpty) {
      try {
        return await _translateThroughServer(text, serverUrl, serverToken);
      } on _DoNotFallbackException catch (error) {
        throw Exception(error.message);
      } catch (error) {
        serverFailure = error.toString().replaceFirst('Exception: ', '');
      }
    }

    final apiKey = (await GeminiConfigService.instance.readApiKey())?.trim() ?? '';
    if (apiKey.isEmpty) {
      if (serverFailure != null) {
        throw Exception(
          '$serverFailure\n\nNo hay una API Key personal de Gemini configurada. Abre Conexión y seguridad para agregarla.',
        );
      }
      throw Exception(
        'No hay un servidor configurado o disponible ni una API Key personal de Gemini. Configura al menos una opción en Conexión y seguridad.',
      );
    }

    try {
      return await _translateDirectWithModelRotation(text, apiKey);
    } catch (error) {
      final directFailure = error.toString().replaceFirst('Exception: ', '');
      if (serverFailure != null) {
        throw Exception(
          'El servidor no estuvo disponible ($serverFailure) y Gemini directo tampoco pudo completar la solicitud: $directFailure',
        );
      }
      rethrow;
    }
  }

  Future<AiTranslationResult> _translateThroughServer(
      String text,
      String baseUrl,
      String token,
      ) async {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 55),
      sendTimeout: const Duration(seconds: 25),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ));

    try {
      final response = await dio.post<Map<String, dynamic>>(
        '/api/ai/complete',
        data: {'text': text},
      );
      final data = response.data;
      if (data == null) {
        throw const FormatException('El servidor devolvió una respuesta vacía.');
      }
      return _parseTranslation(data);
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        throw _DoNotFallbackException(
          'El servidor rechazó la autenticación. Revisa el token guardado en Conexión y seguridad.',
        );
      }
      if (status != null && status != 429 && status < 500) {
        final message = error.response?.data is Map
            ? (error.response?.data['error']?.toString() ?? '')
            : '';
        throw _DoNotFallbackException(
          message.isNotEmpty
              ? message
              : 'El servidor rechazó la solicitud (HTTP $status).',
        );
      }
      // 429, errores 5xx, timeout o falta de conexión: se intenta Gemini directo.
      throw Exception(_serverErrorMessage(error));
    } on FormatException catch (error) {
      throw Exception('El servidor devolvió datos incompletos: ${error.message}');
    }
  }

  String _serverErrorMessage(DioException error) {
    final status = error.response?.statusCode;
    if (status == 429) {
      return 'El servidor alcanzó su límite de solicitudes (429). Se probará Gemini directo.';
    }
    if (status != null && status >= 500) {
      return 'El servidor presentó un error interno (HTTP $status). Se probará Gemini directo.';
    }
    return 'No se pudo conectar con el servidor (${error.message ?? 'error de conexión'}). Se probará Gemini directo.';
  }

  Future<AiTranslationResult> _translateDirectWithModelRotation(
      String koreanText,
      String apiKey,
      ) async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://generativelanguage.googleapis.com',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 25),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      },
    ));

    final failures = <String>[];
    for (final model in directGeminiModels) {
      try {
        final response = await dio.post<Map<String, dynamic>>(
          '/v1beta/models/$model:generateContent',
          data: {
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': _buildPrompt(koreanText)},
                ],
              },
            ],
            'generationConfig': {
              'temperature': 0.25,
              'responseMimeType': 'application/json',
            },
          },
        );

        final responseText = _extractGeminiText(response.data);
        final decoded = jsonDecode(_stripJsonFences(responseText));
        if (decoded is! Map) {
          throw const FormatException('Gemini no devolvió un objeto JSON.');
        }
        return _parseTranslation(Map<String, dynamic>.from(decoded));
      } on DioException catch (error) {
        final status = error.response?.statusCode;
        final apiMessage = _geminiErrorMessage(error);
        failures.add('$model: $apiMessage');

        // La clave inválida, permisos o solicitudes incorrectas no se arreglan
        // cambiando de modelo. Sí se rota ante cuota, saturación o modelo ausente.
        if (status == 400 || status == 401 || status == 403) {
          throw Exception(apiMessage);
        }
        if (status != null &&
            status < 500 &&
            status != 404 &&
            status != 408 &&
            status != 429) {
          throw Exception(apiMessage);
        }
      } on FormatException catch (error) {
        failures.add('$model: respuesta no válida (${error.message})');
      }
    }

    throw Exception(
      'Ninguno de los modelos Gemini pudo completar la traducción. ${failures.join(' | ')}',
    );
  }

  String _buildPrompt(String koreanText) => '''
Eres un asistente especializado en idioma coreano para estudiantes hispanohablantes.
Analiza exclusivamente el texto coreano proporcionado y responde en español.

Texto coreano: "$koreanText"

Devuelve únicamente un objeto JSON válido, sin Markdown ni texto adicional, con esta estructura exacta:
{
  "translation": "traducción natural al español",
  "romanization": "romanización en Revised Romanization of Korean",
  "example": {
    "korean": "una oración breve y natural en coreano que use la expresión",
    "spanish": "traducción al español de esa misma oración"
  },
  "context": "contexto de uso: situación, registro y con quién se utiliza",
  "note": "explicación breve de matices, gramática o uso relevante"
}

Reglas:
- Completa todos los campos y no dejes cadenas vacías.
- La romanización debe corresponder al texto coreano original, no a la traducción.
- El ejemplo coreano y su traducción española deben expresar exactamente la misma idea.
- Usa explicaciones breves, claras y útiles para estudiar.
- No inventes significados ni agregues información ajena al texto.
- No incluyas comentarios sobre K-pop, dramas, celebridades o medios, salvo que el texto lo requiera directamente.
- Si el texto admite varios sentidos, indica el más habitual y aclara brevemente la ambigüedad en "note".
''';

  String _extractGeminiText(Map<String, dynamic>? data) {
    if (data == null) {
      throw const FormatException('Gemini devolvió una respuesta vacía.');
    }
    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty || candidates.first is! Map) {
      throw const FormatException('Gemini no devolvió contenido utilizable.');
    }
    final content = (candidates.first as Map)['content'];
    if (content is! Map || content['parts'] is! List) {
      throw const FormatException('La respuesta de Gemini no contiene partes de texto.');
    }
    final parts = content['parts'] as List;
    final texts = parts
        .whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .toList();
    if (texts.isEmpty) {
      throw const FormatException('Gemini no generó texto.');
    }
    return texts.join('\n').trim();
  }

  String _stripJsonFences(String text) {
    var value = text.trim();
    if (value.startsWith('```')) {
      value = value.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      value = value.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return value.trim();
  }

  String _geminiErrorMessage(DioException error) {
    final data = error.response?.data;
    final message = data is Map && data['error'] is Map
        ? (data['error']['message']?.toString() ?? '')
        : '';
    final status = error.response?.statusCode;
    if (status == 400 || status == 401 || status == 403) {
      return message.isNotEmpty
          ? 'Gemini rechazó la API Key o la solicitud: $message'
          : 'Gemini rechazó la API Key o no tiene permisos (HTTP $status).';
    }
    if (status == 429) return 'límite de uso o saturación (HTTP 429)';
    if (status == 404) return 'modelo no disponible (HTTP 404)';
    if (status != null && status >= 500) return 'servicio temporalmente no disponible (HTTP $status)';
    return error.message ?? 'error de conexión';
  }

  AiTranslationResult _parseTranslation(Map<dynamic, dynamic> data) {
    final example = data['example'];
    if (example is! Map) {
      throw const FormatException('Falta el objeto de ejemplo en la respuesta.');
    }

    String readText(Map<dynamic, dynamic> map, String key) {
      final value = map[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('No se completó correctamente el campo "$key".');
      }
      return value.trim();
    }

    return AiTranslationResult(
      translation: readText(data, 'translation'),
      romanization: readText(data, 'romanization'),
      exampleKorean: readText(example, 'korean'),
      exampleSpanish: readText(example, 'spanish'),
      context: readText(data, 'context'),
      note: readText(data, 'note'),
    );
  }
}

class _DoNotFallbackException implements Exception {
  const _DoNotFallbackException(this.message);
  final String message;
}

class AiTranslationResult {
  final String translation;
  final String romanization;
  final String exampleKorean;
  final String exampleSpanish;
  final String context;
  final String note;

  AiTranslationResult({
    required this.translation,
    required this.romanization,
    required this.exampleKorean,
    required this.exampleSpanish,
    required this.context,
    required this.note,
  });

  bool get isEmpty => translation.isEmpty &&
      romanization.isEmpty &&
      exampleKorean.isEmpty &&
      exampleSpanish.isEmpty &&
      context.isEmpty &&
      note.isEmpty;
}
