
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService._();

  static final BiometricAuthService instance =
  BiometricAuthService._();

  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> hasEnrolledBiometrics() async {
    try {
      final available = await _auth.getAvailableBiometrics();

      // Acepta los tipos biométricos que Android pueda reportar.
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({
    String reason =
    'Confirma tu identidad para mostrar la API Key de Gemini.',
  }) async {
    final supported = await _auth.isDeviceSupported();

    if (!supported) {
      throw Exception(
        'Este dispositivo no admite autenticación local.',
      );
    }

    final biometrics = await _auth.getAvailableBiometrics();

    if (biometrics.isEmpty) {
      throw Exception(
        'No hay datos biométricos registrados o disponibles. '
            'Configura una huella en los ajustes de Android.',
      );
    }

    return _auth.authenticate(
      localizedReason: reason,
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
  }
}
