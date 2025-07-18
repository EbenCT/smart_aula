// lib/services/location_service.dart
import 'package:location/location.dart';
import '../utils/debug_logger.dart';

class LocationService {
  static LocationService? _instance;
  final Location _location = Location();
  
  LocationService._internal();
  
  static LocationService get instance {
    _instance ??= LocationService._internal();
    return _instance!;
  }

  /// Verifica y solicita permisos de ubicación
  Future<bool> checkAndRequestLocationPermission() async {
    try {
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          DebugLogger.warning('Servicio de ubicación deshabilitado');
          return false;
        }
      }

      // Verificar permisos
      PermissionStatus permissionGranted = await _location.hasPermission();
      
      if (permissionGranted == PermissionStatus.denied) {
        // Solicitar permisos
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          DebugLogger.warning('Permisos de ubicación denegados');
          return false;
        }
      }

      if (permissionGranted == PermissionStatus.deniedForever) {
        DebugLogger.error('Permisos de ubicación denegados permanentemente');
        return false;
      }

      DebugLogger.info('Permisos de ubicación concedidos');
      return true;
    } catch (e) {
      DebugLogger.error('Error al verificar permisos: $e');
      return false;
    }
  }

  /// Obtiene la ubicación actual del docente
  Future<Map<String, double>?> getCurrentLocation() async {
    try {
      // Verificar permisos primero
      bool hasPermission = await checkAndRequestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      // Obtener ubicación actual
      LocationData locationData = await _location.getLocation();

      if (locationData.latitude == null || locationData.longitude == null) {
        DebugLogger.error('No se pudieron obtener las coordenadas');
        return null;
      }

      DebugLogger.info('Ubicación obtenida: ${locationData.latitude}, ${locationData.longitude}');
      
      return {
        'latitude': locationData.latitude!,
        'longitude': locationData.longitude!,
      };
    } catch (e) {
      DebugLogger.error('Error al obtener ubicación: $e');
      return null;
    }
  }

  /// Obtiene la dirección aproximada (opcional, para mostrar al usuario)
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      // Aquí podrías usar geocoding si quieres mostrar la dirección
      // Por simplicidad, retornamos las coordenadas
      return 'Lat: ${lat.toStringAsFixed(6)}, Lng: ${lng.toStringAsFixed(6)}';
    } catch (e) {
      DebugLogger.warning('Error al obtener dirección: $e');
      return 'Ubicación actual';
    }
  }
}