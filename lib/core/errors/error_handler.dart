import 'dart:developer' as dev;
import 'exceptions.dart';
import 'failures.dart';

class ErrorHandler {
  static void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    final errorMessage = _formatErrorMessage(error, context);
    
    dev.log(
      errorMessage,
      error: error,
      stackTrace: stackTrace,
      name: 'IzForce.ErrorHandler',
    );
  }

  static Failure handleException(Exception exception) {
    switch (exception.runtimeType) {
      case BluetoothException:
        final e = exception as BluetoothException;
        return BluetoothFailure(e.message, code: e.code);
      
      case DataProcessingException:
        final e = exception as DataProcessingException;
        return DataProcessingFailure(e.message, code: e.code);
      
      case CalibrationException:
        final e = exception as CalibrationException;
        return CalibrationFailure(e.message, code: e.code);
      
      case TestException:
        final e = exception as TestException;
        return TestFailure(e.message, code: e.code);
      
      case DatabaseException:
        final e = exception as DatabaseException;
        return DatabaseFailure(e.message, code: e.code);
      
      case FileException:
        final e = exception as FileException;
        return FileFailure(e.message, code: e.code);
      
      case PermissionException:
        final e = exception as PermissionException;
        return PermissionFailure(e.message, code: e.code);
      
      default:
        return DataProcessingFailure(
          'Beklenmeyen hata: ${exception.toString()}',
        );
    }
  }

  static String _formatErrorMessage(dynamic error, String? context) {
    final buffer = StringBuffer();
    
    if (context != null) {
      buffer.writeln('Context: $context');
    }
    
    buffer.writeln('Error: ${error.toString()}');
    
    if (error is AppException && error.originalError != null) {
      buffer.writeln('Original Error: ${error.originalError}');
    }
    
    return buffer.toString();
  }

  // Private constructor
  ErrorHandler._();
}