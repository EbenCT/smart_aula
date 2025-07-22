class AppConstants {
  // API
  static const String apiBaseUrl = 'http://157.230.83.231:8000';
  
  // Strings
  static const String appName = 'Aula Inteligente';
  static const String versionNumber = '1.0.0';
  
  // Formatos de fecha
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  
  // Configuración de predicción
  static const double prediccionUmbralBajo = 60.0;
  static const double prediccionUmbralMedio = 80.0;
  
  // Intervalos de tiempo
  static const int tokenExpirationHours = 24;
  static const int cacheExpirationMinutes = 30;
  
  // Máximos
  static const int maxObservacionLength = 200;
  static const int maxParticipacionesPorClase = 5;
  
  // Preferencias
  static const String prefThemeMode = 'theme_mode';
  static const String prefLastPeriodoId = 'last_periodo_id';
  static const String prefLastCursoId = 'last_curso_id';
  
  // Clave pública para validar tokens
  static const String jwtPublicKey = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAnzyis1Zjz4BbJWCSbJPo
... (aquí va la clave completa) ...
57yCNH4GjW/+OvXYMV1Wz5wiIDgZ36W9tBFmFMm3RnCNUYJTeRkw4JY1OvkcgOZD
QIDAQAB
-----END PUBLIC KEY-----
''';
}