import 'dart:developer' as developer;
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// izForce logger sistemi
class AppLogger {
  static Logger? _logger;
  static File? _logFile;
  static bool _isInitialized = false;

  AppLogger._();

  /// Logger'ı başlat
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Log dosyası oluştur
      await _createLogFile();

      // Logger'ı konfigüre et
      _logger = Logger(
        filter: _LogFilter(),
        printer: kDebugMode ? PrettyPrinter(
          methodCount: 2,
          errorMethodCount: 8,
          lineLength: 120,
          colors: true,
          printEmojis: true,
          printTime: true,
        ) : SimplePrinter(),
        output: _LogOutput(_logFile),
      );

      _isInitialized = true;
      info('🚀 izForce Logger başlatıldı');
    } catch (e) {
      debugPrint('Logger başlatma hatası: $e');
    }
  }

  /// Log dosyası oluştur
  static Future<void> _createLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(directory.path, 'logs'));
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      final fileName = 'izforce_${DateTime.now().toString().split(' ')[0]}.log';
      _logFile = File(path.join(logDir.path, fileName));

      // Eski log dosyalarını temizle (7 günden eski)
      await _cleanOldLogs(logDir);
    } catch (e) {
      debugPrint('Log dosyası oluşturma hatası: $e');
    }
  }

  /// Eski log dosyalarını temizle
  static Future<void> _cleanOldLogs(Directory logDir) async {
    try {
      final files = await logDir.list().toList();
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Eski log temizleme hatası: $e');
    }
  }

  /// Debug log
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) {
      debugPrint('[DEBUG] $message');
      return;
    }
    _logger?.d(message);
  }

  /// Info log
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) {
      debugPrint('[INFO] $message');
      return;
    }
    _logger?.d(message);
  }

  /// Warning log
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) {
      debugPrint('[WARNING] $message');
      return;
    }
    _logger?.d(message);
  }

  /// Error log
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!_isInitialized) {
      debugPrint('[ERROR] $message');
      return;
    }
    _logger?.d(message);
  }

  /// Success log (info seviyesinde)
  static void success(String message) {
    info('✅ $message');
  }

  /// Test specific logs
  static void testStart(String testType, String athleteName) {
    info('🏃 Test başladı: $testType - $athleteName');
  }

  static void testComplete(String testType, String athleteName, Duration duration) {
    info('✅ Test tamamlandı: $testType - $athleteName (${duration.inSeconds}s)');
  }

  static void testError(String testType, String error) {
    AppLogger.error('❌ Test hatası: $testType - $error');
  }

  /// USB connection logs
  static void usbConnected(String deviceId) {
    info('🔌 USB bağlandı: $deviceId');
  }

  static void usbDisconnected() {
    warning('🔌 USB bağlantısı kesildi');
  }

  static void usbError(String error) {
    AppLogger.error('🔌 USB hatası: $error');
  }

  /// Database logs
  static void dbOperation(String operation, String table) {
    debug('🗄️  DB: $operation - $table');
  }

  static void dbError(String operation, String error) {
    AppLogger.error('🗄️  DB Hatası: $operation - $error');
  }

  /// Metrics calculation logs
  static void metricsCalculated(String testType, int metricCount) {
    debug('📊 Metrikler hesaplandı: $testType ($metricCount metrik)');
  }

  static void metricsError(String error) {
    AppLogger.error('📊 Metrik hesaplama hatası: $error');
  }

  /// Performance logs
  static void performance(String operation, Duration duration) {
    if (duration.inMilliseconds > 100) {
      warning('⚡ Yavaş işlem: $operation (${duration.inMilliseconds}ms)');
    } else {
      debug('⚡ $operation (${duration.inMilliseconds}ms)');
    }
  }

  /// Memory usage log
  static void memoryUsage() {
    if (kDebugMode) {
      final info = developer.Service.getIsolateID(Isolate.current);
      debug('💾 Memory: ${info ?? 'N/A'}');
    }
  }

  /// Log dosyasını al
  static File? get logFile => _logFile;

  /// Log geçmişini al
  static Future<String> getLogHistory({int days = 1}) async {
    try {
      if (_logFile == null || !await _logFile!.exists()) {
        return 'Log dosyası bulunamadı';
      }

      final content = await _logFile!.readAsString();
      final lines = content.split('\n');
      
      // Son X günün loglarını filtrele
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final filteredLines = lines.where((line) {
        if (line.isEmpty) return false;
        try {
          // Log satırından tarih çıkar (basit regex)
          final dateMatch = RegExp(r'\d{4}-\d{2}-\d{2}').firstMatch(line);
          if (dateMatch != null) {
            final dateStr = dateMatch.group(0);
            final logDate = DateTime.parse('${dateStr}T00:00:00');
            return logDate.isAfter(cutoffDate);
          }
        } catch (e) {
          // Tarih parse edilemezse dahil et
        }
        return true;
      }).toList();

      return filteredLines.join('\n');
    } catch (e) {
      return 'Log okuma hatası: $e';
    }
  }

  /// Log dosyasını temizle
  static Future<void> clearLogs() async {
    try {
      if (_logFile != null && await _logFile!.exists()) {
        await _logFile!.writeAsString('');
        info('🧹 Log dosyası temizlendi');
      }
    } catch (e) {
      debugPrint('Log temizleme hatası: $e');
    }
  }

  /// Logger'ı kapat
  static Future<void> dispose() async {
    try {
      _logger?.close();
      _logger = null;
      _logFile = null;
      _isInitialized = false;
    } catch (e) {
      debugPrint('Logger kapatma hatası: $e');
    }
  }
}

/// Log filter - hangi logların yazılacağını belirler
class _LogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // Debug modda tüm loglar
    if (kDebugMode) return true;
    
    // Release modda sadece warning ve üstü
    return event.level.index >= Level.warning.index;
  }
}

/// Log output - konsol ve dosyaya yazma
class _LogOutput extends LogOutput {
  final File? logFile;

  _LogOutput(this.logFile);

  @override
  void output(OutputEvent event) {
    // Konsola yaz
    for (final line in event.lines) {
      debugPrint(line);
    }

    // Dosyaya yaz
    _writeToFile(event.lines);
  }

  Future<void> _writeToFile(List<String> lines) async {
    if (logFile == null) return;

    try {
      final timestamp = DateTime.now().toIso8601String();
      final logLine = '[$timestamp] ${lines.join('\n')}\n';
      
      await logFile!.writeAsString(
        logLine,
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('Log dosyaya yazma hatası: $e');
    }
  }
}

/// Basit log formatter (release mode için)
class SimplePrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final time = DateTime.now().toString().substring(0, 19);
    final level = event.level.name.toUpperCase().padRight(7);
    return ['$time [$level] ${event.message}'];
  }
}

/// Performance timer helper
class PerformanceTimer {
  final String operation;
  final Stopwatch _stopwatch;

  PerformanceTimer(this.operation) : _stopwatch = Stopwatch()..start();

  void stop() {
    _stopwatch.stop();
    AppLogger.performance(operation, _stopwatch.elapsed);
  }
}

/// Log helper extensions
extension LoggerExtensions on Object? {
  /// Hızlı debug log
  void logDebug() => AppLogger.debug(toString());
  
  /// Hızlı info log
  void logInfo() => AppLogger.info(toString());
  
  /// Hızlı error log
  void logError() => AppLogger.error(toString());
}