import 'package:flutter/foundation.dart';

/// A production-ready logger that ensures logs are only printed in Debug mode.
/// This prevents sensitive information from leaking into device logs in production.
class AppLogger {
  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ INFO: $message');
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      print('🪲 DEBUG: $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      print('❌ ERROR: $message');
      if (error != null) print('Details: $error');
      if (stackTrace != null) print('Stacktrace: $stackTrace');
    }
    // In production, you would send these to Sentry/Firebase Crashlytics here.
  }

  static void warning(String message) {
    if (kDebugMode) {
      print('⚠️ WARNING: $message');
    }
  }
}
