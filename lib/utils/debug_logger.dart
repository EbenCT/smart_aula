// lib/utils/debug_logger.dart
import 'package:flutter/foundation.dart';

class DebugLogger {
  static const String _tag = 'AulaInteligente';
  static bool _isEnabled = kDebugMode;

  static void enable() {
    _isEnabled = true;
  }

  static void disable() {
    _isEnabled = false;
  }

  static void info(String message, {String? tag}) {
    if (_isEnabled) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] INFO: $message');
    }
  }

  static void warning(String message, {String? tag}) {
    if (_isEnabled) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] WARNING: $message');
    }
  }

  static void error(String message, {String? tag, dynamic error, StackTrace? stackTrace}) {
    if (_isEnabled) {
      debugPrint('[$_tag${tag != null ? ':$tag' : ''}] ERROR: $message');
      if (error != null) {
        debugPrint('[$_tag${tag != null ? ':$tag' : ''}] ERROR DETAILS: $error');
      }
      if (stackTrace != null) {
        debugPrint('[$_tag${tag != null ? ':$tag' : ''}] STACK TRACE: $stackTrace');
      }
    }
  }

  static void api(String method, String url, {Map<String, dynamic>? body, Map<String, String>? headers}) {
    if (_isEnabled) {
      debugPrint('[$_tag:API] $method $url');
      if (headers != null) {
        debugPrint('[$_tag:API] Headers: $headers');
      }
      if (body != null) {
        debugPrint('[$_tag:API] Body: $body');
      }
    }
  }

  static void apiResponse(int statusCode, String url, {dynamic response}) {
    if (_isEnabled) {
      debugPrint('[$_tag:API] Response $statusCode for $url');
      if (response != null) {
        final responseStr = response.toString();
        if (responseStr.length > 500) {
          debugPrint('[$_tag:API] Response (truncated): ${responseStr.substring(0, 500)}...');
        } else {
          debugPrint('[$_tag:API] Response: $response');
        }
      }
    }
  }

  static void provider(String provider, String action, {dynamic data}) {
    if (_isEnabled) {
      debugPrint('[$_tag:$provider] $action');
      if (data != null) {
        debugPrint('[$_tag:$provider] Data: $data');
      }
    }
  }

  static void cache(String action, String key, {dynamic data}) {
    if (_isEnabled) {
      debugPrint('[$_tag:CACHE] $action - Key: $key');
      if (data != null) {
        debugPrint('[$_tag:CACHE] Data: $data');
      }
    }
  }
}