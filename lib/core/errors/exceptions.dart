/// Base exception class for the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message';
}

/// Bluetooth connection related exceptions
class BluetoothException extends AppException {
  const BluetoothException(super.message, {super.code, super.originalError});
}

/// Data processing related exceptions
class DataProcessingException extends AppException {
  const DataProcessingException(super.message, {super.code, super.originalError});
}

/// Calibration related exceptions
class CalibrationException extends AppException {
  const CalibrationException(super.message, {super.code, super.originalError});
}

/// Test execution related exceptions
class TestException extends AppException {
  const TestException(super.message, {super.code, super.originalError});
}

/// Database related exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

/// File operations related exceptions
class FileException extends AppException {
  const FileException(super.message, {super.code, super.originalError});
}

/// Permission related exceptions
class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.originalError});
}