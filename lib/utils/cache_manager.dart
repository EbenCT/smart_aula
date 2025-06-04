// lib/utils/cache_manager.dart
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  static const int maxCacheSize = 50; // Máximo número de entradas en cache
  static const int defaultTTLMinutes = 10; // Tiempo de vida por defecto

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _timestamps = {};
  final Map<String, int> _ttlMinutes = {};

  // Agregar entrada al cache
  void put(String key, dynamic data, {int? ttlMinutes}) {
    _cleanupIfNeeded();
    
    _cache[key] = data;
    _timestamps[key] = DateTime.now();
    _ttlMinutes[key] = ttlMinutes ?? defaultTTLMinutes;
  }

  // Obtener entrada del cache
  T? get<T>(String key) {
    if (!_cache.containsKey(key)) return null;
    
    // Verificar si ha expirado
    if (_isExpired(key)) {
      remove(key);
      return null;
    }
    
    return _cache[key] as T?;
  }

  // Verificar si una clave existe y es válida
  bool has(String key) {
    if (!_cache.containsKey(key)) return false;
    
    if (_isExpired(key)) {
      remove(key);
      return false;
    }
    
    return true;
  }

  // Remover entrada específica
  void remove(String key) {
    _cache.remove(key);
    _timestamps.remove(key);
    _ttlMinutes.remove(key);
  }

  // Limpiar todo el cache
  void clear() {
    _cache.clear();
    _timestamps.clear();
    _ttlMinutes.clear();
  }

  // Limpiar cache por patrón
  void clearByPattern(String pattern) {
    final keysToRemove = _cache.keys
        .where((key) => key.contains(pattern))
        .toList();
    
    for (final key in keysToRemove) {
      remove(key);
    }
  }

  // Verificar si una entrada ha expirado
  bool _isExpired(String key) {
    if (!_timestamps.containsKey(key)) return true;
    
    final timestamp = _timestamps[key]!;
    final ttl = _ttlMinutes[key] ?? defaultTTLMinutes;
    final now = DateTime.now();
    
    return now.difference(timestamp).inMinutes >= ttl;
  }

  // Limpiar cache si excede el tamaño máximo
  void _cleanupIfNeeded() {
    // Primero remover entradas expiradas
    final expiredKeys = _timestamps.entries
        .where((entry) => _isExpired(entry.key))
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredKeys) {
      remove(key);
    }
    
    // Si aún excede el tamaño, remover las más antiguas
    if (_cache.length >= maxCacheSize) {
      final sortedEntries = _timestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final keysToRemove = sortedEntries
          .take(_cache.length - maxCacheSize + 5) // Remover 5 extra
          .map((entry) => entry.key)
          .toList();
      
      for (final key in keysToRemove) {
        remove(key);
      }
    }
  }

  // Obtener estadísticas del cache
  Map<String, dynamic> getStats() {
    return {
      'totalEntries': _cache.length,
      'maxSize': maxCacheSize,
      'entries': _cache.keys.map((key) => {
        'key': key,
        'timestamp': _timestamps[key]?.toIso8601String(),
        'ttlMinutes': _ttlMinutes[key],
        'isExpired': _isExpired(key),
      }).toList(),
    };
  }

  // Generar clave de cache estandarizada
  static String generateKey(String resource, Map<String, dynamic> params) {
    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key))
    );
    
    final paramString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');
    
    return paramString.isEmpty ? resource : '$resource?$paramString';
  }
}

// Mixin para providers que usen cache
mixin CacheableMixin {
  final CacheManager _cacheManager = CacheManager();
  
  // Obtener datos con cache
  Future<T> getWithCache<T>(
    String cacheKey,
    Future<T> Function() fetchFunction, {
    int? ttlMinutes,
  }) async {
    // Intentar obtener del cache primero
    final cached = _cacheManager.get<T>(cacheKey);
    if (cached != null) {
      return cached;
    }
    
    // Si no está en cache, obtener datos
    final data = await fetchFunction();
    
    // Guardar en cache
    _cacheManager.put(cacheKey, data, ttlMinutes: ttlMinutes);
    
    return data;
  }
  
  // Invalidar cache relacionado
  void invalidateCache(String pattern) {
    _cacheManager.clearByPattern(pattern);
  }
  
  // Limpiar todo el cache del provider
  void clearProviderCache() {
    _cacheManager.clear();
  }
}