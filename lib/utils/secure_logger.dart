import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Secure logging utility that prevents sensitive data from being logged
/// and provides different log levels for better debugging control.
/// 
/// This utility is designed to be safe for production use and helps
/// prevent accidental logging of sensitive information like passwords,
/// tokens, or personal data.
class SecureLogger {
  static const String _tag = 'SunnahSteps';
  
  // Log levels
  static const int _levelDebug = 0;
  static const int _levelInfo = 1;
  static const int _levelWarning = 2;
  static const int _levelError = 3;
  
  // Current log level (can be configured)
  static int _currentLevel = kDebugMode ? _levelDebug : _levelError;
  
  /// Set the minimum log level
  static void setLogLevel(int level) {
    _currentLevel = level;
  }
  
  /// Log debug information (only in debug builds)
  static void debug(String message, {String? tag, Object? error}) {
    if (_currentLevel <= _levelDebug && kDebugMode) {
      _log('DEBUG', tag ?? _tag, _sanitizeMessage(message), error);
    }
  }
  
  /// Log general information
  static void info(String message, {String? tag, Object? error}) {
    if (_currentLevel <= _levelInfo) {
      _log('INFO', tag ?? _tag, _sanitizeMessage(message), error);
    }
  }
  
  /// Log warnings
  static void warning(String message, {String? tag, Object? error}) {
    if (_currentLevel <= _levelWarning) {
      _log('WARNING', tag ?? _tag, _sanitizeMessage(message), error);
    }
  }
  
  /// Log errors
  static void error(String message, {String? tag, Object? error}) {
    if (_currentLevel <= _levelError) {
      _log('ERROR', tag ?? _tag, _sanitizeMessage(message), error);
    }
  }
  
  /// Log Firebase operations (with automatic sanitization)
  static void firebase(String operation, {String? details, Object? error}) {
    if (_currentLevel <= _levelInfo) {
      final sanitizedDetails = details != null ? _sanitizeFirebaseMessage(details) : '';
      _log('FIREBASE', 'FirebaseService', '$operation $sanitizedDetails', error);
    }
  }
  
  /// Log authentication events (with automatic sanitization)
  static void auth(String event, {String? userId, Object? error}) {
    if (_currentLevel <= _levelInfo) {
      final sanitizedUserId = userId != null ? _sanitizeUserId(userId) : '';
      _log('AUTH', 'AuthService', '$event $sanitizedUserId', error);
    }
  }
  
  /// Log user actions (with automatic sanitization)
  static void userAction(String action, {String? details, Object? error}) {
    if (_currentLevel <= _levelInfo) {
      final sanitizedDetails = details != null ? _sanitizeMessage(details) : '';
      _log('USER', 'UserAction', '$action $sanitizedDetails', error);
    }
  }
  
  /// Log performance metrics
  static void performance(String metric, {String? details, Object? error}) {
    if (_currentLevel <= _levelInfo && AppConstants.enablePerformanceLogging) {
      _log('PERF', 'Performance', '$metric ${details ?? ''}', error);
    }
  }
  
  /// Internal logging method
  static void _log(String level, String tag, String message, Object? error) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] [$level] [$tag] $message';
    
    if (kDebugMode || AppConstants.enableDebugLogging) {
      print(logMessage);
      if (error != null) {
        print('[$timestamp] [$level] [$tag] Error: $error');
      }
    }
  }
  
  /// Sanitize messages to remove sensitive information
  static String _sanitizeMessage(String message) {
    String sanitized = message;
    
    // Remove email addresses (replace with masked version)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'),
      (match) => _maskEmail(match.group(0)!),
    );
    
    // Remove potential passwords (any string after "password" keyword)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'password[:\s=]+[^\s]+', caseSensitive: false),
      (match) => 'password: [REDACTED]',
    );
    
    // Remove potential tokens (long alphanumeric strings)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\b[A-Za-z0-9]{32,}\b'),
      (match) => '[TOKEN_REDACTED]',
    );
    
    // Remove potential API keys
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'(api[_-]?key|secret|token)[:\s=]+[^\s]+', caseSensitive: false),
      (match) => '${match.group(1)}: [REDACTED]',
    );
    
    return sanitized;
  }
  
  /// Sanitize Firebase-specific messages
  static String _sanitizeFirebaseMessage(String message) {
    String sanitized = _sanitizeMessage(message);
    
    // Remove Firebase UIDs (keep first 4 characters for debugging)
    sanitized = sanitized.replaceAllMapped(
      RegExp(r'\b[A-Za-z0-9]{20,}\b'),
      (match) {
        final uid = match.group(0)!;
        if (uid.length > 8) {
          return '${uid.substring(0, 4)}***';
        }
        return uid;
      },
    );
    
    return sanitized;
  }
  
  /// Sanitize user IDs for logging
  static String _sanitizeUserId(String userId) {
    if (userId.length > 8) {
      return '${userId.substring(0, 4)}***';
    }
    return userId;
  }
  
  /// Mask email addresses for logging
  static String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return '[INVALID_EMAIL]';
    
    final username = parts[0];
    final domain = parts[1];
    
    String maskedUsername;
    if (username.length <= 2) {
      maskedUsername = '*' * username.length;
    } else {
      maskedUsername = '${username[0]}${'*' * (username.length - 2)}${username[username.length - 1]}';
    }
    
    return '$maskedUsername@$domain';
  }
  
  /// Log method entry (for debugging complex flows)
  static void methodEntry(String className, String methodName, {Map<String, dynamic>? params}) {
    if (_currentLevel <= _levelDebug && kDebugMode) {
      final sanitizedParams = params != null ? _sanitizeParams(params) : '';
      debug('→ $className.$methodName $sanitizedParams');
    }
  }
  
  /// Log method exit (for debugging complex flows)
  static void methodExit(String className, String methodName, {dynamic result}) {
    if (_currentLevel <= _levelDebug && kDebugMode) {
      final sanitizedResult = result != null ? _sanitizeMessage(result.toString()) : '';
      debug('← $className.$methodName $sanitizedResult');
    }
  }
  
  /// Sanitize method parameters
  static String _sanitizeParams(Map<String, dynamic> params) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in params.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;
      
      // Redact sensitive parameters
      if (key.contains('password') || 
          key.contains('token') || 
          key.contains('secret') || 
          key.contains('key')) {
        sanitized[entry.key] = '[REDACTED]';
      } else if (key.contains('email') && value is String) {
        sanitized[entry.key] = _maskEmail(value);
      } else if (key.contains('uid') && value is String && value.length > 8) {
        sanitized[entry.key] = _sanitizeUserId(value);
      } else {
        sanitized[entry.key] = value;
      }
    }
    
    return sanitized.toString();
  }
  
  /// Check if logging is enabled for a specific level
  static bool isLoggingEnabled(int level) {
    return _currentLevel <= level;
  }
  
  /// Disable all logging (for production)
  static void disableLogging() {
    _currentLevel = 999; // Set to a very high level to disable all logs
  }
  
  /// Enable debug logging (for development)
  static void enableDebugLogging() {
    _currentLevel = _levelDebug;
  }
}

/// Extension methods for easier logging
extension SecureLoggerExtension on Object {
  void logDebug(String message, {String? tag}) {
    SecureLogger.debug(message, tag: tag ?? runtimeType.toString());
  }
  
  void logInfo(String message, {String? tag}) {
    SecureLogger.info(message, tag: tag ?? runtimeType.toString());
  }
  
  void logWarning(String message, {String? tag}) {
    SecureLogger.warning(message, tag: tag ?? runtimeType.toString());
  }
  
  void logError(String message, {Object? error, String? tag}) {
    SecureLogger.error(message, tag: tag ?? runtimeType.toString(), error: error);
  }
}
