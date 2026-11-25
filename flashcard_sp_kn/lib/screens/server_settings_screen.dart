import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../services/api_config_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/gemini_config_service.dart';

class ServerSettingsScreen extends StatefulWidget {
  const ServerSettingsScreen({super.key});

  @override
  State<ServerSettingsScreen> createState() => _ServerSettingsScreenState();
}

class _ServerSettingsScreenState extends State<ServerSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _geminiKeyController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _obscureToken = true;
  bool _hasGeminiKey = false;
  bool _showGeminiKey = false;
  bool _editingGeminiKey = false;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    final config = ApiConfigService.instance;
    _urlController.text = await config.readServerUrl() ?? '';
    _tokenController.text = await config.readAccessToken() ?? '';
    _hasGeminiKey = await GeminiConfigService.instance.hasApiKey();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiConfigService.instance.save(
        serverUrl: _urlController.text,
        accessToken: _tokenController.text,
      );
      if (!mounted) return;
      _showMessage('Configuración del servidor guardada de forma segura.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final url = _urlController.text.trim().replaceFirst(RegExp(r'/+$'), '');
      final dio = Dio(BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'Authorization': 'Bearer ${_tokenController.text.trim()}'},
      ));
      await dio.get('/api/auth/check');
      if (!mounted) return;
      _showMessage('Conexión y autenticación verificadas correctamente.');
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      _showMessage(status == 401
          ? 'El servidor respondió, pero el token no es válido.'
          : 'No se pudo verificar el servidor: ${error.message ?? 'error de conexión'}.');
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearConfiguration() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar configuración'),
        content: const Text(
          'Se eliminarán del almacenamiento seguro la dirección y el token del servidor de este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ApiConfigService.instance.clear();
    _urlController.clear();
    _tokenController.clear();
    if (mounted) _showMessage('Configuración del servidor eliminada.');
  }

  Future<bool> _authenticate(String reason) async {
    try {
      final authenticated = await BiometricAuthService.instance.authenticate(
        reason: reason,
      );
      if (!authenticated && mounted) {
        _showMessage('No se confirmó la autenticación.');
      }
      return authenticated;
    } catch (error) {
      if (mounted) _showMessage(error.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Future<void> _revealGeminiKey() async {
    if (!await _authenticate(
      'Confirma tu huella para mostrar la API Key de Gemini.',
    )) {
      return;
    }

    final key = await GeminiConfigService.instance.readApiKey();

    if (!mounted) return;

    if (key == null || key.isEmpty) {
      setState(() => _hasGeminiKey = false);
      _showMessage('No hay una API Key de Gemini guardada.');
      return;
    }

    setState(() {
      _geminiKeyController.text = key;
      _showGeminiKey = true;
      _editingGeminiKey = false;
    });
  }

  Future<void> _prepareGeminiKeyReplacement() async {
    if (!await _authenticate('Confirma tu huella para modificar la API Key de Gemini.')) {
      return;
    }
    if (!mounted) return;
    setState(() {
      _geminiKeyController.clear();
      _showGeminiKey = false;
      _editingGeminiKey = true;
    });
  }

  Future<void> _saveGeminiKey() async {
    final key = _geminiKeyController.text.trim();
    if (key.isEmpty) {
      _showMessage('Ingresa tu API Key de Gemini.');
      return;
    }
    if (!await _authenticate('Confirma tu huella para guardar la API Key de Gemini.')) {
      return;
    }

    setState(() => _saving = true);
    try {
      await GeminiConfigService.instance.saveApiKey(key);
      if (!mounted) return;
      setState(() {
        _hasGeminiKey = true;
        _showGeminiKey = false;
        _editingGeminiKey = false;
        _geminiKeyController.clear();
      });
      _showMessage('API Key de Gemini guardada de forma segura.');
    } catch (error) {
      _showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteGeminiKey() async {
    if (!await _authenticate('Confirma tu huella para eliminar la API Key de Gemini.')) {
      return;
    }
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar API Key de Gemini'),
        content: const Text(
          'La aplicación dejará de poder utilizar Gemini directamente cuando el servidor no esté disponible. Esta acción no elimina la configuración del servidor.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar API Key'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await GeminiConfigService.instance.clearApiKey();
    if (!mounted) return;
    setState(() {
      _hasGeminiKey = false;
      _showGeminiKey = false;
      _editingGeminiKey = false;
      _geminiKeyController.clear();
    });
    _showMessage('API Key de Gemini eliminada del dispositivo.');
  }

  void _cancelGeminiKeyEdit() {
    setState(() {
      _geminiKeyController.clear();
      _showGeminiKey = false;
      _editingGeminiKey = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _tokenController.dispose();
    _geminiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conexión y seguridad')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.shield_outlined, size: 52),
          const SizedBox(height: 12),
          Text('Servidor personal',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'Configura la dirección del backend y el token de acceso. Ambos valores se guardan en el almacenamiento seguro de Android y no se incorporan al APK.',
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'URL del servidor',
                    hintText: 'https://tu-servidor.example',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final uri = Uri.tryParse((value ?? '').trim());
                    if (uri == null ||
                        !uri.hasAuthority ||
                        (uri.scheme != 'https' && uri.scheme != 'http')) {
                      return 'Ingresa una URL http:// o https:// válida.';
                    }
                    if (uri.userInfo.isNotEmpty ||
                        uri.query.isNotEmpty ||
                        uri.fragment.isNotEmpty) {
                      return 'No incluyas credenciales ni parámetros en la URL.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _tokenController,
                  obscureText: _obscureToken,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Token de acceso',
                    prefixIcon: const Icon(Icons.key_outlined),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(
                              () => _obscureToken = !_obscureToken),
                      icon: Icon(_obscureToken
                          ? Icons.visibility
                          : Icons.visibility_off),
                    ),
                  ),
                  validator: (value) => (value ?? '').trim().length < 32
                      ? 'El token debe tener al menos 32 caracteres.'
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Importante: utiliza HTTPS cuando el servidor sea accesible desde Internet. HTTP debe reservarse para pruebas en una red local de confianza; no envíes tu token por redes públicas.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : _saveConfiguration,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving
                ? 'Procesando...'
                : 'Guardar configuración del servidor'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _saving ? null : _testConnection,
            icon: const Icon(Icons.wifi_tethering),
            label: const Text('Probar conexión y token'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _saving ? null : _clearConfiguration,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Eliminar configuración del servidor'),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gemini directo de respaldo',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Icon(
                _hasGeminiKey ? Icons.check_circle : Icons.info_outline,
                color: _hasGeminiKey
                    ? Colors.green
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _hasGeminiKey
                ? 'Hay una API Key guardada en este dispositivo. Se utilizará si el servidor principal no está disponible.'
                : 'No hay una API Key personal configurada. Puedes agregarla para utilizar Gemini cuando tu servidor esté apagado o no responda.',
          ),
          const SizedBox(height: 14),
          if (_hasGeminiKey && !_editingGeminiKey) ...[
            TextField(
              controller: _geminiKeyController,
              readOnly: true,
              obscureText: !_showGeminiKey,
              enableInteractiveSelection: _showGeminiKey,
              decoration: InputDecoration(
                labelText: 'API Key de Gemini',
                hintText: 'API Key guardada de forma segura',
                prefixIcon: const Icon(Icons.key),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: _showGeminiKey
                      ? 'Ocultar API Key'
                      : 'Mostrar con huella',
                  onPressed: _showGeminiKey
                      ? () => setState(() {
                    _showGeminiKey = false;
                    _geminiKeyController.clear();
                  })
                      : _revealGeminiKey,
                  icon: Icon(
                    _showGeminiKey
                        ? Icons.visibility_off
                        : Icons.fingerprint,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _saving ? null : _prepareGeminiKeyReplacement,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Reemplazar API Key'),
            ),
            TextButton.icon(
              onPressed: _saving ? null : _deleteGeminiKey,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar API Key'),
            ),
          ] else ...[
            TextField(
              controller: _geminiKeyController,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'API Key de Gemini',
                hintText: 'Pega aquí tu API Key',
                prefixIcon: Icon(Icons.key),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _saving ? null : _saveGeminiKey,
              icon: const Icon(Icons.lock_outline),
              label: Text(_saving
                  ? 'Guardando...'
                  : 'Guardar API Key con huella'),
            ),
            if (_hasGeminiKey)
              TextButton(
                onPressed: _saving ? null : _cancelGeminiKeyEdit,
                child: const Text('Cancelar reemplazo'),
              ),
          ],
          const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orden de modelos de respaldo',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('1. gemini-3.5-flash-lite'),
                  Text('2. gemini-3.1-flash-lite'),
                  Text('3. gemini-2.5-flash-lite'),
                  SizedBox(height: 8),
                  Text(
                    'La aplicación intentará el siguiente modelo cuando detecte saturación o indisponibilidad temporal. La disponibilidad y las cuotas dependen de Google.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
