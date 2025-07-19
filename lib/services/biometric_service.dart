// lib/services/biometric_service.dart
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import '../utils/debug_logger.dart';

class BiometricService {
  static BiometricService? _instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  BiometricService._internal();
  
  static BiometricService get instance {
    _instance ??= BiometricService._internal();
    return _instance!;
  }

  /// Verificar si el dispositivo soporta biometría
  Future<bool> isDeviceSupported() async {
    try {
      final bool isSupported = await _localAuth.isDeviceSupported();
      DebugLogger.info('Dispositivo soporta biometría: $isSupported');
      return isSupported;
    } catch (e) {
      DebugLogger.error('Error verificando soporte biométrico: $e');
      return false;
    }
  }

  /// Verificar si hay biometría disponible (configurada)
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      
      DebugLogger.info('Can check biometrics: $canCheckBiometrics');
      DebugLogger.info('Device supported: $isDeviceSupported');
      
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      DebugLogger.error('Error verificando disponibilidad biométrica: $e');
      return false;
    }
  }

  /// Obtener tipos de biometría disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      DebugLogger.info('Biometrías disponibles: $availableBiometrics');
      return availableBiometrics;
    } catch (e) {
      DebugLogger.error('Error obteniendo biometrías disponibles: $e');
      return [];
    }
  }

  /// Autenticar con biometría
  Future<BiometricResult> authenticate({
    String reason = 'Verificar identidad para marcar asistencia',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      // Verificar si está disponible
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return BiometricResult.notAvailable('Autenticación biométrica no disponible en este dispositivo');
      }

      // Intentar autenticación
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Permite PIN/patrón como alternativa
        ),
      );

      if (didAuthenticate) {
        DebugLogger.info('Autenticación biométrica exitosa');
        return BiometricResult.success();
      } else {
        DebugLogger.warning('Autenticación biométrica cancelada por el usuario');
        return BiometricResult.cancelled('Autenticación cancelada');
      }

    } catch (e) {
      DebugLogger.error('Error en autenticación biométrica: $e');
      
      // Manejar errores específicos
      if (e.toString().contains(auth_error.notAvailable)) {
        return BiometricResult.notAvailable('Biometría no disponible');
      } else if (e.toString().contains(auth_error.notEnrolled)) {
        return BiometricResult.notEnrolled('No hay huella digital registrada en el dispositivo');
      } else if (e.toString().contains(auth_error.lockedOut)) {
        return BiometricResult.lockedOut('Biometría bloqueada temporalmente');
      } else if (e.toString().contains(auth_error.permanentlyLockedOut)) {
        return BiometricResult.permanentlyLockedOut('Biometría bloqueada permanentemente');
      } else {
        return BiometricResult.error('Error de autenticación: ${e.toString()}');
      }
    }
  }
}

/// Resultado de la autenticación biométrica
class BiometricResult {
  final bool isSuccess;
  final String? message;
  final BiometricResultType type;

  BiometricResult._(this.isSuccess, this.message, this.type);

  factory BiometricResult.success() => BiometricResult._(true, null, BiometricResultType.success);
  factory BiometricResult.cancelled(String message) => BiometricResult._(false, message, BiometricResultType.cancelled);
  factory BiometricResult.notAvailable(String message) => BiometricResult._(false, message, BiometricResultType.notAvailable);
  factory BiometricResult.notEnrolled(String message) => BiometricResult._(false, message, BiometricResultType.notEnrolled);
  factory BiometricResult.lockedOut(String message) => BiometricResult._(false, message, BiometricResultType.lockedOut);
  factory BiometricResult.permanentlyLockedOut(String message) => BiometricResult._(false, message, BiometricResultType.permanentlyLockedOut);
  factory BiometricResult.error(String message) => BiometricResult._(false, message, BiometricResultType.error);
}

enum BiometricResultType {
  success,
  cancelled,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  error,
}